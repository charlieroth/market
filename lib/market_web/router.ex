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
    put "/content/:id", ContentController, :update
    get "/content/:id", ContentController, :show
    post "/content/:id/purchase", ContentController, :purchase

    get "/user/:user_id/content", ContentController, :content_for_user

    post "/purchase/complete/:purchase_id", ContentController, :complete_purchase
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
