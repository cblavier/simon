defmodule Simon.GameServer do
  use GenServer

  @sequence_size 100_000
  @sequence_delay 500
  @colors ~w(green red yellow blue)a

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    sequence = Keyword.get(opts, :sequence, build_sequence())

    {:ok,
     %{
       turn: 0,
       watchers: [],
       players: [],
       sequence: sequence,
       current_guess_sequence: [],
       current_player: nil,
       status: :waiting_for_start
     }}
  end

  def watch(pid, watcher), do: GenServer.cast(pid, {:watch, watcher})
  def join(pid, player), do: GenServer.cast(pid, {:join, player})
  def start(pid), do: GenServer.cast(pid, :start)
  def color_guess(pid, color), do: GenServer.call(pid, {:color_guess, color})

  def handle_cast({:watch, watcher}, state = %{watchers: watchers}) do
    {:noreply, %{state | watchers: [watcher | watchers]}}
  end

  def handle_cast({:join, player}, state = %{players: players}) do
    {:noreply, %{state | players: [player | players]}}
  end

  def handle_cast(:start, state = %{sequence: sequence, status: :waiting_for_start, turn: 0}) do
    turn = 1
    player = game_server_turn(state.players, state.watchers, sequence, turn)
    notify_listeners(state.players ++ state.watchers, {:current_player, player})

    {:noreply,
     %{
       state
       | turn: turn,
         status: :waiting_for_player_input,
         current_player: player,
         current_guess_sequence: []
     }}
  end

  def handle_call(
        {:color_guess, _guess},
        {from_pid, _ref},
        state = %{current_player: current_player}
      )
      when current_player != from_pid do
    {:reply, :invalid_player, state}
  end

  def handle_call(
        {:color_guess, guess},
        _from,
        state = %{turn: turn, sequence: sequence, current_guess_sequence: current_guess_sequence}
      ) do
    current_guess_sequence = current_guess_sequence ++ [guess]
    correct_sequence = Enum.take(sequence, length(current_guess_sequence))
    state = %{state | current_guess_sequence: current_guess_sequence}

    if correct_sequence == current_guess_sequence do
      if length(correct_sequence) == turn do
        turn = turn + 1
        game_server_turn(state.players, state.watchers, sequence, turn)
        state = %{state | turn: turn, current_guess_sequence: []}
        {:reply, :ok, state}
      else
        {:reply, :ok, state}
      end
    else
      end_game(:lose, state.players ++ state.watchers)
      {:reply, :bad_guess, state}
    end
  end

  def handle_info(:halt, state) do
    {:stop, :normal, state}
  end

  defp build_sequence do
    Enum.map(
      1..@sequence_size,
      fn _ -> Enum.random(@colors) end
    )
  end

  defp game_server_turn(players, watchers, sequence, turn) do
    if turn < length(sequence) + 1 do
      play_sequence(players ++ watchers, sequence, turn)
      give_player_turn(players, turn)
    else
      end_game(:win, players ++ watchers)
    end
  end

  defp play_sequence(listeners, sequence, turn) do
    sequence = Enum.take(sequence, turn)

    Enum.each(sequence, fn color ->
      Enum.each(listeners, fn pid ->
        Process.send(pid, {:sequence_color, turn, color}, [])
        :timer.sleep(@sequence_delay)
      end)
    end)
  end

  defp give_player_turn(players, turn) do
    player = Enum.random(players)
    Process.send(player, {:your_turn, turn}, [])
    player
  end

  defp notify_listeners(listeners, message) do
    Enum.each(listeners, fn pid ->
      Process.send(pid, message, [])
    end)
  end

  defp end_game(status, listeners) do
    notify_listeners(listeners, status)
    Process.send(self(), :halt, [])
  end
end
