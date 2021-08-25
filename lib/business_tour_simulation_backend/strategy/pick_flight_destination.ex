defmodule MonopolySimulation.Strategy.PickFlightDestination do
  alias MonopolySimulation.Strategy.Variations
  alias MonopolySimulation.{GameState, Strategy}

  @behaviour Variations

  @type variations :: :never | :random

  @spec variations :: [variations]
  def variations(),
    do: [:never, :random]

  @spec never(Strategy.venue_options, %GameState{}) :: Strategy.pick_flight_destination_decision
  def never(_options, _game_state), do: -1

  @spec random(Strategy.venue_options, %GameState{}) :: Strategy.pick_flight_destination_decision
  def random(options, _game_state), do: Enum.random(options.cities ++ options.resorts).id
end
