defmodule Market.Application do
  @moduledoc """
  Entry point for the `Market` application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MarketWeb.Telemetry,
      Market.Repo,
      {Phoenix.PubSub, name: Market.PubSub},
      {Finch, name: Market.Finch},
      MarketWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Market.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MarketWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
