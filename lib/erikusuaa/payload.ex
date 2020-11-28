defmodule Erikusuaa.Payload do
  @moduledoc false

  require Logger
  alias Erikusuaa.{Config, Constants}

  @large_threshold 250

  @doc false
  def heartbeat_payload(sequence) do
    sequence
    |> build_payload("HEARTBEAT")
  end

  @doc false
  def identity_payload(state) do
    {os, name} = :os.type()

    %{
      "token" => Config.bot_token(),
      "properties" => %{
        "$os" => Atom.to_string(os) <> " " <> Atom.to_string(name),
        "$browser" => "Erikusuaa",
        "$device" => "Erikusuaa",
        "$referrer" => "",
        "$referring_domain" => ""
      },
      "compress" => false,
      "large_threshold" => @large_threshold,
      # TODO(QuantumlyTangled): Dynamic shard count
      "shard" => [state.shard_num, Config.bot_shard_count()],
      # TODO(QuantumlyTangled): Dynamic intents
      "intents" => 512
    }
    |> build_payload("IDENTIFY")
  end

  @doc false
  def resume_payload(state) do
    %{
      "token" => Config.bot_token(),
      "session_id" => state.session,
      "seq" => state.seq
    }
    |> build_payload("RESUME")
  end

  defp build_payload(data, opcode_name) do
    opcode = Constants.opcode_from_name(opcode_name)

    %{"op" => opcode, "d" => data}
    |> :erlang.term_to_binary()
  end
end
