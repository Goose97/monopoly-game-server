defmodule MonopolySimulationBackendWeb.Router do
  use MonopolySimulationBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MonopolySimulationBackendWeb do
    pipe_through :api
  end
end
