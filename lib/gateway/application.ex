defmodule Gateway.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Gateway.Worker.start_link(arg)
      # {Gateway.Worker, arg}
    ]

    {:ok, worker} = :gun.open(:binary.bin_to_list("https://discord.com/api/v6"), 443, %{protocols: [:http]})
    {:ok, :http} = :gun.await_up(worker, 10_000)
    stream = :gun.ws_upgrade(worker, "/?compress=zlib-stream&encoding=etf&v=6")
    await_ws_upgrade(worker, stream)

    Logger.debug(fn -> "Websocket connection up on worker #{inspect(worker)}" end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp await_ws_upgrade(worker, stream) do
    # TODO: Once gun 2.0 is released, the block below can be simplified to:
    # {:upgrade, [<<"websocket">>], _headers} = :gun.await(worker, stream, @timeout_ws_upgrade)

    receive do
      {:gun_upgrade, ^worker, ^stream, [<<"websocket">>], _headers} ->
        :ok

      {:gun_error, ^worker, ^stream, reason} ->
        exit({:ws_upgrade_failed, reason})
    after
      10_000 ->
        Logger.error(fn ->
          "Cannot upgrade connection to Websocket after #{10_000 / 1000} seconds"
        end)

        exit(:timeout)
    end
  end
end
