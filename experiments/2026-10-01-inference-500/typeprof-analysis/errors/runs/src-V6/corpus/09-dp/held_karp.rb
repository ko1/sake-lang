require "set"

class City
  attr_reader :name, :x, :y

  def initialize(name, x, y)
    @name = name
    @x = x
    @y = y
  end

  def distance(other) = (@x - other.x).abs + (@y - other.y).abs
end

# best[mask][j]: shortest path from city 0 visiting exactly `mask`, ending at j
def held_karp(cities)
  n = cities.size
  d = cities.map { |a| cities.map { |b| a.distance(b) } }
  full = (1 << n) - 1
  best = Array.new(full + 1) { Array.new(n) }
  prev = Array.new(full + 1) { Array.new(n) }
  best[1][0] = 0
  (1..full).each do |mask|
    next if mask & 1 == 0
    n.times do |j|
      here = best[mask][j]
      next if !here    
      1.upto(n - 1) do |k|
        bit = 1 << k
        next if mask & bit != 0
        nxt = mask | bit
        cand = here + d[j][k]
        old = best[nxt][k]
        if !old     || cand < old
          best[nxt][k] = cand
          prev[nxt][k] = j
        end
      end
    end
  end
  tour_len = nil
  last = nil
  1.upto(n - 1) do |j|
    v = best[full][j]
    next if !v    
    total = v + d[j][0]
    if !tour_len     || total < tour_len
      tour_len = total
      last = j
    end
  end
  order = []
  mask = full
  j = last
  while j
    order.unshift(j)
    pj = prev[mask][j]
    mask ^= (1 << j)
    j = pj
  end
  [tour_len, order, d]
end

def nearest_neighbour(cities, d)
  n = cities.size
  seen = Set[0]
  order = [0]
  total = 0
  cur = 0
  while seen.size < n
    cand = (0...n).reject { |k| seen.include?(k) }
    nxt = cand.min_by { |k| d[cur][k] * 100 + k }
    total += d[cur][nxt]
    seen << nxt
    order << nxt
    cur = nxt
  end
  [total + d[cur][0], order]
end

def names(cities, order)
  (order.map { |i| cities[i].name } + [cities[0].name]).join(" -> ")
end

depots = [
  City.new("Depot", 0, 0), City.new("Ash", 4, 7), City.new("Birch", 9, 2), City.new("Cedar", 3, 3),
  City.new("Dogwood", 8, 8), City.new("Elm", 1, 9), City.new("Fir", 6, 4), City.new("Gum", 10, 6)
]

[4, 6, 8].each do |k|
  cities = depots.take(k)
  len, order, d = held_karp(cities)
  greedy_len, greedy_order = nearest_neighbour(cities, d)
  puts "#{k} stops:"
  puts "  optimal #{len}: #{names(cities, order)}"
  puts "  greedy  #{greedy_len}: #{names(cities, greedy_order)}"
  gap = (100.0 * (greedy_len - len) / len).round(1)
  puts "  greedy is #{gap}% longer"
end

cities = depots
len, order, d = held_karp(cities)
puts "leg lengths of the optimal 8-stop tour:"
(order + [0]).each_cons(2) do |a, b|
  puts format("  %-8s %-8s %3d", cities[a].name, cities[b].name, d[a][b])
end
