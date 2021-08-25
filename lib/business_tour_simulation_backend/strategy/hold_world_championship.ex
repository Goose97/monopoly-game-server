defmodule MonopolySimulation.Strategy.HoldWorldChampionship do
  alias MonopolySimulation.Strategy.Variations
  alias MonopolySimulation.{GameState, Strategy}
  use Strategy.General, only: [:lowest_rent_price, :highest_rent_price]

  @behaviour Variations

  @type variations :: :never | :lowest_rent_price | :highest_rent_price

  @spec variations :: [variations]
  def variations(),
    do: [:never, :lowest_rent_price, :highest_rent_price]

  @spec never(Strategy.venue_options, %GameState{}) :: Strategy.hold_world_championship_decision
  def never(_options, _game_state), do: -1
end
