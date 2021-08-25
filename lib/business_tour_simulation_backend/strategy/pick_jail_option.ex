defmodule MonopolySimulation.Strategy.PickJailOption do
  alias MonopolySimulation.Strategy.Variations
  alias MonopolySimulation.{GameState, Strategy}

  @behaviour Variations

  @type variations :: :always_roll_dices | :always_pay_when_possible

  @spec variations :: [variations]
  def variations(),
    do: [:always_roll_dices, :always_pay_when_possible]

  @spec always_roll_dices(Strategy.jail_options, %GameState{}) :: Strategy.pick_jail_option_decision
  def always_roll_dices(_options, _game_state), do: 0

  @spec always_pay_when_possible(Strategy.jail_options, %GameState{}) :: Strategy.pick_jail_option_decision
  def always_pay_when_possible(options, _game_state),
    do: if length(options) > 1, do: 1, else: 0
end
