defmodule MonopolySimulation.Moderator.Planner do
  alias MonopolySimulation.{Data, Player, Venue, GameState, GameSystem}
  alias MonopolySimulation.Venue.{City, Resort}

  def initial_game_state(game_config) do
    venues = initial_venues_state()
    players = initial_players_state(game_config)
    %GameState{
      venues: venues,
      players: players,
      dices: nil
    }
  end

  defp initial_venues_state do
    venue_ids = GameSystem.random_festival_venues(Data.festival_venues_amount())
    cities =
      Data.cities()
      |> Map.keys()
      |> Enum.map(fn city_id ->
        modifiers =
          if city_id in venue_ids do
            MapSet.new([:festival])
          else
            MapSet.new()
          end
        %City{id: city_id, modifiers: modifiers}
      end)

    resorts =
      Data.resorts()
      |> Map.get("id")
      |> Enum.map(fn resort_id ->
        modifiers =
          if resort_id in venue_ids do
            MapSet.new([:festival])
          else
            MapSet.new()
          end
        %Resort{id: resort_id, modifiers: modifiers}
      end)

    %{
      cities: cities,
      resorts: resorts
    }
  end

  defp initial_players_state(game_config) do
    player_count = game_config.player_count
    Enum.map(1..player_count, fn index ->
      player_id = "player_#{index}"
      %Player.State{
        id: player_id,
        balance: Data.player_initial_balance(),
        position: Data.player_initial_position()
      }
    end)
  end

  def actions_before_move(player, game_state) do
    %{position: position} = player
    %{"type" => venue_type} = Data.venue_info() |> Enum.at(position)
    actions = case venue_type do
      :airport ->
        options = GameState.viable_flight_destinations(game_state, player.id)
        has_options? = options.cities != [] || options.resorts != []

        if player.balance >= Data.airport_cost() && has_options?,
          do: [%{action: {:pick_flight_destination, options}, need_inquire_player?: false}],
          else: [%{action: :roll_dices, need_inquire_player?: true}]

      :jail ->
        if get_in(game_state, [:jail, :players, player.id, :turn_count]) == Data.max_turn_in_jail() do
          [
            %{action: {:out_of_jail, player.id}, need_inquire_player?: true},
            %{action: :roll_dices, need_inquire_player?: true}
          ]
        else
          options = [:roll_dices]
          options =
            if player.balance >= Data.jail_cost(),
              do: options ++ [{:pay, Data.jail_cost()}],
              else: options
          options =
            if Player.has_item?(player, :free_from_jail),
            do: options ++ [:use_free_card],
            else: options
          [%{action: {:pick_jail_option, options}, need_inquire_player?: false}]
        end

      _ -> [%{action: :roll_dices, need_inquire_player?: true}]
    end

    ensure_has_player_id(actions, player.id)
  end

  # Find out what the player need to do after land on this tile
  # {:build, venue, options}
  def actions_after_move(player, game_state) do
    %{position: position} = player
    %{"id" => venue_id, "type" => venue_type} = Data.venue_info() |> Enum.at(position)
    actions = get_actions_after_move(venue_type, venue_id, player, game_state)
    ensure_has_player_id(actions, player.id)
  end

  defp get_actions_after_move(:city, venue_id, player, game_state) do
    %{venues: %{cities: cities}} = game_state
    %{id: player_id} = player
    city = Enum.find(cities, & &1.id == venue_id)
    build_action =
      case Player.affordable_upgrades(player, city) do
        [] -> nil
        upgrades -> %{action: {:build, city, upgrades}, need_inquire_player?: false}
      end

    case city do
      %{owner: nil} -> if build_action, do: [build_action], else: []
      %{owner: ^player_id} -> if city.level < 5 && build_action, do: [build_action], else: []
      %{owner: other_player} ->
        owner = GameState.get_player(game_state, other_player)
        {use_item_action, player_rent_multiplier} = generate_use_item_action(player)
        rent_price =
          if Venue.out_of_electricity?(city, owner),
            do: 0,
            else: Venue.rent_price(city, game_state) * player_rent_multiplier

        actions = generate_pay_action(%{
          payer: player,
          recipient: owner,
          amount: rent_price,
          game_state: game_state,
          pay_reason: :rent
        })
        if use_item_action, do: [use_item_action | actions], else: actions
    end
  end

  defp get_actions_after_move(:resort, venue_id, player, game_state) do
    %{venues: %{resorts: resorts}} = game_state
    %{id: player_id} = player
    resort = Enum.find(resorts, & &1.id == venue_id)
    case resort do
      %{owner: nil} ->
        upgrades = Player.affordable_upgrades(player, resort)
        if upgrades != [],
          do: [%{action: {:build, resort, upgrades}, need_inquire_player?: false}],
          else: []

      %{owner: ^player_id} -> []
      %{owner: other_player} ->
        owner = GameState.get_player(game_state, other_player)
        rent_price =
          if Venue.out_of_electricity?(resort, owner),
          do: 0,
          else: Venue.rent_price(resort, game_state)
        generate_pay_action(%{
          payer: player,
          recipient: owner,
          amount: rent_price,
          game_state: game_state,
          pay_reason: :rent
        })
    end
  end

  defp get_actions_after_move(:jail, _venue_id, player, _game_state),
    do: [%{action: {:go_to_jail, player.id}, need_inquire_player?: true}]

  defp get_actions_after_move(:world_championship, _venue_id, player, game_state) do
    with(
      true <- player.balance >= Data.world_championship_cost(),
      %{cities: own_cities, resorts: own_resorts} = options
        when own_cities != []
        when own_resorts != []
        <- GameState.player_own_venues(game_state, player.id)
    ) do
      [%{action: {:hold_world_championship, options}, need_inquire_player?: false}]
    else
      _ -> []
    end
  end

  defp get_actions_after_move(:tax_agency, _venue_id, player, game_state) do
    %{cities: cities, resorts: resorts} = GameState.player_own_venues(game_state, player.id)
    total_worth = Enum.map(cities ++ resorts, &Venue.worth/1) |> Enum.sum()
    generate_pay_action(%{
      payer: player,
      recipient: :system,
      amount: total_worth * Data.tax_rate(),
      game_state: game_state,
      pay_reason: :tax
    })
  end

  defp get_actions_after_move(:airport, _venue_id, _player, _game_state),
    do: [%{action: :go_to_airport, need_inquire_player?: true}]

  defp get_actions_after_move(:start, _venue_id, _player, _game_state),
    do: []

  defp get_actions_after_move(:chance, _venue_id, _player, _game_state) do
    chance = GameSystem.random_chance()
    [%{action: {:chance, chance}, need_inquire_player?: true}]
  end

  def generate_pay_action(params) do
    %{
      payer: payer,
      recipient: recipient,
      amount: amount,
      game_state: game_state,
      pay_reason: pay_reason
    } = params

    if payer.balance >= amount do
      [%{action: {:pay, recipient, amount, pay_reason}, need_inquire_player?: true}]
    else
      sell_options = GameState.player_own_venues(game_state, payer.id)
      total_venue_worth = Enum.map(
        sell_options.cities ++ sell_options.resorts,
        &Venue.worth/1
      ) |> Enum.sum()
      total_player_worth = total_venue_worth + payer.balance

      if total_player_worth > amount do
        missing_amount = amount - payer.balance
        [
          %{action: {:sell, missing_amount, sell_options}, need_inquire_player?: false},
          %{action: {:pay, recipient, amount, pay_reason}, need_inquire_player?: true}
        ]
      else
        [
          %{action: {:sell, payer.id, sell_options.cities ++ sell_options.resorts}, need_inquire_player?: true},
          %{action: {:pay, recipient, total_player_worth, pay_reason}, need_inquire_player?: true},
          %{action: {:bankrupt, payer}, need_inquire_player?: true}
        ]
      end
    end
  end

  # When paying rent, user can use item to modify the amount they have to pay
  defp generate_use_item_action(player) do
    cond do
      Player.has_item?(player, :double_rent) ->
        {
          %{action: {:use_item, :double_rent}, need_inquire_player?: true},
          Data.double_rent_multiplier()
        }

      Player.has_item?(player, :halve_rent) ->
        {
          %{action: {:use_item, :halve_rent}, need_inquire_player?: true},
          Data.halve_rent_multiplier()
        }

      true -> {nil, 1}
    end
  end

  def ensure_has_player_id(actions, player_id) do
    Enum.map(actions, fn action ->
      case action do
        %{player_id: _} -> action
        _ -> Map.put(action, :player_id, player_id)
      end
    end)
  end
end
