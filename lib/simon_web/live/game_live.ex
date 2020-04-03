defmodule SimonWeb.GameLive do
  use Phoenix.LiveView

  alias Simon.GameServer
  alias SimonWeb.GameView

  @turn_delay 2000
  @sequence_delay 1000
  @sequence_pause_delay 500

  def render(assigns) do
    GameView.render("index.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok, game_server} = GameServer.start_link()
    {turn, sequence} = GameServer.current_turn_sequence(game_server)
    Process.send_after(self(), {:play_sequence, sequence}, @turn_delay)

    {:ok,
     assign(socket,
       game_server: game_server,
       active_button: nil,
       current_turn: turn
     )}
  end

  def handle_info({:play_sequence, []}, socket = %{assigns: %{game_server: game_server}}) do
    {turn, sequence} = GameServer.current_turn_sequence(game_server)
    Process.send_after(self(), {:play_sequence, sequence}, @turn_delay)
    {:noreply, assign(socket, active_button: nil, current_turn: turn)}
  end

  def handle_info({:play_sequence, [head | tail]}, socket) do
    Process.send_after(self(), {:sequence_pause, tail}, @sequence_delay)
    {:noreply, assign(socket, active_button: head)}
  end

  def handle_info({:sequence_pause, sequence}, socket) do
    Process.send_after(self(), {:play_sequence, sequence}, @sequence_pause_delay)
    {:noreply, assign(socket, active_button: nil)}
  end
end
