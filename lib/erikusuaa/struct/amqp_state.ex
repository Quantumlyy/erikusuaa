defmodule Erikusuaa.Struct.AMQpState do

  defstruct [
    :conn_pid
  ]

  @typedoc "PID of the connection process"
  @type conn_pid :: pid

  @type t :: %__MODULE__{
          conn_pid: conn_pid
        }
end
