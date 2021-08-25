defmodule MonopolySimulation.Strategy.Repurchase do
  alias MonopolySimulation.Strategy.Variations
  alias MonopolySimulation.Venue.{City, Resort}
  alias MonopolySimulation.{GameState, Strategy}

  @behaviour Variations

  @type variations :: :always | :never

  @spec variations :: [variations]
  def variations(),
    do: [:always, :never]

  @spec always(%City{}, %GameState{}) :: Strategy.repurchase_decision
  @spec always(%Resort{}, %GameState{}) :: Strategy.repurchase_decision
  def always(_venue, _game_state), do: 1

  @spec never(%City{}, %GameState{}) :: Strategy.repurchase_decision
  @spec never(%Resort{}, %GameState{}) :: Strategy.repurchase_decision
  def never(_venue, _game_state), do: 0
end
