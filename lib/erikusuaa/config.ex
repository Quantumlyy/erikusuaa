defmodule Erikusuaa.Config do
  @moduledoc false

  def bot_config, do: c(:bot)
  def bot_token, do: bot_config() |> Keyword.get(:token)
  def bot_shard_count, do: bot_config() |> Keyword.get(:shard_count)

  def amqp_config, do: c(:bot)
  def amqp_url, do: amqp_config() |> Keyword.get(:url)

  defp c(k) when is_atom(k), do: Application.get_env(:erikusuaa, k)
end
