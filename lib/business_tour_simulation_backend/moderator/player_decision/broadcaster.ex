defmodule MonopolySimulation.Moderator.PlayerDecision.Broadcaster do
  alias MonopolySimulation.{GameState, Broadcaster, Venue}
  alias MonopolySimulation.Venue.{City, Resort}

  @go_to_special_venue_chances [:start_over, :lost_island, :tourist_trip, :invitation, :luxury_tax]
  @add_player_item_chances [:a_bad_sign, :discount_coupon, :road_home]

  def broadcast({:build, venue, _option}, player, %GameState{} = game_state, game_id) do
    {updated_venue, type} =
      case venue do
        %City{id: id} -> {GameState.get_venue(game_state, id, :city), :city}
        %Resort{id: id} -> {GameState.get_venue(game_state, id, :resort), :resort}
      end

    updated_player = GameState.get_player(game_state, player.id)

    Broadcaster.broadcast(game_id, "game:venue", %{
      action: :build,
      type: type,
      venue: Venue.evaluate_rent_price(updated_venue, game_state)
    })
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
  end

  def broadcast({:pay, :system, _amount, _reason}, player, %GameState{} = game_state, game_id) do
    updated_player = GameState.get_player(game_state, player.id)

    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
  end

  def broadcast({:pay, owner, _venue, _reason}, player, %GameState{} = game_state, game_id) do
    updated_owner = GameState.get_player(game_state, owner.id)
    updated_player = GameState.get_player(game_state, player.id)

    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_owner})
  end

  def broadcast({:sell, venue_owner, venues}, _player, %GameState{} = game_state, game_id) do
    updated_player = GameState.get_player(game_state, venue_owner)
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})

    Enum.each(venues, fn venue ->
      type = Venue.type(venue)
      updated_venue = GameState.get_venue(game_state, venue.id, type)
      Broadcaster.broadcast(game_id, "game:venue", %{
        action: :sell,
        type: type,
        venue: Venue.evaluate_rent_price(updated_venue, game_state)
      })
    end)
  end

  def broadcast({:repurchase, city}, player, %GameState{} = game_state, game_id) do
    former_owner = GameState.get_player(game_state, city.owner)
    current_owner = GameState.get_player(game_state, player.id)
    updated_city = GameState.get_venue(game_state, city.id, :city)

    Broadcaster.broadcast(game_id, "game:player", %{value: former_owner})
    Broadcaster.broadcast(game_id, "game:player", %{value: current_owner})
    Broadcaster.broadcast(game_id, "game:venue", %{
      action: :repurchase,
      type: :city,
      venue: Venue.evaluate_rent_price(updated_city, game_state)
    })
  end

  # We have to also update the venue which is the former host
  # Unfortunately, at this state, we lost the information about which city it is
  # So we just update all venues which have an owner
  def broadcast({:hold_world_championship, _venue}, player, %GameState{} = game_state, game_id) do
    updated_player = GameState.get_player(game_state, player.id)
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})

    Enum.each(game_state.venues.cities ++ game_state.venues.resorts, fn venue ->
      type = Venue.type(venue)
      Broadcaster.broadcast(game_id, "game:venue", %{
        action: :add_modifier,
        type: type,
        venue: Venue.evaluate_rent_price(venue, game_state)
      })
    end)
  end

  def broadcast(:roll_dices, player, %GameState{} = game_state, game_id) do
    updated_player = GameState.get_player(game_state, player.id)
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
    Broadcaster.broadcast(game_id, "game:dice", %{value: game_state.dices})
  end

  def broadcast({:pick_flight_destination, _venue_id}, player, %GameState{} = game_state, game_id) do
    updated_player = GameState.get_player(game_state, player.id)
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
  end

  def broadcast({:add_modifier, _modifier, venue}, _player, %GameState{} = game_state, game_id) do
    type = Venue.type(venue)
    updated_venue = GameState.get_venue(game_state, venue.id, type)
    Broadcaster.broadcast(game_id, "game:venue", %{
      action: :add_modifier,
      type: type,
      venue: Venue.evaluate_rent_price(updated_venue, game_state)
    })
  end

  def broadcast({:use_item, _item}, player, %GameState{} = game_state, game_id) do
    updated_player = GameState.get_player(game_state, player.id)
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
  end

  def broadcast({action, venue}, _player, %GameState{} = game_state, game_id)
    when action in [:downgrade, :destroy, :forced_sale, :cut_electricity]
  do
    type = Venue.type(venue)
    updated_venue = GameState.get_venue(game_state, venue.id, type)
    Broadcaster.broadcast(game_id, "game:venue", %{
      action: :targeted_chance,
      type: type,
      venue: Venue.evaluate_rent_price(updated_venue, game_state)
    })
  end

  def broadcast({:gift, venue, _recipient}, _player, %GameState{} = game_state, game_id) do
    type = Venue.type(venue)
    updated_venue = GameState.get_venue(game_state, venue.id, type)
    Broadcaster.broadcast(game_id, "game:venue", %{
      action: :gifted,
      type: type,
      venue: Venue.evaluate_rent_price(updated_venue, game_state)
    })
  end

  def broadcast({:chance, chance}, player, %GameState{} = game_state, game_id)
    when chance == :to_world_championship
    when chance in @go_to_special_venue_chances
    when chance in @add_player_item_chances
  do
    updated_player = GameState.get_player(game_state, player.id)
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
  end

  def broadcast({:chance, :happy_birthday}, _player, %GameState{} = game_state, game_id) do
    Enum.each(
      game_state.players,
      &Broadcaster.broadcast(game_id, "game:player", %{value: &1})
    )
  end

  def broadcast({:bankrupt, player, _turn}, _player, %GameState{} = game_state, game_id) do
    updated_player = GameState.get_player(game_state, player.id)
    Broadcaster.broadcast(game_id, "game:player", %{value: updated_player})
  end

  def broadcast(_, _player, %GameState{} = _game_state, _game_id), do: :noop
end
