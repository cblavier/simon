defmodule Simon.GameServerTest do
  use ExUnit.Case

  alias Simon.GameServer

  test "good game sequence" do
    {:ok, game_server} = GameServer.start_link(sequence: [:red, :green])

    GameServer.join(game_server, self())
    GameServer.start(game_server)

    receive do
      {:sequence_color, turn, color} ->
        assert turn == 1
        assert color == :red
    end

    receive do
      {:your_turn, turn} ->
        assert turn == 1
        assert :ok == GameServer.color_guess(game_server, :red)
    end

    receive do
      {:sequence_color, turn, color} ->
        assert turn == 2
        assert color == :red
    end

    receive do
      {:sequence_color, turn, color} ->
        assert turn == 2
        assert color == :green
    end

    receive do
      {:your_turn, turn} ->
        assert turn == 2
        assert :ok == GameServer.color_guess(game_server, :red)
        assert :ok == GameServer.color_guess(game_server, :green)
    end

    receive do
      :win -> assert true
    end
  end

  test "bad guess" do
    {:ok, game_server} = GameServer.start_link(sequence: [:red, :green])

    GameServer.join(game_server, self())
    GameServer.start(game_server)

    receive do
      {:sequence_color, turn, color} ->
        assert turn == 1
        assert color == :red
    end

    receive do
      {:your_turn, turn} ->
        assert turn == 1
        assert :ok == GameServer.color_guess(game_server, :red)
    end

    receive do
      {:sequence_color, turn, color} ->
        assert turn == 2
        assert color == :red
    end

    receive do
      {:sequence_color, turn, color} ->
        assert turn == 2
        assert color == :green
    end

    receive do
      {:your_turn, turn} ->
        assert turn == 2
        assert :ok == GameServer.color_guess(game_server, :red)
        assert :bad_guess == GameServer.color_guess(game_server, :blue)
    end

    receive do
      :lose -> assert true
    end
  end
end
