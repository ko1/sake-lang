class Forest
  GLYPHS = { tree: "T", fire: "*", ash: "~", empty: "." }.freeze
  NEIGHBORS = [[1, 0], [-1, 0], [0, 1], [0, -1]].freeze

  attr_reader :width, :height, :cells, :burned, :fires_started

  def initialize(width, height, density, seed)
    @width = width
    @height = height
    @rng = seed
    @burned = 0
    @fires_started = 0
    @cells = Array.new(height) { Array.new(width) { rand100 < density ? :tree : :empty } }
  end

  def rand100
    @rng = (@rng * 1103515245 + 12345) % 2147483648
    (@rng / 65536) % 100
  end

  def at(x, y)
    return :edge if x < 0 || y < 0 || x >= @width || y >= @height
    @cells[y][x]
  end

  def ignite(x, y)
    return false unless at(x, y) == :tree
    @cells[y][x] = :fire
    @fires_started += 1
    true
  end

  def count(kind) = @cells.sum { |row| row.count(kind) }

  def step(wind)
    wx, wy = wind
    nxt = @cells.map(&:dup)
    @height.times do |y|
      @width.times do |x|
        case @cells[y][x]
        when :fire
          nxt[y][x] = :ash
          @burned += 1
          NEIGHBORS.each do |dx, dy|
            nx = x + dx
            ny = y + dy
            next unless at(nx, ny) == :tree
            chance = (dx == wx && dy == wy) ? 90 : ((dx + wx == 0 && dy + wy == 0) ? 15 : 55)
            nxt[ny][nx] = :fire if rand100 < chance
          end
        when :ash
          nxt[y][x] = :empty if rand100 < 10
        when :empty
          nxt[y][x] = :tree if rand100 < 2
        end
      end
    end
    @cells = nxt
  end

  def render
    @cells.each { |row| puts row.map { |c| GLYPHS.fetch(c) }.join }
  end
end

def run(title, wind, seed)
  f = Forest.new(24, 10, 78, seed)
  trees0 = f.count(:tree)
  f.ignite(8, 5) || f.ignite(9, 5) || f.ignite(8, 4)
  puts "== #{title}: #{trees0} trees, wind #{wind}"
  history = []
  t = 0
  while f.count(:fire) > 0 && t < 40
    f.step(wind)
    t += 1
    history << f.count(:fire)
    if t == 6
      puts "after #{t} steps:"
      f.render
    end
  end
  puts "burned out after #{t} steps" if f.count(:fire) == 0
  puts "fire front: #{history.join(" ")}"
  burned = f.burned
  puts format("burned %d of %d trees (%.1f%%), peak front %d at step %d",
    burned, trees0, 100.0 * burned / trees0, history.max, history.index(history.max) + 1)
  f.render
  burned
end

results = {}
[["calm east wind", [1, 0]], ["west wind", [-1, 0]], ["south wind", [0, 1]]].each do |title, wind|
  results[title] = run(title, wind, 3)
end
worst = results.max_by { |e__0| _k, v = e__0; v }
puts "worst case: #{worst[0]}" if worst
