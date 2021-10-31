defmodule Erikusuaa.Broker do
  @moduledoc false

  use GenServer

  require AMQP
  require Logger

  alias Erikusuaa.{Config, Struct.AMQpState}

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: Erikusuaa.Shard.Broker)
  end

  @impl true
  # init_arg is pretty much initial state
  def init(init_arg) do
    {:ok, nil, {:continue, init_arg}}
  end

  @impl true
  def handle_continue(_init_arg, nil) do
    {:ok, conn} = AMQP.Connection.open(Config.amqp_url())
    {:ok, chan} = AMQP.Channel.open(conn)

    state = %AMQpState{
      conn: conn,
      chan: chan,
      conn_pid: self()
    }

    {:noreply, state}
  end

  @impl true
  def handle_info({:send, data}, state) do
    Logger.info(data)
    {:noreply, state}
  end
end
