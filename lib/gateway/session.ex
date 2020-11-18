defmodule Gateway.Session do
  use GenServer
  require Logger
  alias Gateway.{Constants, Struct.WSState}

  @timeout 10_000

  @impl true
  # init_arg is pretty much initial state
  def init(init_arg) do
    {:ok, nil, {:continue, init_arg}}
  end

  @impl true
  # cont being whatever the fuck idk
  def handle_continue(cont, nil) do
    # TODO(Quantum): Determine url from api response
    {:ok, worker} =
      :gun.open(:binary.bin_to_list("gateway.discord.gg"), 443, %{protocols: [:http]})

    {:ok, :http} = :gun.await_up(worker, @timeout)
    # TODO: support zlib
    stream = :gun.ws_upgrade(worker, "/?v=8&encoding=etf")
    await_ws_upgrade(worker, stream)

    {:noreply, cont}
  end

  @impl true
  def handle_info({:gun_ws, _worker, _stream, {:binary, frame}}, state) do
    # zlib support shall be implemented here
    frame = :erlang.binary_to_term(frame)
    IO.inspect(frame)
    state = process_frame(frame, state)

    {:noreply, state}
  end

  # HELLO
  def process_frame(%{op: 10} = frame, state) do
    # stuff
  end

  def process_frame(frame, state) do
    # some general stuff that the gateway doesn't have to bother with
    state
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
end
