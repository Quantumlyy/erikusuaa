defmodule Erikusuaa.Struct.AMQpState do

  require AMQP

  defstruct [
    :conn,
    :conn_pid
  ]

  @typedoc "The AMQP connection"
  @type conn :: AMQP.Connection

  @typedoc "PID of the connection process"
  @type conn_pid :: pid

  @type t :: %__MODULE__{
          conn: conn,
          conn_pid: conn_pid
        }
end
