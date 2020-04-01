defmodule SimonWeb.PageController do
  use SimonWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
