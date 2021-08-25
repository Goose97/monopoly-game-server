defmodule MonopolySimulation.Venue.Jail do
  use Accessible

  defmodule Player do
    use Accessible
    defstruct [
      :id,
      turn_count: 0
    ]
  end

  defstruct [
    players: %{}
  ]
end
