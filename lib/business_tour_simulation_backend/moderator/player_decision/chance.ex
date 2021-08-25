defmodule MonopolySimulation.Moderator.PlayerDecision.Chance do
  alias MonopolySimulation.{Moderator, Player, GameState, Data, Venue}

  @go_to_special_venue_chances [:start_over, :lost_island, :tourist_trip, :invitation, :luxury_tax]
  @add_venue_modifier_chances [:shield, :electricity_outage]
  @add_player_item_chances [:a_bad_sign, :discount_coupon, :road_home]
  @target_opponent_venues_chances [:sabotage, :earthquake, :forced_sale]

  # Go directly to the city holding the World Championships
  def execute(:to_world_championship, player, game_state) do
    host_city = get_in(game_state, [:world_championship, :host])
    if host_city do
      venue_position = Enum.find_index(Data.venue_info(), & &1["id"] == host_city)
      updated_player = Player.move(player, {:straight_to, venue_position})
      GameState.update_player(game_state, updated_player)
    else
      game_state
    end
  end

  # Go straight to a special venue
  def execute(chance, player, game_state)
    when chance in @go_to_special_venue_chances
  do
    venue_id = case chance do
      :luxury_tax -> "tax_agency"
      :invitation -> "airport"
      :start_over -> "start"
      :tourist_trip -> "world_championship"
      :lost_island -> "jail"
    end
    venue_position = Enum.find_index(Data.venue_info(), & &1["id"] == venue_id)
    updated_player = Player.move(player, {:straight_to, venue_position})
    GameState.update_player(game_state, updated_player)
  end

  # Add some modifier to venue like shield or electricity outage
  def execute(chance, _player, game_state)
    when chance in @add_venue_modifier_chances
  do
    game_state
  end

  def execute(chance, player, game_state)
    when chance in @add_player_item_chances
  do
    item =
      case chance do
        :a_bad_sign -> :double_rent
        :discount_coupon -> :halve_rent
        :road_home -> :free_from_jail
      end
    updated_player = Player.acquire_item(player, item)
    GameState.update_player(game_state, updated_player)
  end

  def execute(_chance, _player, game_state), do: game_state

  def actions_derived_from_chance(:to_world_championship, player_id, game_state) do
    player = GameState.get_player(game_state, player_id)
    # Check if the player has moved away from chance
    case Enum.at(Data.venue_info(), player.position) do
      %{"type" => :chance} -> []
      %{"type" => type} when type in [:city, :resort] ->
        Moderator.Planner.actions_after_move(player, game_state)
    end
  end

  def actions_derived_from_chance(chance, player_id, game_state)
    when chance in @go_to_special_venue_chances
  do
    player = GameState.get_player(game_state, player_id)
    Moderator.Planner.actions_after_move(player, game_state)
  end

  def actions_derived_from_chance(chance, player_id, game_state)
    when chance in @add_venue_modifier_chances
  do
    {action, options} = case chance do
      :shield -> {:add_shield, GameState.player_own_venues(game_state, player_id)}
      :electricity_outage -> {:cut_electricity, GameState.opponent_venues(game_state, player_id)}
    end

    if options.cities != [] || options.resorts != [],
      do: [%{action: {action, options}, required?: false}],
      else: []
  end

  def actions_derived_from_chance(:world_championship, player_id, game_state) do
    player = GameState.get_player(game_state, player_id)
    with(
      true <- player.balance >= Data.world_championship_cost(),
      %{cities: own_cities, resorts: own_resorts} = options
        when own_cities != []
        when own_resorts != []
        <- GameState.player_own_venues(game_state, player.id)
    ) do
      [%{action: {:hold_world_championship, options}, required?: false}]
    else
      _ -> []
    end
  end

  def actions_derived_from_chance(:fine, player_id, game_state) do
    player = GameState.get_player(game_state, player_id)
    Moderator.Planner.generate_pay_action(%{
      payer: player,
      recipient: :system,
      amount: Data.fine_amount(),
      game_state: game_state,
      pay_reason: :chance
    })
    |> Moderator.Planner.ensure_has_player_id(player_id)
  end

  def actions_derived_from_chance(chance, player_id, game_state)
    when chance in @target_opponent_venues_chances
  do
    options = for {type, venues} <- GameState.opponent_venues(game_state, player_id), into: %{} do
      {type, Enum.filter(venues, &Venue.targetable?/1)}
    end

    action =
      case chance do
        :sabotage -> :downgrade
        :earthquake -> :destroy
        :forced_sale -> :force_sale
      end
    if options.cities != [] || options.resorts != [],
      do: [%{action: {action, options}, required?: false}],
      else: []
  end

  def actions_derived_from_chance(:royal_gift, player_id, game_state) do
    options = GameState.player_own_venues(game_state, player_id)
    %{cities: own_cities, resorts: own_resorts} = options
    opponents = Enum.filter(game_state.players, & &1.id != player_id && &1.bankrupt_turn == nil)
    if own_cities != [] || own_resorts != [],
      do: [%{action: {:gift, options, opponents}, required?: false}],
      else: []
  end

  def actions_derived_from_chance(:happy_birthday, player_id, game_state) do
    recipient = GameState.get_player(game_state, player_id)
    game_state.players
    |> Enum.filter(& &1.id != player_id && &1.bankrupt_turn == nil)
    |> Enum.flat_map(fn player ->
      Moderator.Planner.generate_pay_action(%{
        payer: player,
        recipient: recipient,
        amount: Data.birthday_present(),
        game_state: game_state,
        pay_reason: :chance
      })
      |> Moderator.Planner.ensure_has_player_id(player.id)
    end)
  end

  def actions_derived_from_chance(_chance, _player_id, _game_state), do: []
end
