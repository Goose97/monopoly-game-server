defmodule MonopolySimulation.Game.Config do
  defstruct [
    :id,
    :player_count,
    :player_config,
    :sample_amount,
    :parallel_run,
    run_mode: :auto,
  ]
end
