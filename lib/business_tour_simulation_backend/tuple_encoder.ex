defmodule MonopolySimulation.TupleEncoder do
  defimpl Poison.Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      data
      |> Tuple.to_list()
      |> Poison.Encoder.List.encode(options)
    end
  end
end
