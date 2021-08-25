defmodule MonopolySimulation.Strategy.Sell do
  alias MonopolySimulation.Strategy.Variations
  alias MonopolySimulation.{GameState, Strategy, Venue}

  @behaviour Variations

  @type variations :: :least_venue_possible | :least_money_possible

  @spec variations :: [variations]
  def variations(),
    do: [:least_venue_possible, :least_money_possible]

  @spec least_venue_possible(non_neg_integer(), Strategy.venue_options, %GameState{}) :: Strategy.sell_decision
  def least_venue_possible(minimum, options, _game_state) do
    Enum.sort_by(
      options.cities ++ options.resorts,
      &Venue.worth/1,
      &>=/2
    )
    |> do_least_venue_possible(minimum)
    |> Enum.map(& &1.id)
  end

  @spec least_money_possible(non_neg_integer(), Strategy.venue_options, %GameState{}) :: Strategy.sell_decision
  def least_money_possible(minimum, options, _game_state) do
    Process.put(:memo, %{})
    {_, picked} = least_money_possible_sub_problem(
      minimum,
      options.cities ++ options.resorts
    )
    MapSet.to_list(picked)
  end

  # This is a variation of the knapsack problem
  defp least_money_possible_sub_problem(_minimum, _options, picked \\ MapSet.new())
  defp least_money_possible_sub_problem(minimum, _options, picked) when minimum <= 0,
    do: {0, picked}
  defp least_money_possible_sub_problem(minimum, options, picked) do
    memo = Process.get(:memo)
    case Map.get(memo, picked) do
      {lowest, lowest_picked} -> {lowest, lowest_picked}
      _ ->
        # We pick each option and find out which is the best we can do
        # if we pick this option
        sub_problem_result = Enum.reduce(options, {nil, nil}, fn option, acc ->
          if MapSet.member?(picked, option.id) do
            acc
          else
            worth = Venue.worth(option)
            {lowest, lowest_pick} =
              least_money_possible_sub_problem(
                minimum - worth,
                options,
                MapSet.put(picked, option.id)
              )

            cond do
              elem(acc, 0) == nil -> {worth + lowest, lowest_pick}
              worth + lowest < elem(acc, 0) -> {worth + lowest, lowest_pick}
              true -> acc
            end
          end
        end)

        memo = Process.get(:memo)
        Process.put(:memo, Map.put(memo, picked, sub_problem_result))
        sub_problem_result
    end
  end

  defp speed_test do
    cities =
      MonopolySimulation.Data.venue_info
      |> Enum.filter(fn %{"type" => type} -> type == :city end)
      |> Enum.map(fn %{"id" => id} ->
        %MonopolySimulation.Venue.City{
          id: id,
          level: 5
        }
      end)

    resorts =
      MonopolySimulation.Data.venue_info
      |> Enum.filter(fn %{"type" => type} -> type == :resort end)
      |> Enum.map(fn %{"id" => id} ->
        %MonopolySimulation.Venue.Resort{
          id: id
        }
      end)

    options = %{cities: cities, resorts: resorts}
    minimum = 5130.5
    from = System.monotonic_time(:millisecond)
    MonopolySimulation.Strategy.Sell.least_money_possible(minimum, options, 1)
    to = System.monotonic_time(:millisecond)

    (to - from) / 1000
  end

  defp do_least_venue_possible(_options, _minimum, sold_money \\ 0, sold_venues \\ [])
  defp do_least_venue_possible(_, minimum, sold_money, sold_venues)
    when sold_money >= minimum, do: sold_venues
  defp do_least_venue_possible([head | tail], minimum, sold_money, sold_venues),
    do: do_least_venue_possible(tail, minimum, sold_money + Venue.worth(head), [head | sold_venues])
end
