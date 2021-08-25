defmodule MonopolySimulation.StatisticCollector.GameResult do
  defstruct [
    :game_statistic,
    :player_statistic
  ]

  @type game_statistic :: %{
    sample_size: non_neg_integer,
    turn: %{
      median: non_neg_integer,
      maximum: non_neg_integer,
      minimum: non_neg_integer
    }
  }

  @type player_statistic :: %{
    point: %{
      average: non_neg_integer,
      frequency_distribution: map,
      total: non_neg_integer,
      standard_deviation: non_neg_integer
    },
    bankrupt: %{
      total: non_neg_integer
    },
    turn: %{
      median: non_neg_integer,
      maximum: non_neg_integer,
      minimum: non_neg_integer
    },
    win_rate: %{
      value: non_neg_integer,
      baseline_comparison: binary
    }
  }

  @type t :: %__MODULE__{
    game_statistic: game_statistic,
    player_statistic: %{binary => player_statistic}
  }
end
