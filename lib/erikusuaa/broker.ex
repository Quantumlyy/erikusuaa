defmodule Erikusuaa.Broker do
  @moduledoc false

  use GenServer

  require AMQP
  require Logger

  alias Erikusuaa.{Config, Struct.AMQpState}

  @impl true
  # init_arg is pretty much initial state
  def init(init_arg) do
    {:ok, nil, {:continue, init_arg}}
  end

  @impl true
  def handle_continue(_init_arg, nil) do
    {:ok, conn} = if (Config.amqp_url() != nil), do: AMQP.Connection.open(Config.amqp_url()), else: AMQP.Connection.open()

    state = %AMQpState{
      conn: conn,
      conn_pid: self()
    }

    {:noreply, state}
  end
end
