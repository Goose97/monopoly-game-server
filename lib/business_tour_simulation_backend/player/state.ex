defmodule MonopolySimulation.Player.State do
  defstruct [
    :id,
    :balance,
    :position,
    :last_dices,
    :bankrupt_turn,
    consecutive_pairs: 0,
    can_take_another_turn: false,
    completed_rounds: 0,
    items: MapSet.new(),
  ]
end
