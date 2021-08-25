defmodule MonopolySimulation.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    create_ets_tables()

    children = [
      supervisor(MonopolySimulationBackendWeb.Endpoint, []),
      supervisor(MonopolySimulation.Game, []),
    ]

    opts = [strategy: :one_for_one, name: MonopolySimulationBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp create_ets_tables do
    :ets.new(:game_config, [:set, :named_table, :public])
    :ets.new(:game_actors, [:set, :named_table, :public])
    :ets.new(:actors_by_game, [:set, :named_table, :public])
    :ets.new(:game_moderators, [:set, :named_table, :public])
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MonopolySimulationBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
