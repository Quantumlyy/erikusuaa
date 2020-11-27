defmodule Erikusuaa.Broker do
  @moduledoc false

  use GenServer
  require Logger

  @impl true
  # init_arg is pretty much initial state
  def init(init_arg) do
    {:ok, nil, {:continue, init_arg}}
  end

  @impl true
  def handle_continue(_init_arg, nil) do
  end
end
