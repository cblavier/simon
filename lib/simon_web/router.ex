defmodule SimonWeb.Router do
  use SimonWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {SimonWeb.LayoutView, :root}
  end

  scope "/", SimonWeb do
    pipe_through :browser

    live "/", HomeLive
  end
end
