defmodule MonopolySimulation.StatisticCollector do

  @spec collect(%__MODULE__.GameSample{}, pid) :: :ok
  def collect(%__MODULE__.GameSample{} = game_sample, pid) do
    GenServer.cast(pid, {:game_sample, game_sample})
  end

  def show(pid) do
    GenServer.call(pid, :show)
  end
end
