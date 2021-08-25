defmodule MonopolySimulation.Player.Server do
  alias MonopolySimulation.Strategy
  use GenServer

  def start_link(config), do: GenServer.start_link(__MODULE__, config)

  @impl true
  def init(config) do
    {:ok, config}
  end

  @impl true
  def handle_call({:player_decision, action, game_state}, _from, state) do
    %{strategy_config: strategy} = state
    decision = Strategy.make_decision(action.action, game_state, strategy)
    {:reply, {:ok, decision}, state}
  end
end
