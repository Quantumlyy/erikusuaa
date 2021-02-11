use Mix.Config

config :erikusuaa,
  bot: [
    token: System.get_env("BOT_TOKEN")
  ],
  gateway: [
    shard_count: System.get_env("GATEWAY_SHARD_COUNT"),
    identify_delay: String.to_integer(System.get_env("GATEWAY_IDENTIFY_DELAY") || "5100")
  ]
