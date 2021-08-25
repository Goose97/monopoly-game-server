defmodule MonopolySimulation.Strategy.Config do
  alias MonopolySimulation.Strategy
  alias MonopolySimulation.Strategy.{Build, Repurchase, Sell, HoldWorldChampionship, PickFlightDestination, PickJailOption, PickChance}

  defstruct [
    :build,
    :repurchase,
    :sell,
    :hold_world_championship,
    :pick_flight_destination,
    :pick_jail_option,
    :pick_chance
  ]

  @type t :: %__MODULE__{
    build: Build.variations,
    repurchase: Repurchase.variations,
    sell: Sell.variations,
    hold_world_championship: HoldWorldChampionship.variations,
    pick_flight_destination: PickFlightDestination.variations,
    pick_jail_option: PickJailOption.variations,
    pick_chance: [{Strategy.chance_action, PickChance.variations}]
  }
end
