# Example server for Monopoly game

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `iex -S mix phx.server`

To run some sample game:
```
config = MonopolySimulation.Game.config()
GenServer.cast(MonopolySimulation.Game, {:start, config})
```

It'll run for a while then show you the result from the sample games it ran.
You can tweak with the configuration to customize your game.
