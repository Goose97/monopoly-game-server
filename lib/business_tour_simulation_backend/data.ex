defmodule MonopolySimulation.Data do
  # rent_price for all levels for every cities and resorts
  @cities %{
    "granada" => [
      %{"rent_price" => 2, "cost" => 60},
      %{"rent_price" => 25, "cost" => 110},
      %{"rent_price" => 50, "cost" => 160},
      %{"rent_price" => 75, "cost" => 210},
      %{"rent_price" => 150, "cost" => 360}
    ],
    "seville" => [
      %{"rent_price" => 2, "cost" => 60},
      %{"rent_price" => 28, "cost" => 110},
      %{"rent_price" => 55, "cost" => 160},
      %{"rent_price" => 83, "cost" => 210},
      %{"rent_price" => 165, "cost" => 360}
    ],
    "madrid" => [
      %{"rent_price" => 4, "cost" => 60},
      %{"rent_price" => 30, "cost" => 110},
      %{"rent_price" => 60, "cost" => 160},
      %{"rent_price" => 90, "cost" => 210},
      %{"rent_price" => 180, "cost" => 360}
    ],
    "hong_kong" => [
      %{"rent_price" => 6, "cost" => 100},
      %{"rent_price" => 33, "cost" => 150},
      %{"rent_price" => 65, "cost" => 200},
      %{"rent_price" => 98, "cost" => 250},
      %{"rent_price" => 195, "cost" => 400}
    ],
    "beijing" => [
      %{"rent_price" => 6, "cost" => 100},
      %{"rent_price" => 35, "cost" => 150},
      %{"rent_price" => 75, "cost" => 200},
      %{"rent_price" => 105, "cost" => 250},
      %{"rent_price" => 210, "cost" => 400}
    ],
    "shanghai" => [
      %{"rent_price" => 8, "cost" => 120},
      %{"rent_price" => 38, "cost" => 170},
      %{"rent_price" => 75, "cost" => 220},
      %{"rent_price" => 113, "cost" => 270},
      %{"rent_price" => 225, "cost" => 420}
    ],
    "venice" => [
      %{"rent_price" => 10, "cost" => 140},
      %{"rent_price" => 70, "cost" => 240},
      %{"rent_price" => 140, "cost" => 340},
      %{"rent_price" => 210, "cost" => 440},
      %{"rent_price" => 385, "cost" => 690}
    ],
    "milan" => [
      %{"rent_price" => 10, "cost" => 140},
      %{"rent_price" => 75, "cost" => 240},
      %{"rent_price" => 150, "cost" => 340},
      %{"rent_price" => 225, "cost" => 440},
      %{"rent_price" => 413, "cost" => 690}
    ],
    "rome" => [
      %{"rent_price" => 12, "cost" => 160},
      %{"rent_price" => 80, "cost" => 260},
      %{"rent_price" => 160, "cost" => 360},
      %{"rent_price" => 240, "cost" => 460},
      %{"rent_price" => 440, "cost" => 710}
    ],
    "hamburg" => [
      %{"rent_price" => 14, "cost" => 180},
      %{"rent_price" => 85, "cost" => 280},
      %{"rent_price" => 170, "cost" => 380},
      %{"rent_price" => 255, "cost" => 480},
      %{"rent_price" => 468, "cost" => 730}
    ],
    "berlin" => [
      %{"rent_price" => 16, "cost" => 200},
      %{"rent_price" => 90, "cost" => 300},
      %{"rent_price" => 180, "cost" => 400},
      %{"rent_price" => 270, "cost" => 500},
      %{"rent_price" => 495, "cost" => 750}
    ],
    "london" => [
      %{"rent_price" => 18, "cost" => 220},
      %{"rent_price" => 113, "cost" => 370},
      %{"rent_price" => 225, "cost" => 520},
      %{"rent_price" => 338, "cost" => 670},
      %{"rent_price" => 619, "cost" => 1045}
    ],
    "sydney" => [
      %{"rent_price" => 20, "cost" => 240},
      %{"rent_price" => 120, "cost" => 390},
      %{"rent_price" => 240, "cost" => 540},
      %{"rent_price" => 360, "cost" => 690},
      %{"rent_price" => 660, "cost" => 1065}
    ],
    "chicago" => [
      %{"rent_price" => 22, "cost" => 260},
      %{"rent_price" => 128, "cost" => 410},
      %{"rent_price" => 255, "cost" => 560},
      %{"rent_price" => 383, "cost" => 710},
      %{"rent_price" => 701, "cost" => 1085}
    ],
    "las_vegas" => [
      %{"rent_price" => 22, "cost" => 260},
      %{"rent_price" => 135, "cost" => 410},
      %{"rent_price" => 270, "cost" => 560},
      %{"rent_price" => 405, "cost" => 710},
      %{"rent_price" => 543, "cost" => 1085}
    ],
    "new_york" => [
      %{"rent_price" => 24, "cost" => 280},
      %{"rent_price" => 143, "cost" => 430},
      %{"rent_price" => 285, "cost" => 580},
      %{"rent_price" => 428, "cost" => 730},
      %{"rent_price" => 784, "cost" => 1105}
    ],
    "lyon" => [
      %{"rent_price" => 26, "cost" => 300},
      %{"rent_price" => 170, "cost" => 500},
      %{"rent_price" => 340, "cost" => 700},
      %{"rent_price" => 510, "cost" => 900},
      %{"rent_price" => 935, "cost" => 1400}
    ],
    "paris" => [
      %{"rent_price" => 28, "cost" => 320},
      %{"rent_price" => 180, "cost" => 520},
      %{"rent_price" => 360, "cost" => 720},
      %{"rent_price" => 540, "cost" => 920},
      %{"rent_price" => 990, "cost" => 1420}
    ],
    "osaka" => [
      %{"rent_price" => 35, "cost" => 350},
      %{"rent_price" => 190, "cost" => 550},
      %{"rent_price" => 380, "cost" => 750},
      %{"rent_price" => 570, "cost" => 950},
      %{"rent_price" => 1045, "cost" => 1450}
    ],
    "tokyo" => [
      %{"rent_price" => 50, "cost" => 400},
      %{"rent_price" => 200, "cost" => 600},
      %{"rent_price" => 400, "cost" => 800},
      %{"rent_price" => 600, "cost" => 1000},
      %{"rent_price" => 1100, "cost" => 1500}
    ],
  }

  @resorts %{
    "id" => ["bali", "cyprus", "dubai", "nice"],
    "rent_price" => [25, 50, 100, 200]
  }

  @resort_cost 200

  @chances %{
    happy_birthday: "Collect 25k from every opponent",
    to_world_championship: "Go directly to the city holding the World Championships",
    royal_gift: "Give up a city to any opponent for free", ###
    shield: "Protects your city against the purchase and on attack of the opponent",
    luxury_tax: "Go straight to the Tax Agency",
    world_championship: "Select a city to hold the World Championships",
    fine: "You lose 50000",
    sabotage: "Destroy any one opponent building (except hotels)",
    invitation: "Go straight to the World Tour square",
    earthquake: "An earthquake destroyed the city, and now the land belongs to no one (except hotels)",
    discount_coupon: "50% discount on your next rent payment",
    forced_sale: "You force an opponent to sell a city you choose (except hotels)", ###
    tourist_trip: "Go straight to the World Championships square",
    road_home: "Escape from Lost Island (can be used later)",
    electricity_outage: "Cut the lights in any opponents's city to take it out of commision", ###
    lost_island: "Go directly to the lost island",
    a_bad_sign: "The next time you pay rent, you pay double",
    start_over: "Go back to Start immediately",
  }

  @venue_info [
    %{"id" => "start", "type" => :start},
    %{"id" => "granada", "type" => :city},
    %{"id" => "seville", "type" => :city},
    %{"id" => "madrid", "type" => :city},
    %{"id" => "bali", "type" => :resort},
    %{"id" => "hong_kong", "type" => :city},
    %{"id" => "beijing", "type" => :city},
    %{"id" => "shanghai", "type" => :city},
    %{"id" => "jail", "type" => :jail},
    %{"id" => "venice", "type" => :city},
    %{"id" => "milan", "type" => :city},
    %{"id" => "rome", "type" => :city},
    %{"id" => "chance1", "type" => :chance},
    %{"id" => "hamburg", "type" => :city},
    %{"id" => "cyprus", "type" => :resort},
    %{"id" => "berlin", "type" => :city},
    %{"id" => "world_championship", "type" => :world_championship},
    %{"id" => "london", "type" => :city},
    %{"id" => "dubai", "type" => :resort},
    %{"id" => "sydney", "type" => :city},
    %{"id" => "chance2", "type" => :chance},
    %{"id" => "chicago", "type" => :city},
    %{"id" => "las_vegas", "type" => :city},
    %{"id" => "new_york", "type" => :city},
    %{"id" => "airport", "type" => :airport},
    %{"id" => "lyon", "type" => :city},
    %{"id" => "nice", "type" => :resort},
    %{"id" => "paris", "type" => :city},
    %{"id" => "chance3", "type" => :chance},
    %{"id" => "osaka", "type" => :city},
    %{"id" => "tax_agency", "type" => :tax_agency},
    %{"id" => "tokyo", "type" => :city}
  ]

  @player_initial_balance 2000
  @player_initial_position 0
  @total_tiles 32
  @repurchase_factor 2
  @world_championship_cost 50
  @airport_cost 50
  @jail_cost 200
  @max_turn_in_jail 3
  @starting_line_bonus 300
  @tax_rate 0.1
  @monopoly_groups [
    ["granada", "seville", "madrid"],
    ["hong_kong", "beijing", "shanghai"],
    ["venice", "milan", "rome"],
    ["hamburg", "berlin"],
    ["london", "sydney"],
    ["chicago", "las_vegas", "new_york"],
    ["lyon", "paris"],
    ["osaka", "tokyo"],
    @resorts["id"]
  ]
  @fine_amount 50
  @double_rent_multiplier 2
  @halve_rent_multiplier 0.5
  @birthday_present 25
  @max_consecutive_pairs 3
  @electriciy_outage_duration 3
  @festival_venues_amount 3
  @monopoly_to_win 3

  @script [
    [player: 1, dices: [8, 8]],
    [player: 1, dices: [4, 4]],
    [player: 1, dices: [1, 1]],
    [player: 1, dices: [5, 5]],
    [player: 1, dices: [1, 1]],
    # [player: 0, dices: [1, 1]],
    # [player: 0, dices: [1, 3]],
    # [player: 1, dices: [0, 1]],
    # [player: 1, dices: [17, 14]],
    # [player: 1, dices: [0, 1]],
    # [player: 1, dices: [6, 6]],
    # [player: 1, dices: [1, 2]],
    # [player: 1, dices: [1, 0]],
    # [player: 0, dices: [4, 1]],
    # [player: 1, dices: [1, 1]],
    # [player: 0, dices: [10, 14]],
    # [player: 0, dices: [2, 6]],
    # [player: 0, dices: [16, 15]],
    # [player: 0, dices: [16, 15]],
    # [player: 0, dices: [16, 15]],
    # [player: 1, dices: [16, 10]],
    # [player: 3, dices: [1, 2]],
    # [player: 2, dices: [5, 4]],
    # [player: 1, dices: [2, 5]],
    # [player: 1, dices: [6, 7]],
    # [player: 1, dices: [16, 16]],
    # [player: 1, dices: [16, 12]],
    # [player: 1, dices: [4, 3]],
    # [player: 0, dices: [1, 6]]
  ]

  def cities, do: @cities
  def city(id), do: @cities[id]
  def resorts, do: @resorts
  def resort_cost, do: @resort_cost
  def chances, do: @chances
  def player_initial_balance, do: @player_initial_balance
  def player_initial_position, do: @player_initial_position
  def total_tiles, do: @total_tiles
  def venue_info, do: @venue_info
  def repurchase_factor, do: @repurchase_factor
  def starting_line_bonus, do: @starting_line_bonus
  def script, do: nil
  def world_championship_cost, do: @world_championship_cost
  def airport_cost, do: @airport_cost
  def jail_cost, do: @jail_cost
  def max_turn_in_jail, do: @max_turn_in_jail
  def tax_rate, do: @tax_rate
  def monopoly_groups, do: @monopoly_groups
  def fine_amount, do: @fine_amount
  def double_rent_multiplier, do: @double_rent_multiplier
  def halve_rent_multiplier, do: @halve_rent_multiplier
  def birthday_present, do: @birthday_present
  def max_consecutive_pairs, do: @max_consecutive_pairs
  def electriciy_outage_duration, do: @electriciy_outage_duration
  def festival_venues_amount, do: @festival_venues_amount
  def monopoly_to_win, do: @monopoly_to_win
end
