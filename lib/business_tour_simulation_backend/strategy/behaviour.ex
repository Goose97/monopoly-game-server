defmodule MonopolySimulation.Strategy.Behaviour do
  alias MonopolySimulation.{GameState, Strategy}

  @callback make_decision(any, %GameState{}, %Strategy.Config{}) :: any
end
