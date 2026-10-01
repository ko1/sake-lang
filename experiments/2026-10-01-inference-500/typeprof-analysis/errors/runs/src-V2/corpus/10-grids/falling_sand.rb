require "set"

class World
  attr_reader :cells, :height, :width, :tick

  def initialize(cells, height, width, tick)
    @cells = cells
    @height = height
    @width = width
    @tick = tick
  end

  def self.parse(lines) = new(lines.map(&:chars), lines.size, lines[0].size, 0)

  def at(r, c)
    return "#" if r < 0 || r >= @height || c < 0 || c >= @width
    @cells[r][c]
  end

  def empty?(r, c) = at(r, c) == " "

  def move(r, c, nr, nc)
    @cells[nr][nc], @cells[r][c] = @cells[r][c], @cells[nr][nc]
  end

  # one step, bottom row first so a grain moves at most once; returns how many cells moved
  def step
    moved = Set.new
    count = 0
    sides = @tick.even? ? [-1, 1] : [1, -1]
    (@height - 1).downto(0) do |r|
      @width.times do |c|
        next if moved.include?([r, c])
        kind = @cells[r][c]
        next unless kind == "o" || kind == "~"
        target = nil
        if empty?(r + 1, c) || (kind == "o" && at(r + 1, c) == "~")
          target = [r + 1, c]
        elsif (diag = sides.find { |dc| empty?(r + 1, c + dc) && empty?(r, c + dc) })
          target = [r + 1, c + diag]
        elsif kind == "~"
          flat = sides.find { |dc| empty?(r, c + dc) }
          target = [r, c + flat] if flat
        end
        next unless target
        move(r, c, *target)
        moved << target
        count += 1
      end
    end
    @tick += 1
    count
  end

  def census
    tally = @cells.flatten.tally
    "sand=#{tally["o"] || 0} water=#{tally["~"] || 0}"
  end

  def to_s = @cells.map { |row| "|#{row.join}|" }.join("\n")
end

def simulate(name, lines, limit, show_every)
  puts "== #{name} =="
  w = World.parse(lines)
  puts w
  before = w.census
  moves = []
  settled = false
  while !settled && w.tick < limit
    n = w.step
    moves << n
    settled = true if n == 0
    if !settled && w.tick % show_every == 0
      puts "-- tick #{w.tick} (#{n} moved)"
      puts w
    end
  end
  puts(settled ? "settled after #{w.tick - 1} ticks" : "still moving after #{limit} ticks")
  puts w
  puts "moves per tick: #{moves.join(",")}"
  puts "conserved: #{before == w.census} (#{w.census})"
end

simulate("hourglass", [
  "oooooooo",
  " oooooo ",
  "  #oo#  ",
  "   ##   ",
  "        ",
  "        ",
], 30, 4)

simulate("dam break", [
  "~~~~#    ",
  "~~~~#    ",
  "~~~~     ",
  "#########",
], 40, 5)

simulate("sand into water", [
  "  ooo   ",
  "        ",
  "#      #",
  "#~~~~~~#",
  "########",
], 20, 100)
