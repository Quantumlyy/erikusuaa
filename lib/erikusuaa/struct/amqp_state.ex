defmodule Erikusuaa.Struct.AMQpState do
  require AMQP

  defstruct [
    :conn,
    :chan,
    :conn_pid
  ]

  @typedoc "The AMQp connection"
  @type conn :: AMQP.Connection

  @typedoc "The opened AMQp channel"
  @type chan :: AMQP.Channel

  @typedoc "PID of the connection process"
  @type conn_pid :: pid

  @type t :: %__MODULE__{
          conn: conn,
          chan: chan,
          conn_pid: conn_pid
        }
end
