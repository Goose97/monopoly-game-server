defmodule MonopolySimulation.Moderator.PlayerDecision do
  alias MonopolySimulation.{Player, GameState, GameSystem, Venue, Data}
  alias MonopolySimulation.Venue.{City, Resort}
  alias MonopolySimulation.Moderator

  def execute(decision, player, %GameState{} = game_state) do
    updated_game_state = do_execute(decision, player, game_state)
    extra_actions = actions_derived_from_decision(decision, player.id, updated_game_state)
    {updated_game_state, Moderator.Planner.ensure_has_player_id(extra_actions, player.id)}
  end

  defp do_execute(:roll_dices, player, %GameState{} = game_state) do
    dices = if Data.script, do: Enum.at(Data.script, game_state.turn_count)[:dices], else: GameSystem.roll_dices()
    player =
      Player.move(player, {:step, Enum.sum(dices)})
      |> Player.save_last_dices(dices)

    player =
      if player.consecutive_pairs == Data.max_consecutive_pairs() do
        jail_position = Data.venue_info() |> Enum.find_index(& &1["id"] == "jail")
        Player.move(player, {:straight_to, jail_position})
      else
        player
      end

    game_state
    |> GameState.update_player(player)
    |> GameState.update_dices(dices)
  end

  # Carry out player decision
  # Return an updated game state
  defp do_execute({:build, venue, option}, player, %GameState{} = game_state) do
    # Update the venue owner, level and modifier (monopolies)
    updated_venue = case venue do
      %City{} = city ->
        %{city | owner: player.id, level: option.level, rent_price: option.rent_price}

      %Resort{} = resort ->
        %{resort | owner: player.id, rent_price: option.rent_price}
    end

    # Update the player balance
    updated_player = Player.spend(player, option.cost)

    game_state
    |> GameState.update_venue(updated_venue)
    |> GameState.update_player(updated_player)
  end

  defp do_execute({:pay, :system, amount, _reason}, player, %GameState{} = game_state) do
    updated_player = Player.spend(player, amount)
    GameState.update_player(game_state, updated_player)
  end

  defp do_execute({:pay, recipient, amount, _reason}, player, %GameState{} = game_state) do
    recipient = GameState.get_player(game_state, recipient.id) |> Player.earn(amount)
    payer = GameState.get_player(game_state, player.id) |> Player.spend(amount)

    game_state
    |> GameState.update_player(recipient)
    |> GameState.update_player(payer)
  end

  defp do_execute({:sell, venue_owner, venues}, _player, %GameState{} = game_state) do
    worth = Enum.map(venues, &Venue.worth/1) |> Enum.sum()
    updated_player =
      game_state
      |> GameState.get_player(venue_owner)
      |> Player.earn(worth)
    game_state = GameState.update_player(game_state, updated_player)
    Enum.reduce(venues, game_state, fn venue, acc ->
      updated_venue = Venue.destroy(venue)
      GameState.update_venue(acc, updated_venue)
    end)
  end

  defp do_execute({:repurchase, city}, player, %GameState{} = game_state) do
    owner = GameState.get_player(game_state, city.owner)
    repurchase_price = Venue.repurchase_price(city)

    owner = Player.earn(owner, repurchase_price)
    player = Player.spend(player, repurchase_price)
    city = %{city | owner: player.id}

    game_state
    |> GameState.update_player(owner)
    |> GameState.update_player(player)
    |> GameState.update_venue(city)
  end

  defp do_execute({:go_to_jail, player_id}, _player, %GameState{} = game_state) do
    player = GameState.get_player(game_state, player_id)
    game_state = GameState.update_player(
      game_state,
      %{player | can_take_another_turn: false, consecutive_pairs: 0}
    )

    if GameState.player_in_jail?(game_state, player_id),
      do: game_state,
      else: GameState.put_player_to_jail(game_state, player_id)
  end

  defp do_execute({:out_of_jail, player_id}, _player, %GameState{} = game_state) do
    GameState.get_player_out_of_jail(game_state, player_id)
  end

  defp do_execute({:pick_jail_option, option}, player, %GameState{} = game_state) do
    case option do
      :roll_dices ->
        dices = GameSystem.roll_dices()
        if GameSystem.pair_dices?(dices) do
          updated_player = Player.move(player, {:step, Enum.sum(dices)}) |> Player.save_last_dices(dices)
          game_state
          |> GameState.update_player(updated_player)
          |> GameState.get_player_out_of_jail(updated_player.id)
        else
          GameState.increment_jail_turn_counter(game_state, player.id)
        end

      {:pay, amount} ->
        updated_player = Player.spend(player, amount)
        game_state
        |> GameState.update_player(updated_player)
        |> GameState.get_player_out_of_jail(updated_player.id)

      :use_free_card ->
        updated_player = Player.use_item(player, :free_from_jail)
        game_state
        |> GameState.update_player(updated_player)
        |> GameState.get_player_out_of_jail(updated_player.id)
    end
  end

  defp do_execute({:hold_world_championship, venue}, player, %GameState{} = game_state) do
    update_former_host = fn venue_id ->
      type = Data.venue_info() |> Enum.find(& &1["id"] == venue_id) |> Map.get("type")
      former_host = GameState.get_venue(game_state, venue_id, type)
      former_host = Venue.close_world_championship(former_host)
      GameState.update_venue(game_state, former_host)
    end

    game_state =
      if game_state.world_championship.host not in [nil, venue.id],
        do: update_former_host.(game_state.world_championship.host),
        else: game_state

    updated_venue = Venue.hold_world_championship(venue, game_state.world_championship.counter)
    updated_player = Player.spend(player, Data.world_championship_cost())

    game_state
    |> GameState.change_world_championship_host(updated_venue)
    |> GameState.increment_world_championship_count()
    |> GameState.update_venue(updated_venue)
    |> GameState.update_player(updated_player)
  end

  defp do_execute(:go_to_airport, player, %GameState{} = game_state) do
    player = GameState.get_player(game_state, player.id)
    updated_player = %{player | can_take_another_turn: false}
    GameState.update_player(game_state, updated_player)
  end

  defp do_execute({:pick_flight_destination, venue_id}, player, %GameState{} = game_state) do
    venue_position = Data.venue_info() |> Enum.find_index(& &1["id"] == venue_id)
    updated_player =
      player
      |> Player.move({:straight_to, venue_position})
      |> Player.spend(Data.airport_cost())
    updated_player = %{updated_player | can_take_another_turn: true, consecutive_pairs: 0}

    GameState.update_player(game_state, updated_player)
  end

  defp do_execute({:chance, chance}, player, %GameState{} = game_state),
    do: __MODULE__.Chance.execute(chance, player, game_state)

  defp do_execute({:add_modifier, modifier, venue}, _player, %GameState{} = game_state) do
    modifier =
      case modifier do
        :electricity_outage ->
          owner = GameState.get_player(game_state, venue.owner)
          {:electricity_outage, owner.completed_rounds}

        _ -> modifier
      end
    updated_venue = Venue.add_modifier(venue, modifier)
    GameState.update_venue(game_state, updated_venue)
  end

  defp do_execute({:use_item, item}, player, %GameState{} = game_state) do
    updated_player = Player.use_item(player, item)
    GameState.update_player(game_state, updated_player)
  end

  defp do_execute({:downgrade, venue}, _player, %GameState{} = game_state) do
    updated_venue = Venue.downgrade(venue)
    GameState.update_venue(game_state, updated_venue)
  end

  defp do_execute({:destroy, venue}, _player, %GameState{} = game_state) do
    updated_venue = Venue.destroy(venue)
    GameState.update_venue(game_state, updated_venue)
  end

  defp do_execute({:gift, venue, recipient}, _player, %GameState{} = game_state) do
    updated_venue = Venue.gift(venue, recipient.id)
    GameState.update_venue(game_state, updated_venue)
  end

  defp do_execute({:bankrupt, player, current_turn}, _player, %GameState{} = game_state) do
    player = GameState.get_player(game_state, player.id)
    updated_player = Player.bankrupt(player, current_turn)
    GameState.update_player(game_state, updated_player)
  end

  defp do_execute(:noop, _player, game_state), do: game_state

  defp actions_derived_from_decision({:pay, :system, _, _}, _player_id, _game_state), do: []
  defp actions_derived_from_decision({:pay, _, _, :chance}, _player_id, _game_state), do: []
  defp actions_derived_from_decision({:pay, _, _, _}, player_id, game_state) do
    player = GameState.get_player(game_state, player_id)
    %{"id" => venue_id, "type" => venue_type} = Enum.at(Data.venue_info(), player.position)
    venue = GameState.get_venue(game_state, venue_id, venue_type)
    with(
      %City{} <- venue,
      true <- Venue.repurchasable?(venue),
      true <- Player.can_afford?(player, venue)
    ) do
      [%{action: {:repurchase, venue}, need_inquire_player?: false}]
    else
      _ -> []
    end
  end

  # Theses actions are result of previous decision
  # Eg: repurchase a city opens up an action to upgrade it
  defp actions_derived_from_decision({:repurchase, _city}, player_id, game_state) do
    player = GameState.get_player(game_state, player_id)
    Moderator.Planner.actions_after_move(player, game_state)
  end

  defp actions_derived_from_decision({:pick_jail_option, decision}, _player_id, _game_state) do
    case decision do
      :roll_dices -> []
      {:pay, _amount} -> [%{action: :roll_dices, need_inquire_player?: true}]
      :use_free_card -> [%{action: :roll_dices, need_inquire_player?: true}]
    end
  end

  defp actions_derived_from_decision({:chance, chance}, player_id, game_state),
    do: __MODULE__.Chance.actions_derived_from_chance(chance, player_id, game_state)

  defp actions_derived_from_decision(_decision, _player_id, _game_state), do: []

  defdelegate validate(scenario, decision), to: __MODULE__.Validator
  defdelegate save_log(decision, player, game_state, game_logs), to: __MODULE__.Log
end
