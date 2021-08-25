defmodule MonopolySimulation.Venue.Resort do
  use Accessible

  defstruct [
    :id,
    :rent_price,
    :owner,
    modifiers: MapSet.new()
  ]

  defimpl Poison.Encoder, for: MonopolySimulation.Venue.Resort do
    alias MonopolySimulation.Venue.Resort
    def encode(%Resort{} = data, options) do
      %{modifiers: modifiers} = data
      modifiers =
        for modifier <- MapSet.to_list(modifiers) do
          case modifier do
            {:world_championship, _} -> :world_championship
            {:electricity_outage, _} -> :electricity_outage
            modifier -> modifier
          end
        end
      data = %Resort{data | modifiers: modifiers}

      Map.from_struct(data)
      |> Poison.Encoder.Map.encode(options)
    end
  end
end
