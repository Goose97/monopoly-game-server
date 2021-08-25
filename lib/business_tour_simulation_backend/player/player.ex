defmodule MonopolySimulation.Player do
  alias MonopolySimulation.{Venue, Player, Data, GameSystem}
  alias MonopolySimulation.Venue.City
  alias MonopolySimulation.Venue.Resort

  def affordable_upgrades(%Player.State{} = player, %City{} = city) do
    available_upgrades = Venue.available_upgrades(city)
    available_upgrades =
      if player.completed_rounds == 0 do
        Enum.reject(available_upgrades, & &1.level == 4)
      else
        available_upgrades
      end

    Enum.filter(available_upgrades, & &1.cost <= player.balance)
  end

  def affordable_upgrades(%Player.State{} = player, %Resort{} = resort) do
    available_upgrades = Venue.available_upgrades(resort)
    Enum.filter(available_upgrades, & &1.cost <= player.balance)
  end

  def can_afford?(%Player.State{} = player, %City{} = city),
    do: player.balance >= Venue.repurchase_price(city)

  def move(%Player.State{} = player, {:step, steps}) do
    next_position = rem(player.position + steps, Data.total_tiles())
    move(player, {:straight_to, next_position})
  end

  def move(%Player.State{} = player, {:straight_to, position}) do
    jail_position = Data.venue_info() |> Enum.find_index(& &1["id"] == "jail")
    player =
      if position < player.position && position != jail_position do
        earn(player, Data.starting_line_bonus())
        |> increment_completed_rounds()
      else
        player
      end
    %{player | position: position}
  end

  def spend(%Player.State{balance: balance} = player, amount) when amount <= balance do
    %{player | balance: balance - amount}
  end

  def earn(%Player.State{balance: balance} = player, amount),
    do: %{player | balance: balance + amount}

  def acquire_item(%Player.State{items: items} = player, item),
    do: %{player | items: MapSet.put(items, item)}

  def use_item(%Player.State{items: items} = player, item),
    do: %{player | items: MapSet.delete(items, item)}

  def has_item?(%Player.State{items: items}, item),
    do: MapSet.member?(items, item)

  def save_last_dices(%Player.State{} = player, dices) do
    player = %{player | last_dices: dices}
    if GameSystem.pair_dices?(dices) do
      %{player | consecutive_pairs: player.consecutive_pairs + 1, can_take_another_turn: true}
    else
      %{player | consecutive_pairs: 0, can_take_another_turn: false}
    end
  end

  def bankrupt(%Player.State{} = player, current_turn),
    do: %{player | balance: nil, bankrupt_turn: current_turn}

  defp increment_completed_rounds(%Player.State{completed_rounds: completed_rounds} = player),
    do: %{player | completed_rounds: completed_rounds + 1}
end
