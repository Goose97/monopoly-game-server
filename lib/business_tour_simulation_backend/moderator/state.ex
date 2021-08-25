defmodule MonopolySimulation.Moderator.State do
  use Accessible

  defstruct [
    :game_state, # keys: :venues | :players | :dices
    :game_config,
    :player_pids,
    current_turn: 0,
    game_finished?: false,
    game_state_history: [],
    game_logs: %{
      player_actions: [],
      player_balance_changes: []
    }
  ]
end
