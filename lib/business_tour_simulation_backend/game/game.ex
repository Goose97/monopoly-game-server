defmodule MonopolySimulation.Game do
  alias MonopolySimulation.{Player, Moderator, StatisticCollector, Strategy}
  use GenServer

  def start_link(), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_), do: {:ok, %{}}

  def handle_cast({:start, game_config}, state) do
    id = game_config.id
    {moderator, players, statistic_collector} = start_actors(game_config)
    save_game_config(id, game_config)
    save_game_actors(id, moderator, players, statistic_collector)

    game_record = %{
      config: game_config,
      status: :running,
      statistic_collector: statistic_collector
    }
    game_record =
      if game_config.run_mode == :auto do
        Map.merge(game_record, %{
          collected_sample: 0,
          pending_sample: 0
        })
      else
        game_record
      end

    game_record = do_start(game_record)
    {:noreply, Map.put(state, id, game_record)}
  end

  def handle_call({:report, game_sample, game_id}, from, state) do
    game_record = Map.get(state, game_id)
    %{config: game_config, statistic_collector: statistic_collector} = game_record

    cond do
      game_record.status == :running && game_config.run_mode == :auto ->
        StatisticCollector.collect(game_sample, statistic_collector)
        game_record = Map.update!(game_record, :collected_sample, & &1 + 1)
        game_record = Map.update!(game_record, :pending_sample, & &1 - 1)

        game_record =
          cond do
            game_record.collected_sample + game_record.pending_sample < game_config.sample_amount ->
              game_id = game_config.id
              [{^game_id, _, players, _}] = :ets.lookup(:actors_by_game, game_id)
              GenServer.cast(elem(from, 0), {:start_game, players})
              Map.update!(game_record, :pending_sample, & &1 + 1)

            game_record.pending_sample == 0 ->
              send(self(), {:game_finished, game_id})
              %{game_record | status: :finish}

            # Keep running until all pending sample all finish
            true -> game_record
          end

        {:reply, :ok, Map.put(state, game_id, game_record)}

      true -> {:reply, :ok, state}
    end
  end

  def handle_info({:game_finished, game_id}, state) do
    game_record = Map.get(state, game_id)
    if game_record do
      StatisticCollector.show(game_record.statistic_collector)
      |> IO.inspect()
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, downed_actor, _}, state) do
    case :ets.lookup(:game_actors, downed_actor) do
      [{_, :player, player_id, game_id}] ->
        with(
          %{config: game_config} <- Map.get(state, game_id),
          player_config when player_config != nil <- Enum.find(game_config.player_config, & &1.id == player_id),
          [{_, _, players, _}] <- :ets.lookup(:actors_by_game, game_id)
        ) do
          respawn_player = spawn_player(player_config, game_config)
          replaced_players = (players -- [downed_actor]) ++ [respawn_player]
          :ets.update_element(:actors_by_game, game_id, [{3, replaced_players}])
        end

      [{_, :moderator, game_id}] ->
        with(
          %{config: game_config} <- Map.get(state, game_id),
          [{_, moderators, players, _}] <- :ets.lookup(:actors_by_game, game_id)
        ) do
          respawned_moderator = spawn_moderator(game_config)
          replaced_moderators =
            if is_list(moderators) do
              (moderators -- [downed_actor]) ++ [respawned_moderator]
            else
              respawned_moderator
            end

          :ets.update_element(:actors_by_game, game_id, [{2, replaced_moderators}])

          GenServer.cast(respawned_moderator, {:start_game, players})
        end
    end

    :ets.delete(:game_actors, downed_actor)

    {:noreply, state}
  end

  # Create game config
  def config(game_id \\ UUID.uuid4()) do
    player_config = [
      %Player.Config{
        id: "player_1",
        strategy_config: %Strategy.Config{
          build: :most_expensive,
          repurchase: :always,
          sell: :least_venue_possible,
          hold_world_championship: :lowest_rent_price,
          pick_flight_destination: :random,
          pick_jail_option: :always_pay_when_possible,
          pick_chance: [
            add_shield: :cheapest,
            cut_electricity: :random,
            downgrade: :random,
            destroy: :random,
            force_sale: :random,
            gift: :random
          ]
        }
      },
      %Player.Config{
        id: "player_2",
        strategy_config: %Strategy.Config{
          build: :most_expensive,
          repurchase: :always,
          sell: :least_money_possible,
          hold_world_championship: :lowest_rent_price,
          pick_flight_destination: :random,
          pick_jail_option: :always_pay_when_possible,
          pick_chance: [
            add_shield: :random,
            cut_electricity: :random,
            downgrade: :random,
            destroy: :random,
            force_sale: :random,
            gift: :random
          ]
        }
      },
      %Player.Config{
        id: "player_3",
        strategy_config: %Strategy.Config{
          build: :most_expensive,
          repurchase: :always,
          sell: :least_money_possible,
          hold_world_championship: :never,
          pick_flight_destination: :random,
          pick_jail_option: :always_pay_when_possible,
          pick_chance: [
            add_shield: :random,
            cut_electricity: :random,
            downgrade: :random,
            destroy: :random,
            force_sale: :random,
            gift: :random
          ]
        }
      },
      %Player.Config{
        id: "player_4",
        strategy_config: %Strategy.Config{
          build: :most_expensive,
          repurchase: :always,
          sell: :least_money_possible,
          hold_world_championship: :highest_rent_price,
          pick_flight_destination: :random,
          pick_jail_option: :always_pay_when_possible,
          pick_chance: [
            add_shield: :most_expensive,
            cut_electricity: :lowest_rent_price,
            downgrade: :random,
            destroy: :random,
            force_sale: :random,
            gift: :random
          ]
        }
      }
    ]

    %__MODULE__.Config{
      id: game_id,
      player_count: 4,
      player_config: player_config,
      run_mode: :auto,
      sample_amount: 1000,
      parallel_run: System.schedulers()
    }
  end

  def get_game_state(game_id) do
    case :ets.lookup(:actors_by_game, game_id) do
      [{^game_id, moderator, _, _}] when is_pid(moderator) ->
        game_state = GenServer.call(moderator, :game_state)
        {:ok, game_state}

      [{^game_id, moderator, _, _}] when is_list(moderator) ->
        {:ok, "Can not inspect game running in auto mode"}

      _ -> {:error, "Game id does not exist"}
    end
  end

  def control_game_progress(_game_id, "start_game") do
    config = __MODULE__.config()
    GenServer.cast(__MODULE__, {:start, config})
  end

  def control_game_progress(game_id, action) do
    moderator_pid =
      case :ets.lookup(:actors_by_game, game_id) do
        [{^game_id, moderator, _, _}] -> moderator
        _ -> nil
      end

    if moderator_pid do
      case action do
        "next_turn" -> send(moderator_pid, :next_turn)
        "previous_turn" -> send(moderator_pid, :previous_turn)
        _ -> :ignore
      end
    end
  end

  def report(%StatisticCollector.GameSample{} = game_result, game_id) do
    GenServer.call(__MODULE__, {:report, game_result, game_id})
  end

  # Wake up game moderator, players and statistic collector pre define config
  defp start_actors(game_config) do
    moderator =
      case game_config do
        %{run_mode: :manual} -> spawn_moderator(game_config)
        %{run_mode: :auto, parallel_run: parallel_run} ->
          Enum.map(1..parallel_run, fn _ -> spawn_moderator(game_config) end)
      end

    players =
      Enum.map(game_config.player_config, fn config ->
        spawn_player(config, game_config)
      end)

    {:ok, statistic_collector} = GenServer.start(StatisticCollector.Server, nil)

    {moderator, players, statistic_collector}
  end

  defp spawn_moderator(game_config) do
    {:ok, moderator} = GenServer.start(Moderator, game_config)
    :ets.insert(:game_actors, {moderator, :moderator, game_config.id})
    Process.monitor(moderator)
    moderator
  end

  defp spawn_player(player_config, game_config) do
    {:ok, player} = GenServer.start(Player.Server, player_config)
    :ets.insert(:game_actors, {player, :player, player_config.id, game_config.id})
    Process.monitor(player)
    player
  end

  defp save_game_config(game_id, config),
    do: :ets.insert(:game_config, {game_id, config})

  # Store all related pid of the game to an ets table
  defp save_game_actors(game_id, moderator, players, statistic_collector),
    do: :ets.insert(:actors_by_game, {game_id, moderator, players, statistic_collector})

  # Tell moderate to start the game
  defp do_start(game_record) do
    %{id: game_id, run_mode: run_mode} = game_record.config
    [{^game_id, moderator, players, _}] = :ets.lookup(:actors_by_game, game_id)
    start_moderator = fn pid -> GenServer.cast(pid, {:start_game, players}) end

    pending_count = case moderator do
      moderators when is_list(moderators) ->
        Enum.each(moderators, start_moderator)
        length(moderators)

      moderator when is_pid(moderator) ->
        start_moderator.(moderator)
        1
    end

    if run_mode == :auto,
      do: Map.update!(game_record, :pending_sample, & &1 + pending_count),
      else: game_record
  end
end
