GROWTH_RATES = { "spring" => 0.35, "summer" => 0.25, "autumn" => 0.1, "winter" => 0.0 }

def growth_rate(season)
  GROWTH_RATES[season] || 0.0
end

class Patch
  attr_reader :name, :capacity, :neighbors
  attr_accessor :grass, :rabbits, :foxes

  def initialize(name, grass, rabbits, foxes, capacity, neighbors)
    @name = name
    @grass = grass
    @rabbits = rabbits
    @foxes = foxes
    @capacity = capacity
    @neighbors = neighbors
  end

  def to_s = format("%-7s grass %6.1f rabbits %6.1f foxes %5.2f", @name, @grass, @rabbits, @foxes)

  def grow(season)
    r = growth_rate(season)
    @grass += r * @grass * (1.0 - @grass / @capacity)
    @grass = @grass.clamp(0.0, @capacity)
  end

  def feed
    eaten = (@rabbits * 0.3).clamp(0.0, @grass * 0.5)
    @grass -= eaten
    fed_ratio = @rabbits > 0.0 ? eaten / (@rabbits * 0.3) : 0.0
    births = @rabbits * 0.4 * fed_ratio
    starve = @rabbits * 0.15 * (1.0 - fed_ratio)
    hunted = (@foxes * 5.0).clamp(0.0, @rabbits * 0.6)
    @rabbits = @rabbits + births - starve - hunted
    fox_births = hunted * 0.06
    fox_deaths = @foxes * 0.18
    @foxes = @foxes + fox_births - fox_deaths
    @rabbits = 0.0 if @rabbits < 0.5
    @foxes = 0.0 if @foxes < 0.1
    hunted
  end
end

class Census
  attr_reader :season, :grass, :rabbits, :foxes

  def initialize(season, grass, rabbits, foxes)
    @season = season
    @grass = grass
    @rabbits = rabbits
    @foxes = foxes
  end
end

def migrate(patches)
  by_name = patches.to_h { |p| [p.name, p] }
  moves = []
  patches.each do |p|
    crowding = p.rabbits / (p.grass + 1.0)
    next if crowding < 0.5
    targets = p.neighbors.filter_map { |n| by_name[n] }
    next if targets.empty?
    emigrants = p.rabbits * 0.2
    share = emigrants / targets.size
    targets.each { |t| moves << [p, t, share] }
  end
  moves.each do |from, to, amount|
    from.rabbits -= amount
    to.rabbits += amount
  end
  moves.size
end

patches = [
  Patch.new("meadow", 400.0, 60.0, 4.0, 500.0, ["forest", "river"]),
  Patch.new("forest", 200.0, 20.0, 6.0, 250.0, ["meadow"]),
  Patch.new("river", 300.0, 5.0, 0.0, 350.0, ["meadow", "marsh"]),
  Patch.new("hills", 150.0, 30.0, 2.0, 150.0, [])
]

seasons = ["spring", "summer", "autumn", "winter"]
history = []
total_hunted = 0.0
total_moves = 0
12.times do |q|
  season = seasons[q % 4]
  patches.each { |p| p.grow(season) }
  patches.each { |p| total_hunted += p.feed }
  total_moves += migrate(patches)
  history << Census.new("Y#{q / 4 + 1} #{season}",
    patches.sum(&:grass), patches.sum(&:rabbits), patches.sum(&:foxes))
end

history.each do |c|
  puts format("%-12s grass %7.1f rabbits %6.1f foxes %5.2f", c.season, c.grass, c.rabbits, c.foxes)
end
puts "--- final patches"
patches.each { |p| puts p }
peak = history.max_by(&:rabbits)
puts "rabbit peak: #{peak.season}" if peak
extinct = patches.select { |p| p.foxes == 0.0 }
puts "patches without foxes: #{extinct.map(&:name).join(", ")}"
puts format("total hunted %.1f, migration flows %d", total_hunted, total_moves)
