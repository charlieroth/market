import Config

config :market, MarketWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Market.Finch

config :swoosh, local: false

config :logger, level: :info
