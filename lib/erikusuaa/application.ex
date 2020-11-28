defmodule Erikusuaa.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  alias Erikusuaa.{Shard, Config}

  @impl true
  def start(_type, _args) do
    children = [

    ] ++ for i <- 0..(Config.bot_shard_count() - 1), do: create_worker("gateway.discord.gg", i)

    # Supervisor.init(children, strategy: :one_for_one, max_restarts: 3, max_seconds: 60)
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def create_worker(gateway, shard_num) do
    Supervisor.child_spec(
      {Shard, [gateway, shard_num]},
      id: shard_num
    )
  end
end
