defmodule SimonWeb.GameView do
  use SimonWeb, :view

  def active_class(active_button, active_button), do: "active"
  def active_class(_, _), do: ""

  def active_player_class(pid, {pid, _name}), do: "active"
  def active_player_class(_, _), do: ""
end
