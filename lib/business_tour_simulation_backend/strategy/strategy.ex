defmodule MonopolySimulation.Strategy do
  alias MonopolySimulation.{GameState, Player}
  alias MonopolySimulation.Venue.{City, Resort}
  alias __MODULE__.{Config, Build, Repurchase, Sell, HoldWorldChampionship, PickFlightDestination, PickJailOption, PickChance}

  @behaviour __MODULE__.Behaviour

  @venue_visit_frequency [
    %{"frequency" => 1.0, "id" => "start"},
    %{"frequency" => 1.029, "id" => "granada"},
    %{"frequency" => 1.061, "id" => "seville"},
    %{"frequency" => 1.082, "id" => "madrid"},
    %{"frequency" => 0.993, "id" => "bali"},
    %{"frequency" => 1.194, "id" => "hong_kong"},
    %{"frequency" => 1.238, "id" => "beijing"},
    %{"frequency" => 1.27, "id" => "shanghai"},
    %{"frequency" => 1.494, "id" => "jail"},
    %{"frequency" => 1.213, "id" => "venice"},
    %{"frequency" => 1.222, "id" => "milan"},
    %{"frequency" => 1.207, "id" => "rome"},
    %{"frequency" => 1.038, "id" => "chance1"},
    %{"frequency" => 1.19, "id" => "hamburg"},
    %{"frequency" => 1.117, "id" => "cyprus"},
    %{"frequency" => 1.213, "id" => "berlin"},
    %{"frequency" => 1.21, "id" => "world_championship"},
    %{"frequency" => 1.172, "id" => "london"},
    %{"frequency" => 1.092, "id" => "dubai"},
    %{"frequency" => 1.147, "id" => "sydney"},
    %{"frequency" => 1.031, "id" => "chance2"},
    %{"frequency" => 1.168, "id" => "chicago"},
    %{"frequency" => 1.162, "id" => "las_vegas"},
    %{"frequency" => 1.152, "id" => "new_york"},
    %{"frequency" => 1.202, "id" => "airport"},
    %{"frequency" => 1.141, "id" => "lyon"},
    %{"frequency" => 1.039, "id" => "nice"},
    %{"frequency" => 1.04, "id" => "paris"},
    %{"frequency" => 0.911, "id" => "chance3"},
    %{"frequency" => 0.978, "id" => "osaka"},
    %{"frequency" => 1.021, "id" => "tax_agency"},
    %{"frequency" => 0.906, "id" => "tokyo"}
  ]

  # Just some glueing code\
  # We can always deny harm chance like earthquake or sabotage

  @type venue_id :: binary()
  @type venue_options :: %{cities: list(%City{}), resorts: list(%Resort{})}
  @type opponents :: [%Player.State{}]

  @type build_scenario :: {:build, %City{} | %Resort{}, venue_options}
  @type build_decision :: -1 | non_neg_integer

  @spec make_decision(build_scenario, %GameState{}, Config.t) :: build_decision
  def make_decision({:build, venue, options}, game_state, %Config{} = config) do
    apply(Build, config.build, [venue, options, game_state])
  end

  @type repurchase_scenario :: {:repurchase, %City{} | %Resort{}}
  @type repurchase_decision :: 1 | 0

  @spec make_decision(repurchase_scenario, %GameState{}, Config.t) :: repurchase_decision
  def make_decision({:repurchase, venue}, game_state, %Config{} = config) do
    apply(Repurchase, config.repurchase, [venue, game_state])
  end

  @type sell_scenario :: {:sell, non_neg_integer, venue_options}
  @type sell_decision :: [venue_id]

  @spec make_decision(sell_scenario, %GameState{}, Config.t) :: sell_decision
  def make_decision({:sell, minimum, options}, game_state, %Config{} = config) do
    apply(Sell, config.sell, [minimum, options, game_state])
  end

  @type hold_world_championship_scenario :: {:hold_world_championship, venue_options}
  @type hold_world_championship_decision :: venue_id | -1

  @spec make_decision(hold_world_championship_scenario, %GameState{}, Config.t) :: hold_world_championship_decision
  def make_decision({:hold_world_championship, options}, game_state, %Config{} = config) do
    apply(HoldWorldChampionship, config.hold_world_championship, [options, game_state])
  end

  @type pick_flight_destination_scenario :: {:pick_flight_destination, venue_options}
  @type pick_flight_destination_decision :: venue_id | -1

  @spec make_decision(pick_flight_destination_scenario, %GameState{}, Config.t) :: pick_flight_destination_decision
  def make_decision({:pick_flight_destination, options}, game_state, %Config{} = config) do
    apply(PickFlightDestination, config.pick_flight_destination, [options, game_state])
  end

  @type jail_options :: [:roll_dices | {:pay, non_neg_integer} | :use_free_card]
  @type pick_jail_option_scenario :: {:pick_jail_option, jail_options}
  @type pick_jail_option_decision :: non_neg_integer

  @spec make_decision(pick_jail_option_scenario, %GameState{}, Config.t) :: pick_jail_option_decision
  def make_decision({:pick_jail_option, options}, game_state, %Config{} = config) do
    apply(PickJailOption, config.pick_jail_option, [options, game_state])
  end

  @type chance_action :: :add_shield | :cut_electricity | :downgrade | :destroy | :force_sale
  @type pick_chance_scenario :: {chance_action, venue_options} | {:gift, venue_options, opponents}
  @type pick_chance_decision :: venue_id | -1

  @spec make_decision(pick_chance_scenario, %GameState{}, Config.t) :: pick_chance_decision
  def make_decision({action, options}, game_state, %Config{} = config)
    when action in [:add_shield, :cut_electricity, :downgrade, :destroy, :force_sale]
  do
    apply(PickChance, config.pick_chance[action], [options, game_state])
  end

  def make_decision({:gift, options, opponents}, game_state, %Config{} = config) do
    apply(PickChance, config.pick_chance[:gift], [options, opponents, game_state])
  end

  def make_decision(_, _, _), do: :not_implement
end
