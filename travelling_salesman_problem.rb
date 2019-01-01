require 'active_support/all'
require 'pry'

# @author Michał Tarsa <michal.tarsa1@gmail.com>
# @note Travelling salesman problem solved using evolutionary algorithm
# @note Default script execution parameters are stored as constants
#   these values can be changed by using parameters: [-n N] [-m MUTATION_RATE] [-g GENERATIONS_COUNT]
#   costs table can be printed using -c option
class TravellingSalesmanProblem
  N = 100
  MUTATION_RATE = 0.05
  GENERATIONS_COUNT = 100
  DEFAULT_CROSS_STRATEGY = :single_point_cross
  AVAILABLE_CROSS_STRATEGIES = [:single_point_cross]

  # @note read and parse input parameters, create needed instance variables
  def initialize
    params = ARGV.in_groups_of(2).to_h
    @number_of_cities = Integer(params.dig('-n') || N)
    @mutation_rate = params.dig('-m').to_f || MUTATION_RATE
    @present_costs = ARGV.include?('-c') || false
    @generations_count = Integer(params.dig('-g') || GENERATIONS_COUNT)
    @cross_strategy_method = AVAILABLE_CROSS_STRATEGIES.include?(params.dig('-s')) ? params.dig('-s') : DEFAULT_CROSS_STRATEGY

    @population = create_population
    @new_population = []
    @costs = create_costs
    @traversing_costs_history = []
  end

  # find traversing order for city
  # @param individual_index [Integer] is a index of a city
  # @return [Array] of cities corresponding for an order
  # @note each city has 100-elements table with randomly generated numbers from range [1,255]
  #   find cities with i element and save its indexes
  #   these elements creates path for salesman to visit all cities
  def find_traversing_order_for(individual_index)
    order = []
    individual = population[individual_index]

    (0..255).each do |current_index|
      order << individual.each_with_index.select{|item, index| item == current_index }.compact.map{|item, index| index}
    end

    order.flatten
  end

  # @param cities_array [Array]
  # @return cost of traversing all cities as a cycle
  def calculate_cost(cities_array)
    cities_array.each_with_index.map{|i,index| cities_array[index+1] ? [i, cities_array[index+1]] : [i, cities_array[0]]}.map{|i,j| costs[i][j]}.sum
  end

  # @note run population cross, mutation and tournament selection for each generation
  # @return information about evolutionary process and results summary
  def make_generations
    present_costs if @present_costs
    puts 'starting generation:'
    present_population_with_costs

    generations_count.times do
      cross
      mutation
      tournament_selection
    end

    puts 'results:'
    present_results
  end

  # @note Crossing the population individuals with selected strategy
  # @return [Array] New population of traversing orders
  def cross
    new_population = []
    population.in_groups_of(2).map(&:compact).each do |cities_pair|
      new_population << cross_strategy(cities_pair).flatten
    end
  end

  # @note Implementation of single point crossing strategy
  # @param [Array] cities_pair that are both arrays of cities traversing order
  # @return [Array] New population
  def single_point_cross(cities_pair)
    len = cities_pair.first.length
    selection_point = rand(len - 1)
    city_a = cities_pair.first
    city_b = cities_pair.last
    city_c = city_a.first(selection_point) + city_b.last(len - selection_point)
    city_d = city_b.first(selection_point) + city_a.last(len - selection_point)
    @new_population << city_c
    @new_population << city_d
  end

  # @note Implementation of mutation process
  #   given mutation rate changes randomly corresponding amount of genotypes
  def mutation
    genotypes_to_change = (number_of_cities * number_of_cities * mutation_rate).to_i
    genotypes_to_change.times do
      selected_population = [population, new_population][rand(2)]
      individual = rand(number_of_cities)
      genotype = rand(number_of_cities)
      selected_population[individual][genotype] = rand(number_of_cities)
    end
  end

  # @note Implementation of tournament selection
  #   old population and a new population are selected randomly in pairs
  #   better solution from each pair will be selected to new generation
  # @return [Array] of cities have won competitions
  def tournament_selection
    cities_pairs = (@new_population + @population).shuffle.in_groups_of(2).map(&:compact)

    winning_cities = []
    cities_pairs.each do |cities_pair|
      if cities_pair.length == 1
        winning_cities << cities_pair.first
      else
        winning_candidate = (calculate_cost(cities_pair.first) < calculate_cost(cities_pair.last)) ? cities_pair.first : cities_pair.last
        winning_cities << winning_candidate if winning_cities.last.present? && calculate_cost(winning_candidate) < calculate_cost(winning_cities.last)
      end
    end

    @population = winning_cities
    @new_population = []
  end

  private
  attr_reader :population,
              :costs,
              :new_population,
              :traversing_costs_history,
              :number_of_cities,
              :mutation_rate,
              :generations_count,
              :cross_strategy_method

  def create_population
    [].tap do |array|
      (0...number_of_cities).each do
        genotypes = []
        (0...number_of_cities).each do
          genotypes << rand(number_of_cities)
        end
        array << genotypes
      end
    end
  end

  def create_costs
    costs = (0...number_of_cities).map{|i| []}
    population.each_with_index do |from, i|
      population.each_with_index do |to, j|
        if i!= j
          random_cost = rand((10..100))
          costs[i][j] = random_cost
          costs[j][i] = random_cost
        else
          costs[i][j] = 0
          costs[i][j] = 0
        end
      end
    end

    costs
  end

  def cross_strategy(cities_pair)
    send(cross_strategy_method, cities_pair)
  end

  def present_population
    puts 'cities'
    population.each_with_index do |individual, index|
      puts "#{index}: #{individual}"
    end
  end

  def present_population_with_costs
    costs = []
    orders = []
    population.each_with_index do |individual, index|
      order = find_traversing_order_for(index)
      cost = calculate_cost(order)

      if costs.empty? || cost < costs.min
        costs << cost
        orders << order
        traversing_costs_history << costs.min
      end
    end

    best_order_index = costs.each_with_index.select{ |cost, index| cost == costs.min }.flatten.last
    puts "The lower traversing cost: #{costs.min} #{orders[best_order_index]}"
  end

  def present_costs
    costs.map{|cost| puts cost.to_s }
  end

  def present_results
    puts 'lowest cost changes:' + traversing_costs_history.to_s
    puts "#{(100 * (traversing_costs_history.max - traversing_costs_history.min) / traversing_costs_history.max.to_f).round(2)}% better result"
  end
end

cities = TravellingSalesmanProblem.new
cities.make_generations
