require 'active_support/all'
require 'pry'

# Travelling salesman problem
#
# algorithm description
# given 100 cities
# each city has 100-elements table with randomly generated numbers from range [1,255]
# for i in (1..255)
# find cities with i element and save its indexes
# these elements creates path for salesman to visit all cities
#
#

class CitiesCollection
  N = 5

  def initialize
    @population = create_population
    @new_population = []
    @costs = create_costs
    @travarsing_costs_history = []
  end

  def present_population
    puts 'cities'
    population.each_with_index do |individual, index|
      puts "#{index}: #{individual}"
    end
    puts separator
  end

  def present_population_with_costs
    puts 'individuals with costs'
    population.each do |individual|
      # binding.pry
      puts "#{individual}, costs: #{calculate_cost(individual)}"
    end
    puts separator
  end

  def find_traversing_order_for(individual_index)
    order = []
    individual = population[individual_index]

    (0..255).each do |current_index|
      order << individual.each_with_index.select{|item, index| item == current_index }.compact.map{|item, index| index}
    end

    order.flatten
  end

  def present_traversing_paths
    puts 'traversing orders'
    (0...N).each{ |city| print find_traversing_order_for(city); puts ' cost: ' + calculate_cost(find_traversing_order_for(city)).to_s }
    puts separator
  end

  def calculate_cost(cities_array)
    cities_array.each_with_index.map{|i,index| cities_array[index+1] ? [i, cities_array[index+1]] : [i, cities_array[0]]}.map{|i,j| costs[i][j]}.sum
  end

  def cross
    cities_pairs = population.in_groups_of(2).map(&:compact)
    # binding.pry
    new_population = []
    cities_pairs.each do |cities_pair|
      new_population << single_point_cross(cities_pair).flatten
    end
  end

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

  def tournament_selection
    cities_pairs = (@new_population + @population).shuffle.in_groups_of(2).map(&:compact)
    winning_cities = []
    cities_pairs.each do |cities_pair|
      if cities_pair.length == 1
        winning_cities << cities_pair.first
      else
        # binding.pry
        best_candidate = (calculate_cost(cities_pair.first) < calculate_cost(cities_pair.last)) ? cities_pair.first : cities_pair.last
        winning_cities << best_candidate
      end
    end

    # cities_pair.compact.each do |pair|
    #   winning_individual = (calculate_cost(pair[0]) < calculate_cost(pair[1])) ? pair[0] : pair[1]
    # end
    @population = winning_cities
    @new_population = []
  end

  private
  attr_reader :population, :costs, :new_population

  # def change_base(number, base = 2, string_length = 8)
  #   changed_base = number.to_s(base)
  #   "0" * (string_length - changed_base.length) + changed_base
  # end

  def create_population
    [].tap do |array|
      (0...N).each do
        genotypes = []
        (0...N).each do
          genotypes << rand(N)
        end
        array << genotypes
      end
    end
  end

  def create_costs
    costs = (0...N).map{|i| []}
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

  def travelling_cost(i,j)
    i == j ? 10_000 : rand(5 * N)
  end

  def separator
    "\n\n\n"
  end
end

cities = CitiesCollection.new
cities.present_population_with_costs
puts cities.send(:costs).to_s

cities.cross
cities.tournament_selection
cities.present_population_with_costs

# cities.present_traversing_paths
cities.cross
cities.tournament_selection
cities.present_population_with_costs

cities.cross
cities.tournament_selection
cities.present_population_with_costs

cities.cross
cities.tournament_selection
cities.present_population_with_costs

cities.cross
cities.tournament_selection
cities.present_population_with_costs

cities.cross
cities.tournament_selection
cities.present_population_with_costs
