defmodule MonopolySimulation.Strategy.General do
  alias MonopolySimulation.Venue

  @all_strategies [:lowest_rent_price, :highest_rent_price, :most_expensive, :cheapest]

  defmacro __using__(params) do
    alias MonopolySimulation.Strategy

    strategies = Keyword.get(params, :only, @all_strategies)

    for strategy <- strategies do
      quote do
        defdelegate unquote(strategy)(options, game_state), to: Strategy.General
      end
    end
  end

  def lowest_rent_price(options, game_state) do
    venue = Enum.min_by(
      options.cities ++ options.resorts,
      & evaluate_rent_price(&1, game_state)
    )
    venue.id
  end

  def highest_rent_price(options, game_state) do
    venue = Enum.max_by(
      options.cities ++ options.resorts,
      & evaluate_rent_price(&1, game_state)
    )
    venue.id
  end

  def most_expensive(options, _game_state) do
    mose_expensive = Enum.max_by(options.cities ++ options.resorts, &Venue.worth/1)
    mose_expensive.id
  end

  def cheapest(options, _game_state) do
    cheapest = Enum.min_by(options.cities ++ options.resorts, &Venue.worth/1)
    cheapest.id
  end

  defp evaluate_rent_price(venue, game_state) do
    world_championship_held_count = get_in(game_state, [:world_championship, :counter])
    venue
    |> Venue.hold_world_championship(world_championship_held_count)
    |> Venue.rent_price(game_state)
  end
end
