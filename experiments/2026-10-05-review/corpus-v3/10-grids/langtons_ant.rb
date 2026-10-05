class Ant
  attr_accessor :x, :y, :heading

  def initialize(x, y, heading)
    @x = x
    @y = y
    @heading = heading
  end
end

TURN_RIGHT = { north: :east, east: :south, south: :west, west: :north }.freeze
TURN_LEFT = { north: :west, west: :south, south: :east, east: :north }.freeze

def step_for(heading)
  case heading
  in :north then [0, -1]
  in :south then [0, 1]
  in :east then [1, 0]
  in :west then [-1, 0]
  end
end

class World
  attr_reader :rule, :cells, :ant, :steps

  def initialize(rule, cells, ant, steps)
    @rule = rule
    @cells = cells
    @ant = ant
    @steps = steps
  end

  def self.create(rule) = new(rule.chars, Hash.new(0), Ant.new(0, 0, :north), 0)

  def tick
    pos = [@ant.x, @ant.y]
    colour = @cells[pos]
    table = @rule[colour] == "R" ? TURN_RIGHT : TURN_LEFT
    @ant.heading = table[@ant.heading]
    nxt = (colour + 1) % @rule.size
    if nxt == 0
      @cells.delete(pos)
    else
      @cells[pos] = nxt
    end
    dx, dy = step_for(@ant.heading)
    @ant.x += dx
    @ant.y += dy
    @steps += 1
  end

  def run(n)
    n.times { tick }
    self
  end

  def bounds
    return nil if @cells.empty?
    xs = @cells.keys.map(&:first)
    ys = @cells.keys.map(&:last)
    [xs.min, ys.min, xs.max, ys.max]
  end

  def picture
    b = bounds
    return "(empty)" unless b
    x0, y0, x1, y1 = b
    glyphs = ".#o+*"
    (y0..y1).map do |y|
      (x0..x1).map do |x|
        x == @ant.x && y == @ant.y ? "A" : glyphs[@cells[[x, y]]]
      end.join
    end.join("\n")
  end

  def summary
    counts = @cells.values.tally
    parts = counts.keys.sort.map { |c| "#{c}:#{counts[c]}" }
    "step #{@steps}: #{@cells.size} coloured cells (#{parts.join(" ")}), ant at (#{@ant.x},#{@ant.y}) facing #{@ant.heading}"
  end
end

[["RL", [11, 100, 389]], ["LLRR", [50, 200]], ["RLR", [120]]].each do |rule, checkpoints|
  puts "rule #{rule}"
  w = World.create(rule)
  checkpoints.each do |target|
    w.run(target - w.steps)
    puts "  #{w.summary}"
  end
  puts w.picture
end
