defmodule MonopolySimulation.Strategy.PickChance do
  alias MonopolySimulation.Strategy.Variations
  alias MonopolySimulation.{GameState, Strategy}
  use Strategy.General

  @behaviour Variations

  @type variations :: :random | :most_expensive | :cheapest | :highest_rent_price | :lowest_rent_price

  @spec variations :: [variations]
  def variations(),
    do: [:never, :random, :most_expensive, :cheapest, :highest_rent_price, :lowest_rent_price]

  @spec random(Strategy.venue_options, %GameState{}) :: Strategy.pick_chance_decision
  def random(options, _game_state) do
    venue = Enum.random(options.cities ++ options.resorts)
    venue.id
  end

  # This one is for gift action
  def random(options, opponents, _game_state) do
    venue = Enum.random(options.cities ++ options.resorts)
    opponent = Enum.random(opponents)
    {venue.id, opponent.id}
  end

  def most_expensive(options, _, game_state),
    do: Strategy.General.most_expensive(options, game_state)

  def cheapest(options, _, game_state),
    do: Strategy.General.cheapest(options, game_state)
end
