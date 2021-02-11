defmodule Erikusuaa.Session do
  @moduledoc false

  use GenServer
  require Logger
  alias Erikusuaa.{Constants, Payload, Struct.WSState, Utils}

  @gw_qs "/?v=8&compress=zlib-stream&encoding=etf"
  @timeout 10_000

  def start_link([gateway, shard_num]) do
    GenServer.start_link(__MODULE__, [gateway, shard_num])
  end

  @impl true
  # init_arg is pretty much initial state
  def init([_gateway, _shard_num] = init_arg) do
    {:ok, nil, {:continue, init_arg}}
  end

  @impl true
  def handle_continue([gateway, shard_num], nil) do
    {:ok, worker} = :gun.open(:binary.bin_to_list(gateway), 443, %{protocols: [:http]})

    {:ok, :http} = :gun.await_up(worker, @timeout)
    stream = :gun.ws_upgrade(worker, @gw_qs)
    await_ws_upgrade(worker, stream)

    zlib_context = :zlib.open()
    :zlib.inflateInit(zlib_context)

    state = %WSState{
      conn_pid: self(),
      conn: worker,
      shard_num: shard_num,
      gateway: gateway <> @gw_qs,
      last_heartbeat_ack: DateTime.utc_now(),
      heartbeat_ack: true,
      zlib_ctx: zlib_context
    }

    {:noreply, state}
  end

  # region Handle WS Connectivity
  @impl true
  def handle_info({:gun_ws, _worker, _stream, {:binary, frame}}, state) do
    payload =
      state.zlib_ctx
      |> :zlib.inflate(frame)
      |> :erlang.iolist_to_binary()
      |> :erlang.binary_to_term()

    state = %{state | seq: payload.s || state.seq}

    frame = process_frame(payload, state)

    case frame do
      {new_state, reply} ->
        :ok = :gun.ws_send(state.conn, {:binary, reply})
        {:noreply, new_state}

      new_state ->
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info({:gun_ws, _conn, _stream, {:close, errno, reason}}, state) do
    Logger.info("Shard websocket closed (errno #{errno}, reason #{inspect(reason)})")
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:gun_down, _conn, _proto, _reason, _killed_streams, _unprocessed_streams},
        state
      ) do
    :timer.cancel(state.heartbeat_ref)
    {:noreply, state}
  end

  @impl true
  def handle_info({:gun_up, worker, _proto}, state) do
    :ok = :zlib.inflateReset(state.zlib_ctx)
    stream = :gun.ws_upgrade(worker, @gw_qs)
    await_ws_upgrade(worker, stream)
    Logger.warn("Reconnected after connection broke")
    {:noreply, %{state | heartbeat_ack: true}}
  end

  # endregion Handle WS Connectivity

  # region Event Handling
  # DISPATCH
  def process_frame(%{op: 0} = payload, state) do
    # Manifold.send(Erikusuaa.Shard.Broker, {:send, payload})
    # TODO: remove
    Logger.info(Supervisor.which_children(Erikusuaa.Gateway))
    Logger.info(Supervisor.which_children(:clusterSupervisor))

    Supervisor.which_children(Erikusuaa.Gateway)
    |> Enum.find(nil, fn x -> elem(x, 0) == Erikusuaa.Broker end)
    |> elem(1)
    |> Manifold.send({:send, payload})

    if payload.t == "READY" do
      %{state | session: payload.d.session_id}
    else
      state
    end
  end

  # HEARTBEAT
  def process_frame(%{op: 1} = _payload, state) do
    {state, Payload.heartbeat_payload(state.seq)}
  end

  # INVALID_SESSION
  def process_frame(%{op: 9} = payload, state) do
    Logger.info(Constants.name_of_opcode(payload.op))
    {state, Payload.identity_payload(state)}
  end

  # HELLO
  def process_frame(%{op: 10} = payload, state) do
    state = %{
      state
      | heartbeat_interval: payload.d.heartbeat_interval
    }

    GenServer.cast(state.conn_pid, %{op: 1})

    if Utils.session_exists?(state) do
      Logger.info("RESUMING")
      {state, Payload.resume_payload(state)}
    else
      Logger.info("IDENTIFYING")
      {state, Payload.identity_payload(state)}
    end
  end

  # HEARTBEAT_ACK
  def process_frame(%{op: 11} = payload, state) do
    Logger.debug(Constants.name_of_opcode(payload.op))
    %{state | last_heartbeat_ack: DateTime.utc_now(), heartbeat_ack: true}
  end

  # Fallback
  def process_frame(payload, state) do
    Logger.warn("UNHANDLED GATEWAY EVENT \"#{Constants.name_of_opcode(payload.op)}\"")
    state
  end

  # endregion Event Handling

  # region HEARTBEAT Handling
  @impl true
  def handle_cast(%{op: 1} = _payload, %{heartbeat_ack: false, heartbeat_ref: timer_ref} = state) do
    Logger.warn("heartbeat_ack not received in time, disconnecting")
    {:ok, :cancel} = :timer.cancel(timer_ref)
    :gun.ws_send(state.conn, :close)
    {:noreply, state}
  end

  @impl true
  def handle_cast(%{op: 1} = payload, state) do
    {:ok, ref} =
      :timer.apply_after(state.heartbeat_interval, :gen_server, :cast, [
        state.conn_pid,
        payload
      ])

    :ok = :gun.ws_send(state.conn, {:binary, Payload.heartbeat_payload(state.seq)})

    {:noreply,
     %{state | heartbeat_ref: ref, heartbeat_ack: false, last_heartbeat_send: DateTime.utc_now()}}
  end

  # endregion HEARTBEAT Handling

  defp await_ws_upgrade(worker, stream) do
    receive do
      {:gun_upgrade, ^worker, ^stream, [<<"websocket">>], _headers} ->
        :ok

      {:gun_error, ^worker, ^stream, reason} ->
        exit({:ws_upgrade_failed, reason})
    after
      @timeout ->
        Logger.critical(
          "Cannot upgrade connection to Websocket after #{@timeout} damn that's some bullshit"
        )

        exit(:timeout)
    end
  end
end
