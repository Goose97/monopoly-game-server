defmodule MonopolySimulation.Moderator.PlayerDecision.Log do
  alias MonopolySimulation.{GameState, Venue}

  def save_log(decision, player, %GameState{} = _game_state, game_logs) do
    %{player_actions: player_actions} = game_logs
    new_log = build_logs(decision, player)
    updated_player_actions =
      if new_log,
        do: List.update_at(player_actions, -1, & &1 ++ [new_log]),
        else: player_actions

    %{game_logs | player_actions: updated_player_actions}
  end

  defp build_logs(:roll_dices, player) do
    dices = Enum.sum(player.last_dices)
    "<player_id:#{player.id}> rolls #{dices}"
  end

  defp build_logs({:build, venue, option}, player) do
    case Venue.type(venue) do
      :city -> "<player_id:#{player.id}> builds level #{option.level} <venue_id:#{venue.id}>"
      :resort -> "<player_id:#{player.id}> builds <venue_id:#{venue.id}>"
    end
  end

  defp build_logs({:pay, :system, amount, _reason}, player),
    do: "<player_id:#{player.id}> pays #{amount}"

  defp build_logs({:pay, recipient, amount, _reason}, player),
    do: "<player_id:#{player.id}> pays #{amount} for <player_id:#{recipient.id}>"

  defp build_logs({:sell, venue_owner, venues}, _player) do
    venues_to_sell = Enum.map(venues, & "<venue_id:#{&1.id}>") |> Enum.join(", ")
    "<player_id:#{venue_owner}> sells #{venues_to_sell}"
  end

  defp build_logs({:repurchase, city}, player),
    do: "<player_id:#{player.id}> repurchases <venue_id:#{city.id}>"

  defp build_logs({:go_to_jail, player_id}, _player),
    do: "<player_id:#{player_id}> goes to jail"

  defp build_logs({:pick_jail_option, option}, player) do
    action = case option do
      :roll_dices -> "roll dices"
      {:pay, amount} -> "pay #{amount}"
      :use_free_card -> "use free from jail card"
    end
    "<player_id:#{player.id}> is in jail and choose to #{action}"
  end

  defp build_logs({:hold_world_championship, venue}, player),
    do: "<player_id:#{player.id}> holds World championship at <venue_id:#{venue.id}>"

  defp build_logs({:pick_flight_destination, venue_id}, player),
    do: "<player_id:#{player.id}> flies to <venue_id:#{venue_id}>"

  defp build_logs({:chance, chance}, player),
    do: "<player_id:#{player.id}> get <chance:#{chance}> chance"

  defp build_logs({:add_modifier, modifier, venue}, player) do
    case modifier do
      :shield -> "<player_id:#{player.id}> shields <venue_id:#{venue.id}>"
      :electricity_outage -> "<player_id:#{player.id}> cuts electricity of <venue_id:#{venue.id}>"
    end
  end

  defp build_logs({:downgrade, venue}, player),
    do: "<player_id:#{player.id}> downgrades <venue_id:#{venue.id}>"

  defp build_logs({:destroy, venue}, player),
    do: "<player_id:#{player.id}> destroys <venue_id:#{venue.id}>"

  defp build_logs({:gift, venue, recipient}, player),
    do: "<player_id:#{player.id}> gifts <venue_id:#{venue.id}> to <player_id:#{recipient.id}>"

  defp build_logs({:bankrupt, player, _turn}, _player),
    do: "<player_id:#{player.id}> bankrupts"

  defp build_logs(_decision, _player), do: nil
end
