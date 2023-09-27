defmodule MarketWeb.Router do
  use MarketWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MarketWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MarketWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", MarketWeb do
    pipe_through :api

    post "/content", ContentController, :create

    get "/user/:user_id/content/purchased", ContentController, :purchased_content_for_user
    get "/user/:user_id/content/received", ContentController, :received_content_for_user
    get "/user/:user_id/content/:content_id", ContentController, :content_for_user

    post "/content/:content_id/purchase", ContentController, :purchase

    post "/purchase/:purchase_id/complete", ContentController, :complete_purchase
  end

  if Application.compile_env(:market, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MarketWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
