defmodule MonopolySimulation.Moderator do
  use GenServer
  alias __MODULE__.{State, Planner, PlayerDecision}
  alias MonopolySimulation.{GameSystem, Broadcaster, GameState, Data, Venue, Game}
  alias MonopolySimulation.StatisticCollector.GameSample

  @player_decision_timeout 10000

  @impl true
  def init(game_config) do
    {:ok, %State{game_config: game_config}}
  end

  @impl true
  def handle_cast({:start_game, players}, state) do
    initial_game_state = Planner.initial_game_state(state.game_config)
    state = Map.merge(state, %{
      game_state: initial_game_state,
      game_state_history: [initial_game_state],
      player_pids: players,
      current_turn: 0,
      game_finished?: false,
      game_logs: %{
        player_actions: [],
        player_balance_changes: []
      }
    })

    if state.game_config.run_mode != :auto do
      Broadcaster.broadcast(
        state.game_config.id,
        "game:init",
        %{game_state: initial_game_state, current_turn: state.current_turn, game_logs: state.game_logs}
      )
    end

    state = start_game(state)
    {:noreply, state}
  end

  @impl true
  def handle_call(:game_state, _from, state) do
    payload = %{
      game_state: GameState.evaluate_rent_price(state.game_state),
      current_turn: state.current_turn,
      game_logs: state.game_logs
    }
    {:reply, payload, state}
  end

  @impl true
  def handle_info(:next_turn, state) do
    next_turn = state.current_turn + 1
    execute_turn(next_turn, state)
  end

  @impl true
  def handle_info(:previous_turn, state) do
    previous_turn = state.current_turn - 1
    execute_turn(previous_turn, state)
  end

  defp start_game(state) do
    %{game_config: game_config} = state

    if game_config.run_mode == :auto do
      go_first_player =
        if Data.script,
          do: Enum.at(Data.script, 0)[:player],
          else: GameSystem.random_player(game_config.player_count) - 1
      send(self(), :next_turn)
      put_in(state, [:game_state, :next_player], go_first_player)
    else
      state
    end
  end

  defp execute_turn(turn, state) when turn < 0, do: {:noreply, state}
  # This turn is in the past
  defp execute_turn(turn, %{game_state_history: history} = state) when turn < length(history) do
    game_state = lookup_game_state_history(history, turn)

    if state.game_config.run_mode != :auto do
      Broadcaster.broadcast(
        state.game_config.id,
        "game:init",
        %{game_state: GameState.evaluate_rent_price(game_state), current_turn: turn, game_logs: state.game_logs}
      )
    end

    {:noreply, %{state | current_turn: turn, game_state: game_state}}
  end

  # Do nothing if the game is already finished
  defp execute_turn(_turn, %{game_finished?: true} = state), do: {:noreply, state}

  # This turn is in the future
  defp execute_turn(turn, state) do
    %{game_state: game_state, game_config: game_config, game_logs: game_logs} = state
    next_player =
      if game_state.next_player do
        game_state.next_player
      else
        # This is the first turn
        if Data.script,
          do: Enum.at(Data.script, 0)[:player],
          else: GameSystem.random_player(game_config.player_count) - 1
      end

    state = Map.merge(state, %{
      game_state: GameState.increment_turn_count(game_state) |> Map.put(:next_player, nil),
      current_turn: turn,
      game_logs: update_in(game_logs, [:player_actions], & &1 ++ [[]])
    })
    state = put_in(state, [:game_state, :next_player], nil)
    state = before_move(next_player, state)
    state = after_move(next_player, state)
    {:noreply, state}
  end

  defp before_move(player_index, state) do
    %{game_state: game_state} = state

    player = Enum.at(game_state.players, player_index)
    player = %{player | last_dices: nil, can_take_another_turn: false}
    game_state = GameState.update_player(game_state, player)

    actions = Planner.actions_before_move(player, game_state)
    # IO.inspect(actions, label: "What I will do before move")
    ask_player_decisions(actions, state)
  end

  defp after_move(player_index, state) do
    %{game_state: game_state, game_config: game_config} = state
    player = Enum.at(game_state.players, player_index)
    actions = Planner.actions_after_move(player, game_state)

    # IO.inspect(actions, label: "What I will do after move")
    updated_state = ask_player_decisions(actions, state)
    updated_state =
      case GameState.finished?(updated_state.game_state) do
        {win_reason, ranking} ->
          player_ranking =
            Enum.with_index(ranking)
            |> Enum.map(fn {player_id, index} ->
              %{game_state: game_state} = updated_state
              rank = index + 1
              point = length(ranking) - index
              player = GameState.get_player(game_state, player_id)
              is_bankrupted = player.bankrupt_turn != nil

              total_worth =
                if is_bankrupted do
                  0
                else
                  %{cities: cities, resorts: resorts} = GameState.player_own_venues(game_state, player_id)
                  total_worth = Enum.map(cities ++ resorts, &Venue.worth/1) |> Enum.sum()
                  total_worth + player.balance
                end

              %{
                id: player_id,
                rank: rank,
                point: point,
                total_turn: if(is_bankrupted, do: player.bankrupt_turn, else: updated_state.current_turn),
                is_bankrupted: is_bankrupted,
                total_worth: total_worth
              }
            end)

          game_sample = %GameSample{
            total_turn: updated_state.current_turn,
            ranking: player_ranking,
            win_reason: win_reason
          }
          Game.report(game_sample, game_config.id)

          %{updated_state | game_finished?: true}

        false ->
          next_player = get_next_player(player_index, updated_state)
          put_in(updated_state, [:game_state, :next_player], next_player)
      end

    updated_state = Map.update!(
      updated_state,
      :game_state_history,
      & [updated_state.game_state | &1]
    )

    updated_state =
      if game_config.run_mode == :auto,
        do: updated_state,
        else: save_balance_changes(updated_state)

    if game_config.run_mode != :auto do
      Broadcaster.broadcast(game_config.id, "game:logs", %{value: updated_state.game_logs})
      Broadcaster.broadcast(game_config.id, "game:current_turn", %{value: updated_state.current_turn})
      Broadcaster.broadcast(game_config.id, "game:state", %{value: GameState.evaluate_rent_price(updated_state.game_state)})
    end

    # If we run in auto mode, just advance to the next turn
    # Else we need for the signal to advance
    if !updated_state.game_finished? && game_config.run_mode == :auto,
      do: send(self(), :next_turn)

    updated_state
  end

  defp get_next_player(current_player_index, state) do
    %{game_state: game_state, game_config: game_config} = state
    current_player = Enum.at(game_state.players, current_player_index)

    next_player = fn current ->
      number = Enum.find(1..4, fn number ->
        next_player_index = rem(current + number, game_config.player_count)
        next_player = Enum.at(game_state.players, next_player_index)
        !next_player.bankrupt_turn
      end)

      rem(current + number, game_config.player_count)
    end

    real_next_player =
      if current_player.can_take_another_turn && !current_player.bankrupt_turn,
        do: current_player_index,
        else: next_player.(current_player_index)

    if Data.script,
      do: Enum.at(Data.script, state.game_state.turn_count + 1)[:player],
      else: real_next_player
  end

  defp save_balance_changes(state) do
    %{current_turn: current_turn, game_state_history: game_state_history} = state
    current_turn_state = lookup_game_state_history(game_state_history, current_turn).players
    previous_turn_state = lookup_game_state_history(game_state_history, current_turn - 1).players
    balance_changes =
      Enum.zip(current_turn_state, previous_turn_state)
      |> Enum.map(fn
        {%{bankrupt_turn: turn}, _previous_player} when turn != nil -> nil
        {%{balance: current_balance}, %{balance: previous_balance}} ->
          if previous_balance == nil do
            IO.inspect(previous_turn_state, label: "0112")
            IO.inspect(current_turn_state, label: "0112")
            IO.inspect(length(game_state_history), label: "1006")
            IO.inspect(current_turn, label: "1006")
          end

          current_balance - previous_balance
      end)

    update_in(state, [:game_logs, :player_balance_changes], & &1 ++ [balance_changes])
  end

  defp ask_player_decisions([], state), do: state
  defp ask_player_decisions([scenario | tail], state) do
    %{
      player_pids: player_pids,
      game_state: game_state,
      game_logs: game_logs
    } = state
    %{players: players} = game_state

    player_index = Enum.find_index(game_state.players, & &1.id == scenario.player_id)
    player = Enum.at(players, player_index)
    player_pid = Enum.at(player_pids, player_index)

    decision =
      case scenario do
        %{need_inquire_player?: false} ->
          {:ok, decision} = GenServer.call(player_pid, {:player_decision, scenario, game_state}, @player_decision_timeout)
          case PlayerDecision.validate(scenario.action, decision) do
            {:ok, _} -> elaborate_decision(decision, scenario.action)
            {:error, reason} -> throw reason
          end

        %{need_inquire_player?: true, action: action} ->
          case action do
            {:bankrupt, player} -> {:bankrupt, player, state.current_turn}
            action -> action
          end
      end

    {updated_game_state, extra_actions} = PlayerDecision.execute(decision, player, game_state)
    updated_game_logs = PlayerDecision.save_log(
      decision,
      GameState.get_player(updated_game_state, player.id),
      updated_game_state,
      game_logs
    )

    ask_player_decisions(
      extra_actions ++ tail,
      %{state | game_state: updated_game_state, game_logs: updated_game_logs}
    )
  end

  defp elaborate_decision(decision, scenario) do
    case scenario do
      {:build, venue, options} ->
        if decision == -1,
          do: :noop,
          else: {:build, venue, Enum.at(options, decision)}

      {:repurchase, city} ->
        if decision == 1,
          do: {:repurchase, city},
          else: :noop

      {:hold_world_championship, options} ->
        if decision == -1 do
          :noop
        else
          host_venue =
            options.cities ++ options.resorts
            |> Enum.find(& &1.id == decision)
          {:hold_world_championship, host_venue}
        end

      {:pick_flight_destination, _options} ->
        if decision == -1,
          do: :roll_dices,
          else: {:pick_flight_destination, decision}

      {:pick_jail_option, options} ->
        {:pick_jail_option, Enum.at(options, decision)}

      {:sell, _instruction, options} ->
        venues_to_sell = Enum.map(decision, fn venue_id ->
          Enum.find(options.cities ++ options.resorts, & &1.id == venue_id)
        end)
        {:sell, List.first(venues_to_sell).owner, venues_to_sell}

      {action, options} when action in [:downgrade, :destroy] ->
        if decision == -1 do
          :noop
        else
          target_venue = Enum.find(options.cities ++ options.resorts, & &1.id == decision)
          {action, target_venue}
        end

      {:force_sale, options} ->
        if decision == -1 do
          :noop
        else
          venue_to_sell = Enum.find(options.cities ++ options.resorts, & &1.id == decision)
          {:sell, venue_to_sell.owner, [venue_to_sell]}
        end

      {action, options} when action in [:add_shield, :cut_electricity] ->
        if decision == -1 do
          :noop
        else
          target_venue =
            options.cities ++ options.resorts
            |> Enum.find(& &1.id == decision)
          modifier =
            case action do
              :add_shield -> :shield
              :cut_electricity -> :electricity_outage
            end
          {:add_modifier, modifier, target_venue}
        end

      {:gift, options, opponents} ->
        {venue_id, opponent_id} = decision
        venue_to_gift = Enum.find(options.cities ++ options.resorts, & &1.id == venue_id)
        opponent = Enum.find(opponents, & &1.id == opponent_id)
        {:gift, venue_to_gift, opponent}

      _ -> :noop
    end
  end

  defp lookup_game_state_history(history, turn) when turn >= 0,
    do: Enum.at(history, length(history) - turn - 1)
end
