defmodule MonopolySimulation.Venue.City do
  use Accessible

  defstruct [
    :id,
    :rent_price,
    :owner,
    :level,
    modifiers: MapSet.new()
  ]

  defimpl Poison.Encoder, for: MonopolySimulation.Venue.City do
    alias MonopolySimulation.Venue.City
    def encode(%City{} = data, options) do
      %{modifiers: modifiers} = data
      modifiers =
        for modifier <- MapSet.to_list(modifiers) do
          case modifier do
            {:world_championship, _} -> :world_championship
            {:electricity_outage, _} -> :electricity_outage
            modifier -> modifier
          end
        end
      data = %City{data | modifiers: modifiers}

      Map.from_struct(data)
      |> Poison.Encoder.Map.encode(options)
    end
  end
end
