defmodule Gateway.Session do
  use GenServer
  require Logger
  alias Gateway.{Constants, Payload, Struct.WSState}

  @gw_qs "/?v=8&compress=zlib-stream&encoding=etf"
  @timeout 10_000

  @impl true
  # init_arg is pretty much initial state
  def init([_gateway, _shard_num] = init_arg) do
    {:ok, nil, {:continue, init_arg}}
  end

  @impl true
  # cont being whatever the fuck idk
  def handle_continue([_gateway, shard_num], nil) do
    gateway = "gateway.discord.gg"
    # TODO(Quantum): Determine url from api response
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

  # HEARTBEAT
  def process_frame(%{op: 1} = _payload, state) do
    {state, Payload.heartbeat_payload(state.seq)}
  end

  # HELLO
  def process_frame(%{op: 10} = payload, state) do
    state = %{
      state
      | heartbeat_interval: payload.d.heartbeat_interval
    }

    GenServer.cast(state.conn_pid, %{op: 1})

    if session_exists?(state) do
      Logger.info("RESUMING")
      {state, Payload.resume_payload(state)}
    else
      Logger.info("IDENTIFYING")
      {state, Payload.identity_payload(state)}
    end
  end

  def process_frame(frame, state) do
    Logger.warn("UNHANDLED GATEWAY EVENT #{Constants.atom_from_opcode(frame.op)}")
    {state}
  end

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

  def session_exists?(state) do
    not is_nil(state.session)
  end
end
