defmodule MonopolySimulation.Strategy.Build do
  alias MonopolySimulation.Strategy.Variations
  alias MonopolySimulation.Venue.{City, Resort}
  alias MonopolySimulation.GameState

  @behaviour Variations

  @type build_option :: %{rent_price: non_neg_integer(), cost: non_neg_integer(), level: non_neg_integer()}

  @spec variations :: [:never | :random | :most_expensive | :cheapest]
  def variations(),
    do: [:most_expensive, :cheapest]

  @spec most_expensive(%City{}, [build_option], %GameState{}) :: Strategy.build_decision
  @spec most_expensive(%Resort{}, [build_option], %GameState{}) :: Strategy.build_decision
  # Rich kid - go as expensive as you can afford
  def most_expensive(_venue, options, _game_state), do: length(options) - 1

  @spec cheapest(%City{}, [build_option], %GameState{}) :: Strategy.build_decision
  @spec cheapest(%Resort{}, [build_option], %GameState{}) :: Strategy.build_decision
  # Real eatate investor - as long as you own the land
  def cheapest(_venue, _options, _game_state), do: 0

  @spec never(%City{}, [build_option], %GameState{}) :: Strategy.build_decision
  @spec never(%Resort{}, [build_option], %GameState{}) :: Strategy.build_decision
  def never(_venue, _options, _game_state), do: -1

  @spec random(%City{}, [build_option], %GameState{}) :: Strategy.build_decision
  @spec random(%Resort{}, [build_option], %GameState{}) :: Strategy.build_decision
  def random(_venue, options, _game_state), do: Enum.random(-1..length(options) - 1)
end
