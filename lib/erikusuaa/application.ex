defmodule Erikusuaa.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Erikusuaa.Worker.start_link(arg)
      # {Erikusuaa.Worker, arg}
    ]

    GenServer.start_link(Erikusuaa.Session, ["gateway.discord.gg", 0])
    GenServer.start_link(Erikusuaa.Session, ["gateway.discord.gg", 1])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Erikusuaa.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
