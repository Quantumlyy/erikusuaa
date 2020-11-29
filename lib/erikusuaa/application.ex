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
      {DynamicSupervisor, strategy: :one_for_one, name: :clusterSupervisor}
    ]

    start = Supervisor.start_link(children, strategy: :one_for_one)

    for i <- 0..(Config.gateway_shard_count() - 1), do: add_worker("gateway.discord.gg", i)

    start
  end

  def create_worker(gateway, shard_num) do
    Supervisor.child_spec(
      {Shard, [gateway, shard_num]},
      id: shard_num
    )
  end

  defp add_worker(gateway, shard_num) do
    DynamicSupervisor.start_child(:clusterSupervisor, create_worker(gateway, shard_num))
    :timer.sleep(Config.gateway_identify_delay())
  end
end
