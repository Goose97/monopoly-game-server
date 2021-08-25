defmodule MonopolySimulation.StatisticCollector.Server do
  alias MonopolySimulation.StatisticCollector.GameResult

  use GenServer

  @baseline_value %{
    win_rate: 25
  }

  def init(_) do
    {:ok, []}
  end

  def handle_cast({:game_sample, game_sample}, state) do
    {:noreply, [game_sample | state]}
  end

  def handle_call(:show, _from, state) do
    {:reply, format_result(state), state}
  end

  defp format_result(samples) do
    total_turn_samples = Enum.map(samples, & &1.total_turn)
    player_ranking_samples = Enum.flat_map(samples, & &1.ranking)

    %GameResult{
      game_statistic: %{
        sample_size: length(samples),
        turn: %{
          median: Statistex.median(total_turn_samples),
          maximum: Statistex.maximum(total_turn_samples),
          minimum: Statistex.minimum(total_turn_samples)
        }
      },
      player_statistic: caculate_player_statistic(player_ranking_samples)
    }
  end

  defp caculate_player_statistic(ranking_samples) do
    for {player_id, samples} <- Enum.group_by(ranking_samples, & &1.id), into: %{} do
      point_samples = Enum.map(samples, & &1.point)
      turn_samples = Enum.map(samples, & &1.total_turn)
      total_win = Enum.filter(samples, & &1.rank == 1) |> length()
      win_rate = Float.round(total_win * 100 / length(samples), 2)
      win_rate_baseline_comparision =
        case win_rate - @baseline_value.win_rate do
          diff when diff > 0 -> "+#{abs(diff)}%"
          diff when diff < 0 -> "-#{abs(diff)}%"
          0.0 -> "0%"
        end

      statistic = %{
        point: %{
          total: Statistex.total(point_samples),
          average: Statistex.average(point_samples),
          frequency_distribution: Statistex.frequency_distribution(point_samples),
          standard_deviation: Statistex.standard_deviation(point_samples)
        },
        bankrupt: %{
          total: Enum.filter(samples, & &1.is_bankrupted) |> length(),
        },
        turn: %{
          median: Statistex.median(turn_samples),
          maximum: Statistex.maximum(turn_samples),
          minimum: Statistex.minimum(turn_samples)
        },
        win_rate: %{
          value: Float.round(total_win * 100 / length(samples), 2),
          baseline_comparison: win_rate_baseline_comparision
        }
      }

      {player_id, statistic}
    end
  end
end
