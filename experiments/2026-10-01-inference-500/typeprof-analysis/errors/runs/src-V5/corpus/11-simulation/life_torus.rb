require "set"

class World
  attr_reader :width, :height, :alive, :generation

  def self.parse(rows)
    alive = Set.new
    rows.each_with_index do |row, y|
      row.chars.each_with_index do |ch, x|
        alive << [x, y] if ch == "#"
      end
    end
    new(rows.fetch(0).size, rows.size, alive, 0)
  end

  def initialize(width, height, alive, generation)
    @width = width
    @height = height
    @alive = alive
    @generation = generation
  end

  def wrap(x, y) = [(x + @width) % @width, (y + @height) % @height]

  def neighbor_counts
    counts = Hash.new(0)
    @alive.each do |x, y|
      [-1, 0, 1].each do |dy|
        [-1, 0, 1].each do |dx|
          next if dx == 0 && dy == 0
          counts[wrap(x + dx, y + dy)] += 1
        end
      end
    end
    counts
  end

  def step
    nxt = Set.new
    neighbor_counts.each do |cell, n|
      nxt << cell if n == 3 || (n == 2 && @alive.include?(cell))
    end
    @alive = nxt
    @generation += 1
    self
  end

  def signature
    cells = @alive.to_a.sort_by { |x, y| y * @width + x }
    cells.map { |x, y| "#{x}.#{y}" }.join(",")
  end

  def bounding_box
    return nil if @alive.empty?
    xs = @alive.map { |x, _y| x }
    ys = @alive.map { |_x, y| y }
    { x0: xs.min, y0: ys.min, x1: xs.max, y1: ys.max }
  end

  def render
    (0...@height).each do |y|
      line = (0...@width).map { |x| @alive.include?([x, y]) ? "#" : "." }
      puts line.join
    end
  end
end

def run(name, rows, limit)
  w = World.parse(rows)
  seen = { w.signature => 0 }
  populations = [w.alive.size]
  outcome = "still running after #{limit}"
  while w.generation < limit
    w.step
    populations << w.alive.size
    sig = w.signature
    if w.alive.empty?
      outcome = "died out at generation #{w.generation}"
      break
    end
    first = seen[sig]
    if first
      period = w.generation - first
      outcome = period == 1 ? "still life from generation #{first}" : "cycle of period #{period} from generation #{first}"
      break
    end
    seen[sig] = w.generation
  end
  puts "== #{name}: #{outcome}"
  puts "population: #{populations.take(16).join(" ")}#{populations.size > 16 ? " ..." : ""}"
  box = w.bounding_box
  if box
    box => { x0:, y0:, x1:, y1: }
    puts "bounding box: (#{x0},#{y0})-(#{x1},#{y1})"
  else
    puts "bounding box: none"
  end
  w.render
  populations.max
end

patterns = [
  ["blinker", [".....", "..#..", "..#..", "..#..", "....."]],
  ["glider", [".#......", "..#.....", "###.....", "........", "........", "........", "........", "........"]],
  ["toad", ["......", "......", "..###.", ".###..", "......", "......"]],
  ["diehard", ["..........", "......#...", "##........", ".#...###..", "..........", ".........."]],
  ["block", ["....", ".##.", ".##.", "...."]]
]

peaks = {}
patterns.each do |name, rows|
  peaks[name] = run(name, rows, 40)
end
puts "peak populations:"
peaks.sort_by { |name, n| [-n, name] }.each { |name, n| puts "  #{name.ljust(8)} #{n}" }
