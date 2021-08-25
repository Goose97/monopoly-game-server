defmodule MonopolySimulationBackendWeb.GameChannel do
  use Phoenix.Channel
  alias MonopolySimulation.{Game, Broadcaster, Data}

  def join("game:" <> game_id, _message, socket) do
    spawn(fn ->
      Process.sleep(50)
      push_game_state(game_id)
      push_game_data(game_id)
    end)
    {:ok, socket}
  end

  def handle_in("input:keyboard", %{"action" => action}, socket) do
    "game:" <> game_id = socket.topic
    Game.control_game_progress(game_id, action)
    {:noreply, socket}
  end

  defp push_game_state(game_id) do
     case Game.get_game_state(game_id) do
      {:ok, game_state} -> Broadcaster.broadcast(game_id, "game:init", game_state)
      {:error, _error} -> :ignore
     end
  end

  defp push_game_data(game_id) do
    venue_info = Data.venue_info()
    chances = Data.chances()
    Broadcaster.broadcast(game_id, "game:data", %{venue_info: venue_info, chance_info: chances})
  end
end
