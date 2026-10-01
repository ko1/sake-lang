require "set"

class Pile
  NEIGHBORS = [[1, 0], [-1, 0], [0, 1], [0, -1]].freeze

  attr_reader :size, :grid, :lost, :topples

  def initialize(n)
    @size = n
    @grid = Array.new(n) { Array.new(n, 0) }
    @lost = 0
    @topples = 0
  end

  def get(x, y) = @grid[y][x]

  def add(x, y, k)
    if x < 0 || y < 0 || x >= @size || y >= @size
      @lost += k
      return false
    end
    @grid[y][x] += k
    @grid[y][x] >= 4
  end

  def drop(x, y)
    unstable = []
    unstable << [x, y] if add(x, y, 1)
    toppled = Set.new
    count = 0
    until unstable.empty?
      cx, cy = unstable.shift
      next if get(cx, cy) < 4
      @grid[cy][cx] -= 4
      count += 1
      toppled << [cx, cy]
      NEIGHBORS.each do |dx, dy|
        nx = cx + dx
        ny = cy + dy
        unstable << [nx, ny] if add(nx, ny, 1)
      end
      unstable << [cx, cy] if get(cx, cy) >= 4
    end
    @topples += count
    [count, toppled.size]
  end

  def grains = @grid.sum(&:sum)

  def render
    @grid.each { |row| puts row.map { |v| " .:*#"[v] }.join }
  end
end

def bucket(n)
  return "0" if n == 0
  return "1" if n == 1
  b = 2
  b *= 2 while b < n
  "#{b / 2 + 1}-#{b}"
end

pile = Pile.new(9)
sizes = []
area_max = 0
seed = 17
320.times do |i|
  seed = (seed * 75 + 74) % 65537
  x = i % 5 == 0 ? 4 : seed % 9
  y = i % 5 == 0 ? 4 : (seed / 9) % 9
  count, area = pile.drop(x, y)
  sizes << count
  area_max = area if area > area_max
  if (i + 1) % 80 == 0
    puts "after #{i + 1} grains: on table #{pile.grains}, fell off #{pile.lost}, topples #{pile.topples}"
  end
end

puts "--- final configuration"
pile.render
counts = pile.grid.flatten.tally
puts "cell heights: #{counts.keys.sort.map { |h| "#{h}:#{counts[h]}" }.join(" ")}"
puts "--- avalanche sizes"
hist = Hash.new(0)
sizes.each { |s| hist[bucket(s)] += 1 }
order = hist.keys.sort_by { |k| k.split("-")[0].to_i }
order.each { |k| puts format("%7s %4d %s", k, hist[k], "#" * hist[k].ceildiv(4)) }
biggest = sizes.max
puts "largest avalanche: #{biggest} topples (grain #{sizes.index(biggest) + 1}), widest area #{area_max} cells"
quiet = sizes.count(0)
puts format("quiet drops: %d (%.1f%%)", quiet, 100.0 * quiet / sizes.size)
