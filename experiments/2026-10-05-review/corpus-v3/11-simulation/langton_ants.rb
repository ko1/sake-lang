DX = [0, 1, 0, -1].freeze
DY = [-1, 0, 1, 0].freeze

class Ant
  attr_reader :name, :x, :y, :dir, :steps

  def initialize(name, x, y, dir)
    @name = name
    @x = x
    @y = y
    @dir = dir
    @steps = 0
  end

  def turn(rule)
    case rule
    when "R" then @dir = (@dir + 1) % 4
    when "L" then @dir = (@dir + 3) % 4
    when "U" then @dir = (@dir + 2) % 4
    when "N" then @dir
    end
  end

  def forward
    @x += DX[@dir]
    @y += DY[@dir]
    @steps += 1
  end
end

def simulate(rules, ants, steps)
  grid = Hash.new(0)
  n = rules.size
  collisions = 0
  steps.times do
    ants.each do |ant|
      pos = [ant.x, ant.y]
      color = grid[pos]
      ant.turn(rules[color])
      grid[pos] = (color + 1) % n
      ant.forward
    end
    spots = ants.map { |a| [a.x, a.y] }
    collisions += 1 if spots.uniq.size < spots.size
  end
  [grid, collisions]
end

def bounds(grid)
  painted = grid.keys.select { |pos| grid[pos] != 0 }
  return nil if painted.empty?
  xs = painted.map(&:first)
  ys = painted.map(&:last)
  [xs.min, ys.min, xs.max, ys.max]
end

def render(grid, ants, limit)
  box = bounds(grid)
  return puts("(empty)") if box.nil?
  x0, y0, x1, y1 = box
  if x1 - x0 >= limit || y1 - y0 >= limit
    puts "(#{x1 - x0 + 1}x#{y1 - y0 + 1}, too large to draw)"
    return
  end
  glyphs = ".#o+*%@&="
  (y0..y1).each do |y|
    row = (x0..x1).map do |x|
      ant = ants.find { |a| a.x == x && a.y == y }
      ant ? ant.name[0].downcase : glyphs[grid[[x, y]]]
    end
    puts row.join
  end
end

def run(title, rules, specs, steps)
  ants = specs.map { |name, x, y, dir| Ant.new(name, x, y, dir) }
  grid, collisions = simulate(rules, ants, steps)
  painted = grid.count { |_pos, c| c != 0 }
  histogram = grid.values.tally
  puts "== #{title} rules=#{rules} steps=#{steps}"
  puts "painted cells: #{painted}, visited: #{grid.size}, collisions: #{collisions}"
  puts "colors: #{histogram.keys.sort.map { |c| "#{c}:#{histogram[c]}" }.join(" ")}"
  ants.each do |a|
    dist = a.x.abs + a.y.abs
    puts "  #{a.name} at (#{a.x}, #{a.y}) facing #{"NESW"[a.dir]}, #{dist} from origin"
  end
  render(grid, ants, 24)
  painted
end

results = {}
results["classic"] = run("classic", "RL", [["Alice", 0, 0, 0]], 400)
results["pair"] = run("two ants", "RL", [["Alice", 0, 0, 0], ["Bob", 3, 1, 2]], 250)
results["triangle"] = run("turmite", "RLR", [["Cleo", 0, 0, 1]], 300)
results["square"] = run("filler", "LRRRRRLLR", [["Dex", 0, 0, 0]], 300)
results["long"] = run("highway", "RL", [["Eve", 0, 0, 0]], 10200)
best = results.max_by { |_k, v| v }
puts "most painted: #{best[0]} (#{best[1]})" if best
