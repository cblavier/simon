defmodule Simon.GameServer do
  use GenServer

  @default_sequence_size 10
  @default_sequence_delay 500
  @default_round_delay 1000

  @colors ~w(green red yellow blue)a

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    sequence_size = Keyword.get(opts, :sequence_size, @default_sequence_size)
    sequence = Keyword.get(opts, :sequence, build_sequence(sequence_size))
    round_delay = Keyword.get(opts, :round_delay, @default_round_delay)

    sequence_delay = Keyword.get(opts, :sequence_delay, @default_sequence_delay)

    {:ok,
     %{
       round: 0,
       watchers: [],
       players: [],
       sequence: sequence,
       current_guess_sequence: [],
       current_player: nil,
       status: :waiting_for_start,
       sequence_delay: sequence_delay,
       round_delay: round_delay
     }}
  end

  def handle_cast({:watch, watcher}, state = %{watchers: watchers}) do
    {:noreply, %{state | watchers: [watcher | watchers]}}
  end

  def handle_cast({:join, player_pid, player_name}, state = %{players: players}) do
    {:noreply, %{state | players: [{player_pid, player_name} | players]}}
  end

  def handle_cast(:start, state = %{status: :waiting_for_start, round: 0}) do
    {new_player, new_round} = game_server_round(state)

    {:noreply,
     %{
       state
       | round: new_round,
         status: :waiting_for_player_input,
         current_player: new_player,
         current_guess_sequence: []
     }}
  end

  def handle_call(
        {:color_guess, _guess},
        {from_pid, _ref},
        state = %{current_player: {current_player_pid, _}}
      )
      when current_player_pid != from_pid do
    {:reply, :invalid_player, state}
  end

  def handle_call(
        {:color_guess, guess},
        _from,
        state = %{
          round: round,
          sequence: sequence,
          current_guess_sequence: current_guess_sequence
        }
      ) do
    current_guess_sequence = current_guess_sequence ++ [guess]
    correct_sequence = Enum.take(sequence, length(current_guess_sequence))
    state = %{state | current_guess_sequence: current_guess_sequence}
    state |> listeners |> notify_listeners({:guess, guess, state.current_player})

    if correct_sequence == current_guess_sequence do
      if length(correct_sequence) == round do
        {new_player, new_round} = game_server_round(state)

        state = %{
          state
          | round: new_round,
            current_player: new_player,
            current_guess_sequence: []
        }

        {:reply, :ok, state}
      else
        {:reply, :ok, state}
      end
    else
      end_game(:lose, listeners(state))
      {:reply, :bad_guess, state}
    end
  end

  def handle_info(:halt, state) do
    {:stop, :normal, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp build_sequence(size) do
    Enum.map(
      1..size,
      fn _ -> Enum.random(@colors) end
    )
  end

  defp game_server_round(state = %{players: players, sequence: sequence, round: round}) do
    if round < length(sequence) do
      :timer.sleep(state.round_delay)
      new_round = round + 1
      state |> listeners |> play_sequence(sequence, new_round, state.sequence_delay)
      new_player = give_player_round(players, new_round)

      :timer.sleep(state.round_delay)
      state |> listeners |> notify_listeners({:current_player, new_player})
      {new_player, new_round}
    else
      end_game(:win, listeners(state))
      {state.current_player, state.round}
    end
  end

  defp play_sequence(listeners, sequence, round, sequence_delay) do
    sequence = Enum.take(sequence, round)

    Enum.each(sequence, fn color ->
      Enum.each(listeners, fn pid ->
        Process.send(pid, {:sequence_color, round, color}, [])
        :timer.sleep(sequence_delay)
      end)
    end)
  end

  defp give_player_round(players, round) do
    player = {player_pid, _player_name} = Enum.random(players)
    Process.send(player_pid, {:your_round, round}, [])
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

  defp listeners(%{players: players, watchers: watchers}) do
    Enum.map(players, &elem(&1, 0)) ++ watchers
  end
end
