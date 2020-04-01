defmodule SimonWeb.HomeLive do
  use Phoenix.LiveView

  alias SimonWeb.HomeView

  def render(assigns) do
    HomeView.render("index.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
