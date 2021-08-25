defmodule MonopolySimulation.Moderator.PlayerDecision.Validator do
  alias MonopolySimulation.Venue

  def validate({:build, _venue, options}, decision) do
    validators = [
      is_integer: %{
        predicate: fn -> is_integer(decision) end,
        message: "Build decision is not an integer"
      },
      in_range: %{
        predicate: fn -> decision >= -1 && decision < length(options) end,
        message: "Build decision is out of range"
      }
    ]
    run_validators(validators)
  end

  def validate({:repurchase, _venue}, 1), do: {:ok, nil}
  def validate({:repurchase, _venue}, 0), do: {:ok, nil}
  def validate({:repurchase, _venue}, _), do: {:error, "Repurchase decision must be 1 or 0"}

  def validate({:sell, minimum, options}, venue_ids) do
    venues = Enum.map(venue_ids, & find_venue_in_options(&1, options))
    validators = [
      all_exist: %{
        predicate: fn -> nil not in venues end,
        message: "Some venues don't exist in options"
      },
      no_duplication: %{
        predicate: fn -> Enum.uniq(venue_ids) == venue_ids end,
        message: "Some venues are duplicated"
      },
      meet_minimum: %{
        predicate: fn ->
          total_worth = Enum.map(venues, &Venue.worth/1) |> Enum.sum()
          total_worth >= minimum
        end,
        message: "Total sell value hasn't meet the minimum #{minimum}"
      }
    ]
    run_validators(validators)
  end

  def validate({action, options}, decision)
    when action in [:hold_world_championship, :pick_flight_destination, :add_shield, :cut_electricity, :downgrade, :destroy, :force_sale]
  do
    validators = [
      is_valid_type: %{
        predicate: fn ->
          cond do
            is_integer(decision) -> decision == -1
            is_binary(decision) -> true
            true -> false
          end
        end,
        message: "Expect to get -1 or a venue id, instead got #{inspect(decision)}"
      },
      venue_exist: %{
        predicate: fn ->
          if is_binary(decision),
            do: find_venue_in_options(decision, options),
            else: true
        end,
        message: "Venue #{inspect(decision)} doesn't exist in options"
      }
    ]
    run_validators(validators)
  end

  def validate({:pick_jail_option, options}, decision) do
    validators = [
      is_valid_option: %{
        predicate: fn -> decision >= 0 && decision < length(options) end,
        message: if(
          length(options) == 1,
          do: "Expect to get 0, instead got #{inspect(decision)}",
          else: "Expect to get an integer from 0 to #{length(options) - 1}, instead got #{inspect(decision)}"
        )
      }
    ]
    run_validators(validators)
  end

  def validate({:gift, options, opponents}, decision) do
    {venue_id, opponent_id} = decision
    validators = [
      is_valid_venue_type: %{
        predicate: fn -> is_binary(venue_id) end,
        message: "Expect to get a venue id, instead got #{inspect(venue_id)}"
      },
      is_valid_opponent_type: %{
        predicate: fn -> is_binary(opponent_id) end,
        message: "Expect to get an opponent id, instead got #{inspect(opponent_id)}"
      },
      venue_exist: %{
        predicate: fn -> find_venue_in_options(venue_id, options) end,
        message: "Venue #{inspect(venue_id)} doesn't exist in options"
      },
      opponent_exist: %{
        predicate: fn -> Enum.find(opponents, & &1.id == opponent_id) end,
        message: "Opponent #{inspect(opponent_id)} doesn't exist in options"
      }
    ]
    run_validators(validators)
  end

  defp run_validators([]), do: {:ok, nil}
  defp run_validators([validator | tail]) do
    {_key, %{predicate: fun, message: message}} = validator
    if fun.(), do: run_validators(tail), else: {:error, message}
  end

  defp find_venue_in_options(venue_id, options) do
    Enum.find(options.cities ++ options.resorts, & &1.id == venue_id)
  end
end
