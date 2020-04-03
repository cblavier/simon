defmodule Simon.RandomServer do
  alias Simon.GameServer

  @colors ~w(green red yellow blue)a
  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_), do: {:ok, nil}

  def play(pid, game_server, turn) do
    GenServer.cast(pid, {:play, game_server, turn})
  end

  def handle_cast({:play, game_server, turn}, _from, state) do
    1..turn
    |> Enum.map(fn _ -> Enum.random(@colors) end)
    |> Enum.each(&GameServer.play(game_server, &1))

    {:noreply, state}
  end
end
