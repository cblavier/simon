defmodule SimonWeb.GameView do
  use SimonWeb, :view

  def active_class(active_button, active_button), do: "active"
  def active_class(_, _), do: ""
end
