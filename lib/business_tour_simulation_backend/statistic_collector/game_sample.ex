defmodule MonopolySimulation.StatisticCollector.GameSample do
  defstruct [
    :total_turn,
    :ranking,
    :win_reason
  ]

  @type player_rank :: %{
    id: binary,
    rank: non_neg_integer,
    point: non_neg_integer,
    total_turn: non_neg_integer,
    is_bankrupted: boolean,
    total_worth: non_neg_integer
  }
  @type t :: %__MODULE__{
    total_turn: non_neg_integer,
    ranking: [player_rank],
    win_reason: :all_bankrupt | :city_monopoly | :resort_monopoly | :side_monopoly
  }
end
