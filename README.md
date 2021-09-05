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

Project structures:
- **MonopolySimulation.Game**: the master proces. There's only one for each instance. This process is responsible for keeping track of running games, relaying game samples result to the statistic collector and regulating the work of others game actors.
- **MonopolySimulation.Moderator**: for each running game, there's a moderator process. This process implements a game loop by sending messages to itself. This process is responsible for coordinating the game, communicating with players when needed and executing player decisions. The game state is stored in this process's state.
- **MonopolySimulation.Player**: for each player in a game, there's a player process. The player process is a GenServer, which functions like "the brain" of the player. It receives inquiries from the moderator (which upgrade to pick, which venue to sell, etc) and returns decision.
- **MonopolySimulation.Strategy**: this module is reponsible for making decisions. Splitting this module makes it easier to expands later on, especially when you need to integrate with client sides. You can write another module implements MonopolySimulation.Strategy.Behaviour behaviour then use it as an adapter to communicate with client sides. Switching between bots and real players is just about switching the implementation, the interface stays intact.
