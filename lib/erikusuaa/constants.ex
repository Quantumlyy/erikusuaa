defmodule Erikusuaa.Constants do
  @moduledoc false

  @spec base_url :: <<_::208>>
  def base_url, do: "https://discord.com/api/v8"
  @spec cdn_url :: <<_::208>>
  def cdn_url, do: "https://cdn.discordapp.com"
  @spec gateway :: <<_::64>>
  def gateway, do: "/gateway"
  @spec gateway_bot :: <<_::96>>
  def gateway_bot, do: "/gateway/bot"

  @opcodes %{
    "DISPATCH" => 0,
    "HEARTBEAT" => 1,
    "IDENTIFY" => 2,
    "PRESENCE_UPDATE" => 3,
    "VOICE_STATE_UPDATE" => 4,
    # "" => 5,
    "RESUME" => 6,
    "RECONNECT" => 7,
    "REQUEST_GUILD_MEMBERS" => 8,
    "INVALID_SESSION" => 9,
    "HELLO" => 10,
    "HEARTBEAT_ACK" => 11
  }
  def opcodes, do: @opcodes

  @spec opcode_from_name(String.t()) :: number
  def opcode_from_name(event) do
    @opcodes[event]
  end

  @spec atom_from_opcode(number) :: atom
  def atom_from_opcode(opcode) do
    {k, _} = Enum.find(@opcodes, fn {_, v} -> v == opcode end)
    k |> String.downcase() |> String.to_atom()
  end
end
