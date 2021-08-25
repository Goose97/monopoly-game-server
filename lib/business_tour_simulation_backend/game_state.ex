defmodule MonopolySimulation.GameState do
  use Accessible
  alias MonopolySimulation.Player
  alias MonopolySimulation.{Venue, Data, GameState}
  alias MonopolySimulation.Venue.{City, Resort, WorldChampionship, Jail}

  defstruct [
    :venues,
    :players,
    :next_player,
    :dices,
    :turn_count,
    jail: %Jail{},
    world_championship: %WorldChampionship{}
  ]

  def update_venue(game_state, %City{} = city) do
    city_index = Enum.find_index(game_state.venues.cities, & &1.id == city.id)
    put_in(game_state, [:venues, :cities, Access.at(city_index)], city)
  end

  def update_venue(game_state, %Resort{} = resort) do
    resort_index = Enum.find_index(game_state.venues.resorts, & &1.id == resort.id)
    put_in(game_state, [:venues, :resorts, Access.at(resort_index)], resort)
  end

  def get_venue(game_state, venue_id, :city) do
    Enum.find(game_state.venues.cities, & &1.id == venue_id)
  end

  def get_venue(game_state, venue_id, :resort) do
    Enum.find(game_state.venues.resorts, & &1.id == venue_id)
  end

  def get_player(game_state, player_id),
    do: Enum.find(game_state.players, & &1.id == player_id)

  def update_player(game_state, %Player.State{} = player) do
    player_index = Enum.find_index(game_state.players, & &1.id == player.id)
    put_in(game_state, [:players, Access.at(player_index)], player)
  end

  def update_dices(game_state, dices), do: put_in(game_state, [:dices], dices)

  def increment_turn_count(%{turn_count: nil} = game_state),
    do: %{game_state | turn_count: 0}
  def increment_turn_count(%{turn_count: turn_count} = game_state),
    do: %{game_state | turn_count: turn_count + 1}

  def increment_world_championship_count(game_state) do
    updated_world_championship = Map.update!(game_state.world_championship, :counter, & &1 + 1)
    %{game_state | world_championship: updated_world_championship}
  end

  def monopoly?(game_state, venue) do
    venue_type =
      case venue do
        %City{} -> :city
        %Resort{} -> :resort
      end
    group = Venue.monopoly_group(venue)
    Enum.all?(group, fn id ->
      venue_in_group = get_venue(game_state, id, venue_type)
      venue_in_group.owner != nil && venue_in_group.owner == venue.owner
    end)
  end

  def player_own_venues(game_state, player_id) do
    cities = Enum.filter(game_state.venues.cities, & &1.owner == player_id)
    resorts = Enum.filter(game_state.venues.resorts, & &1.owner == player_id)
    %{
      cities: cities,
      resorts: resorts
    }
  end

  def opponent_venues(game_state, player_id) do
    cities = Enum.filter(game_state.venues.cities, & &1.owner not in [nil, player_id])
    resorts = Enum.filter(game_state.venues.resorts, & &1.owner not in [nil, player_id])
    %{
      cities: cities,
      resorts: resorts
    }
  end

  def change_world_championship_host(game_state, venue),
    do: put_in(game_state, [:world_championship, :host], venue.id)

  def viable_flight_destinations(game_state, player_id) do
    cities = Enum.filter(game_state.venues.cities, & &1.owner in [player_id, nil])
    resorts = Enum.filter(game_state.venues.resorts, & &1.owner in [player_id, nil])
    %{
      cities: cities,
      resorts: resorts
    }
  end

  def put_player_to_jail(game_state, player_id),
    do: %{game_state | jail: Venue.put_player_to_jail(game_state.jail, player_id)}

  def get_player_out_of_jail(game_state, player_id),
    do: %{game_state | jail: Venue.get_player_out_of_jail(game_state.jail, player_id)}

  def increment_jail_turn_counter(game_state, player_id),
    do: %{game_state | jail: Venue.increment_jail_turn_counter(game_state.jail, player_id)}

  def player_in_jail?(game_state, player_id),
    do: Venue.player_in_jail?(game_state.jail, player_id)

  def evaluate_rent_price(game_state) do
    updated_venues =
      for {type, venues} <- game_state.venues, into: %{} do
        {
          type,
          Enum.map(venues, & Venue.evaluate_rent_price(&1, game_state))
        }
      end

    %{game_state | venues: updated_venues}
  end

  # There are 3 win conditions:
  # 1. All but one are bankrupts
  # 2. One player has 3 city monoplies
  # 3. One player has a resort monopoly
  # 4. One player has a side monopoly
  def finished?(game_state) do
    with(
      {:all_bankrupt, nil} <- {:all_bankrupt, won_by_bankrupts(game_state)},
      {:city_monopoly, nil} <- {:city_monopoly, won_by_city_monopoly(game_state)},
      {:resort_monopoly, nil} <- {:resort_monopoly, won_by_resort_monopoly(game_state)},
      {:side_monopoly, nil} <- {:side_monopoly, won_by_side_monopoly(game_state)}
    ) do
      false
    else
      {win_reason, ranking} -> {win_reason, ranking}
    end
  end

  defp won_by_bankrupts(game_state) do
    remain_players = Enum.filter(game_state.players, & &1.bankrupt_turn == nil)
    case remain_players do
      [won_player] -> rank_players(game_state, won_player.id)
      _ -> nil
    end
  end

  defp won_by_city_monopoly(game_state) do
    city_groups = Enum.group_by(game_state.venues.cities, &Venue.monopoly_group/1)
    won_player = Enum.find(game_state.players, fn player ->
      monopoly_count = Enum.filter(city_groups, fn {_, cities} ->
        Enum.all?(cities, & &1.owner == player.id)
      end) |> length

      monopoly_count == Data.monopoly_to_win()
    end)

    if won_player, do: rank_players(game_state, won_player.id)
  end

  defp won_by_resort_monopoly(game_state) do
    won_player = Enum.find(game_state.players, fn player ->
      Enum.all?(game_state.venues.resorts, & &1.owner == player.id)
    end)

    if won_player, do: rank_players(game_state, won_player.id)
  end

  defp won_by_side_monopoly(game_state) do
    venue_info = Data.venue_info()

    same_owner? = fn venues ->
      Enum.filter(venues, & &1["type"] in [:city, :resort])
      |> Enum.map(fn %{"id" => id, "type" => type} ->
        get_venue(game_state, id, type).owner
      end)
      |> Enum.uniq()
      |> case do
        [owner] -> owner != nil
        _ -> false
      end
    end

    quarter = div(length(venue_info), 4)
    side_with_same_owner =
      Enum.chunk_every(venue_info, quarter)
      |> Enum.find(same_owner?)

    won_player_id =
      if side_with_same_owner do
        %{"id" => id, "type" => type} = Enum.find(side_with_same_owner, & &1["type"] in [:city, :resort])
        GameState.get_venue(game_state, id, type).owner
      end
    if won_player_id, do: rank_players(game_state, won_player_id)
  end

  defp rank_players(game_state, won_player) do
    player_status = fn
      %{id: player_id, bankrupt_turn: nil} ->
        %{cities: cities, resorts: resorts} = player_own_venues(game_state, player_id)
        total_worth = Enum.map(cities ++ resorts, &Venue.worth/1) |> Enum.sum()
        {:not_bankrupt, total_worth}

      %{bankrupt_turn: turn} -> {:bankrupt, turn}
    end

    remain_players = Enum.filter(game_state.players, & &1.id != won_player)
    remain_players = Enum.sort_by(remain_players, player_status, fn
      {:bankrupt, _}, {:not_bankrupt, _} -> false
      {:not_bankrupt, _}, {:bankrupt, _} -> true
      {:bankrupt, turn_1}, {:bankrupt, turn_2} -> turn_1 > turn_2
      {:not_bankrupt, worth_1}, {:not_bankrupt, worth_2} -> worth_1 > worth_2
    end)

    [won_player | Enum.map(remain_players, & &1.id)]
  end
end
