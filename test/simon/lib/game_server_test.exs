defmodule Simon.GameServerTest do
  use ExUnit.Case

  alias Simon.GameServer

  setup do
    {:ok, game_server} =
      GameServer.start_link(
        sequence_delay: 0,
        round_delay: 0,
        sequence: [:red, :green]
      )

    GenServer.cast(game_server, {:join, self(), "Bob"})
    GenServer.cast(game_server, :start)
    {:ok, %{game_server: game_server}}
  end

  test "good game sequence", %{game_server: game_server} do
    receive do
      {:sequence_color, round, color} ->
        assert round == 1
        assert color == :red
    end

    receive do
      {:your_round, round} ->
        assert round == 1
        assert :ok == color_guess(game_server, :red)
    end

    receive do
      {:sequence_color, round, color} ->
        assert round == 2
        assert color == :red
    end

    receive do
      {:sequence_color, round, color} ->
        assert round == 2
        assert color == :green
    end

    receive do
      {:your_round, round} ->
        assert round == 2
        assert :ok == color_guess(game_server, :red)
        assert :ok == color_guess(game_server, :green)
    end

    receive do
      :win -> assert true
    end
  end

  test "bad guess", %{game_server: game_server} do
    receive do
      {:sequence_color, round, color} ->
        assert round == 1
        assert color == :red
    end

    receive do
      {:your_round, round} ->
        assert round == 1
        assert :ok == color_guess(game_server, :red)
    end

    receive do
      {:sequence_color, round, color} ->
        assert round == 2
        assert color == :red
    end

    receive do
      {:sequence_color, round, color} ->
        assert round == 2
        assert color == :green
    end

    receive do
      {:your_round, round} ->
        assert round == 2
        assert :ok == color_guess(game_server, :red)
        assert :bad_guess == color_guess(game_server, :blue)
    end

    receive do
      :lose -> assert true
    end
  end

  defp color_guess(pid, color), do: GenServer.call(pid, {:color_guess, color})
end
