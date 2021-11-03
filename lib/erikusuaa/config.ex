defmodule Erikusuaa.Config do
  @moduledoc false

  def bot_config, do: c(:bot)
  @spec bot_token :: String.t() | nil
  def bot_token, do: bot_config() |> Keyword.get(:token)

  def gateway_config, do: c(:gateway)
  @spec gateway_shard_count :: String.t() | nil
  def gateway_shard_count, do: gateway_config() |> Keyword.get(:shard_count)
  @spec gateway_identify_delay :: integer()
  def gateway_identify_delay, do: gateway_config() |> Keyword.get(:identify_delay)
  def gateway_intents, do: gateway_config() |> Keyword.get(:intents, :nonprivileged)

  def amqp_config, do: c(:amqp)
  @spec amqp_url :: String.t()
  def amqp_url, do: amqp_config() |> Keyword.get(:url)

  defp c(k) when is_atom(k), do: Application.get_env(:erikusuaa, k)
end
