defmodule MonopolySimulation.GameSystem do
  alias MonopolySimulation.Data
  # This module deals with a bunch of system mechanic
  # Dice, chances, ...

  def roll_dices() do
    [roll_dice(), roll_dice()]
  end

  defp roll_dice(), do: :rand.uniform(6)

  def random_player(number_of_players), do: :rand.uniform(number_of_players)

  def pair_dices?([same_number, same_number]), do: true
  def pair_dices?(_), do: false
  def random_chance() do
    Data.chances()
    |> Map.to_list()
    |> Enum.random()
    |> elem(0)
  end

  def random_festival_venues(amount) do
    all_venues = Data.venue_info()
    Enum.reduce(1..amount, [], fn _, acc ->
      random_position = get_random_rentable(all_venues, acc)
      [random_position | acc]
    end)
    |> Enum.map(& Enum.at(all_venues, &1)["id"])
  end

  defp get_random_rentable(all_venues, exclude_venues) do
    random_position = :rand.uniform(length(all_venues))
    case Enum.at(all_venues, random_position) do
      %{"type" => type} when type in [:city, :resort] ->
        if random_position in exclude_venues,
          do: get_random_rentable(all_venues, exclude_venues),
          else: random_position

      _ -> get_random_rentable(all_venues, exclude_venues)
    end
  end
end
