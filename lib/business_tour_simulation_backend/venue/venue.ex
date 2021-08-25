defmodule MonopolySimulation.Venue do
  alias __MODULE__.{City, Resort, Jail}
  alias MonopolySimulation.{Player, Data, GameState}

  def type(%City{}), do: :city
  def type(%Resort{}), do: :resort

  # Q: Which upgrade/purchase can you perform on this venue at this moment?
  # And how much money does it cost?
  def available_upgrades(%City{} = city) do
    current_level = if city.level, do: city.level, else: 0
    city_info = Data.city(city.id)

    Enum.with_index(city_info)
    |> Enum.filter(fn {_, index} ->
      upgrade_level = index + 1
      cond do
        current_level === 5 -> false
        current_level === 4 -> upgrade_level === 5
        true -> upgrade_level > current_level && upgrade_level != 5
      end
    end)
    |> Enum.map(fn {info, index} ->
      upgrade_level = index + 1
      # We don't have to pay the full price if we're upgrading
      %{"rent_price" => rent_price, "cost" => cost} = info
      real_cost = cost - worth(city)
      %{rent_price: rent_price, cost: real_cost, level: upgrade_level}
    end)
  end

  def available_upgrades(%Resort{} = resort) do
    if resort.owner == nil,
      do: [%{rent_price: 25, cost: Data.resort_cost(), level: 1}],
      else: []
  end

  # Q: How much many this venue worth?
  def worth(%City{} = city) do
    current_level = if city.level, do: city.level, else: 0
    city_info = Data.city(city.id)
    if current_level != 0 do
      %{"cost" => cost} =
        Enum.with_index(city_info)
        |> Enum.find(fn {_, index} -> index + 1 == current_level end)
        |> elem(0)

      cost
    else
      0
    end
  end

  def worth(%Resort{} = _resort), do: Data.resort_cost()

  def evaluate_rent_price(%{owner: nil} = venue, _game_state), do: venue
  def evaluate_rent_price(venue, game_state),
    do: %{venue | rent_price: rent_price(venue, game_state)}

  # Q: How much rent does one have to pay if step into this venue? (multiplier included)
  def rent_price(%City{} = city, game_state) do
    city_modifiers =
      if GameState.monopoly?(game_state, city),
        do: MapSet.put(city.modifiers, :monopoly),
        else: city.modifiers

    city.rent_price * rent_multiplier(city_modifiers)
  end

  def rent_price(%Resort{} = resort, game_state) do
    owned_resorts_count = Enum.filter(
      game_state.venues.resorts,
      & &1.owner == resort.owner
    ) |> length
    base_price = get_in(Data.resorts(), ["rent_price", Access.at(owned_resorts_count - 1)])
    base_price * rent_multiplier(resort.modifiers)
  end

  # Q: How many multiplier is having on this venue?
  defp rent_multiplier(venue_modifiers) do
    Enum.map(venue_modifiers, fn
      :monopoly -> 1
      :festival -> 1
      {:world_championship, multiplier} -> multiplier
      _ -> 0
    end)
    |> Enum.sum()
    |> Kernel.+(1)
  end

  # Q: How much money does it cost to repurchase this venue?
  def repurchase_price(%City{} = city), do: Data.repurchase_factor() * worth(city)

  # Q: Which venues are in monopoply group of this venue?
  def monopoly_group(%City{} = city), do: monopoly_group(city.id)
  def monopoly_group(%Resort{} = resort), do: monopoly_group(resort.id)
  for group <- Data.monopoly_groups() do
    def monopoly_group(venue_id) when venue_id in unquote(group), do: unquote(group)
  end

  def destroy(%City{} = city), do: %City{id: city.id}
  def destroy(%Resort{} = resort), do: %Resort{id: resort.id}

  def gift(venue, recipient), do: %{venue | owner: recipient}

  # Q: Is this venue repurchaseable?
  def repurchasable?(%City{} = city), do: !hotel?(city) && :protected not in city.modifiers
  def repurchasable?(%Resort{} = _resort), do: false

  def targetable?(%City{} = city), do: !hotel?(city) && :protected not in city.modifiers
  def targetable?(%Resort{} = resort), do: :protected not in resort.modifiers

  # Q: Is this venue giftable?

  # Q: Is this city has hotels?
  def hotel?(%City{} = city), do: city.level == 5

  def out_of_electricity?(venue, %Player.State{completed_rounds: completed_rounds}) do
    MapSet.to_list(venue.modifiers)
    |> Enum.any?(fn
      {:electricity_outage, from_round} ->
        completed_rounds - from_round < Data.electriciy_outage_duration()

      _ -> false
    end)
  end

  # Q: Is this venue out of electricity?
  def hold_world_championship(venue, world_championship_held_count) do
    if venue == nil, do: IO.inspect(venue, label: "1006")
    venue = close_world_championship(venue)
    modifiers = MapSet.put(
      venue.modifiers,
      {:world_championship, world_championship_held_count + 1}
    )

    %{venue | modifiers: modifiers}
  end

  def close_world_championship(venue) do
    modifiers_list = MapSet.to_list(venue.modifiers)
    new_modifiers =
      Enum.filter(modifiers_list, fn
        {:world_championship, _nth} -> false
        _ -> true
      end)

    %{venue | modifiers: MapSet.new(new_modifiers)}
  end

  def add_modifier(venue, modifier),
    do: %{venue | modifiers: MapSet.put(venue.modifiers, modifier)}

  def remove_modifier(venue, modifier),
    do: %{venue | modifiers: MapSet.delete(venue.modifiers, modifier)}

  def downgrade(%City{} = city) do
    case city.level do
      1 -> destroy(city)
      level ->
        city_info = Data.city(city.id)
        downgraded_level = level - 1
        %{"rent_price" => rent_price} = Enum.at(city_info, downgraded_level - 1)
        %City{city | level: downgraded_level, rent_price: rent_price}
    end
  end

  def downgrade(%Resort{} = resort), do: destroy(resort)

  def put_player_to_jail(%Jail{} = jail, player_id) do
    updated_players = Map.put(jail.players, player_id, %Jail.Player{id: player_id})
    %Jail{jail | players: updated_players}
  end

  def get_player_out_of_jail(%Jail{} = jail, player_id) do
    updated_players = Map.delete(jail.players, player_id)
    %Jail{jail | players: updated_players}
  end

  def increment_jail_turn_counter(%Jail{} = jail, player_id) do
    updated_players = Map.update!(jail.players, player_id, fn state ->
      %{state | turn_count: state.turn_count + 1}
    end)
    %Jail{jail | players: updated_players}
  end

  def player_in_jail?(%Jail{} = jail, player_id), do: Map.has_key?(jail.players, player_id)
end
