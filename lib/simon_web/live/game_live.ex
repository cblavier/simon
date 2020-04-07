defmodule SimonWeb.GameLive do
  use Phoenix.LiveView

  alias Simon.GameServer
  alias SimonWeb.GameView

  @sequence_size 10
  @round_delay 1000
  @sequence_delay 200
  @guess_delay 700
  @button_highlight_duration 500

  # @player_configs [
  #   [module: BricePlayer, name: "Brice"],
  #   [module: MatthieuPlayer, name: "Matthieu"],
  #   [module: RemyPlayer, name: "Rémy"]
  # ]

  @player_configs []

  def render(assigns) do
    GameView.render("index.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok, game_server} =
      GameServer.start_link(
        sequence_delay: @sequence_delay,
        sequence_size: @sequence_size,
        round_delay: @round_delay,
        guess_delay: @guess_delay
      )

    players =
      for [module: module, name: name] <- @player_configs do
        new_player(module, name, game_server)
      end

    GenServer.cast(game_server, {:watch, self()})

    {:ok,
     assign(socket,
       game_server: game_server,
       current_player: nil,
       active_button: nil,
       round: 0,
       status: :not_started,
       players: players,
       message: "Game ready, press to start!"
     )}
  end

  def handle_event("start", _opts, socket) do
    GenServer.cast(socket.assigns.game_server, :start)
    {:noreply, assign(socket, status: :running, round: 0)}
  end

  def handle_info({:sequence_color, round, color}, socket) do
    Process.send_after(self(), :disable_active_color, @button_highlight_duration)

    {:noreply,
     assign(socket, active_button: color, round: round, current_player: nil, message: "Simon says")}
  end

  def handle_info(:disable_active_color, socket) do
    {:noreply, assign(socket, active_button: nil)}
  end

  def handle_info({:current_player, {pid, player_name}}, socket) do
    current_player =
      Enum.find(socket.assigns.players, fn {player_pid, _, _} -> player_pid == pid end)

    {:noreply, assign(socket, current_player: current_player, message: "#{player_name}'s round")}
  end

  def handle_info({:guess, color, _}, socket) do
    Process.send_after(self(), :disable_active_color, @button_highlight_duration)
    {:noreply, assign(socket, active_button: color)}
  end

  def handle_info(:win, socket) do
    {:noreply,
     assign(socket, status: :lost, message: "Game completed at round #{socket.assigns.round}")}
  end

  def handle_info(:lose, socket) do
    {:noreply,
     assign(socket, status: :lost, message: "Game over at round #{socket.assigns.round}")}
  end

  defp new_player(module, name, game_server) do
    perk =
      if Keyword.has_key?(module.__info__(:functions), :supported_perks) do
        supported_perks = apply(module, :supported_perks, [])
        Enum.random(supported_perks ++ [nil])
      else
        nil
      end

    {:ok, player} =
      apply(module, :start_link, [
        [
          game_server: game_server,
          name: name,
          perk: perk,
          guess_delay: @guess_delay,
          round_delay: @round_delay
        ]
      ])

    {player, name, perk}
  end
end
