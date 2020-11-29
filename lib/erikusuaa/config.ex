defmodule Erikusuaa.Config do
  @moduledoc false

  def bot_config, do: c(:bot)
  def bot_token, do: bot_config() |> Keyword.get(:token)

  def gateway_config, do: c(:gateway)
  def gateway_shard_count, do: gateway_config() |> Keyword.get(:shard_count)
  def gateway_identify_delay, do: gateway_config() |> Keyword.get(:identify_delay)

  def amqp_config, do: c(:bot)
  def amqp_url, do: amqp_config() |> Keyword.get(:url)

  defp c(k) when is_atom(k), do: Application.get_env(:erikusuaa, k)
end
