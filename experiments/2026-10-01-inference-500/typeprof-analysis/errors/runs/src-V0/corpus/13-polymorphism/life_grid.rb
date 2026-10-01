module CellSet
  def population
    n = 0
    each_cell { |r, c, alive| n += 1 if alive }
    n
  end

  def bounding_box
    rows = []
    cols = []
    each_cell do |r, c, alive|
      if alive
        rows << r
        cols << c
      end
    end
    return nil if rows.empty?
    [rows.min, cols.min, rows.max, cols.max]
  end
end

class Grid
  include CellSet
  attr_reader :h, :w, :cells

  def initialize(h, w, cells)
    @h = h
    @w = w
    @cells = cells
  end

  def self.blank(h, w) = Grid.new(h, w, Array.new(h) { Array.new(w, false) })

  def self.from_text(text)
    lines = text.lines.map(&:chomp)
    w = lines.map(&:size).max
    g = blank(lines.size, w)
    lines.each_with_index do |line, r|
      line.chars.each_with_index { |ch, c| g[r, c] = ch == "#" }
    end
    g
  end

  def [](r, c)
    @cells[r % @h][c % @w]
  end

  def []=(r, c, v)
    row = @cells[r % @h]
    row[c % @w] = v
  end

  def each_cell
    @h.times do |r|
      @w.times { |c| yield(r, c, self[r, c]) }
    end
  end

  def neighbours(r, c)
    n = 0
    [-1, 0, 1].each do |dr|
      [-1, 0, 1].each do |dc|
        next if dr == 0 && dc == 0
        n += 1 if self[r + dr, c + dc]
      end
    end
    n
  end

  def step
    nxt = Grid.blank(@h, @w)
    each_cell do |r, c, alive|
      n = neighbours(r, c)
      nxt[r, c] = alive ? (n == 2 || n == 3) : n == 3
    end
    nxt
  end

  def same?(other)
    each_cell { |r, c, alive| return false if alive != other[r, c] }
    true
  end

  def to_s
    @cells.map { |row| row.map { |x| x ? "#" : "." }.join }.join("\n")
  end
end

def run(name, text, generations)
  g = Grid.from_text(text)
  history = [g]
  puts "== #{name} (#{g.h}x#{g.w}) population #{g.population} =="
  puts g
  (1..generations).each do |gen|
    g = g.step
    seen_at = history.find_index { |old| old.same?(g) }
    if seen_at
      period = gen - seen_at
      kind = period == 1 ? "still life" : "oscillator with period #{period}"
      puts "generation #{gen}: repeats generation #{seen_at} -> #{kind}"
      return period
    end
    history << g
  end
  box = g.bounding_box
  puts "after #{generations}: population #{g.population}"
  puts g
  if box
    r0, c0, r1, c1 = box
    puts "bounding box rows #{r0}..#{r1} cols #{c0}..#{c1}"
  else
    puts "everything died"
  end
  nil
end

block = "....\n.##.\n.##.\n....\n"
blinker = ".....\n..#..\n..#..\n..#..\n.....\n"
glider = ".#......\n..#.....\n###.....\n........\n........\n........\n"
toad = "......\n......\n..###.\n.###..\n......\n......\n"
dies = "#....\n.....\n....#\n"

results = {}
results["block"] = run("block", block, 5)
results["blinker"] = run("blinker", blinker, 5)
results["toad"] = run("toad", toad, 5)
results["glider"] = run("glider", glider, 4)
results["dies"] = run("dies", dies, 3)

puts "== summary =="
results.each do |name, period|
  puts format("%-8s %s", name, period ? "period #{period}" : "no repeat")
end
