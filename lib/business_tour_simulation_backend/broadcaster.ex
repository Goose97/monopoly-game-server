defmodule MonopolySimulation.Broadcaster do
  alias MonopolySimulationBackendWeb.Endpoint

  def broadcast(game_id, event, payload) do
    channel = "game:#{game_id}"
    Endpoint.broadcast(channel, event, payload)
  end
end
