import Config

config :market,
  ecto_repos: [Market.Repo]

config :market, MarketWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MarketWeb.ErrorHTML, json: MarketWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Market.PubSub,
  live_view: [signing_salt: "VJV08grS"]

config :market, Market.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# in each environment config file you should overwrite this if it's external
config :market, Market.Guardian,
  issuer: "market",
  secret_key: "3cNlRNY5jS1oyExrp1H5TzBJR6E6cFTaz0Uxh0s0yikwGKDTDs5IiWx7Ze+NcLx/"

import_config "#{config_env()}.exs"
