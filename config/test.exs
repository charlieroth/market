import Config

config :market, Market.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "market_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :market, MarketWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "YZz+C5DWbOOAH/e5a+THf0f0Qh9bgSZdwQwGcxiJJaQxhqzAJIkQpXQeq1DPSKCM",
  server: false

config :market, Market.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
