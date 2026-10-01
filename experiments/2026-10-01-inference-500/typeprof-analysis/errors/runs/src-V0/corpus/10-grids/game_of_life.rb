class Board
  attr_reader :rows, :cols, :cells, :generation

  def initialize(rows, cols, cells, generation)
    @rows = rows
    @cols = cols
    @cells = cells
    @generation = generation
  end

  def self.parse(lines)
    cells = lines.map { |line| line.chars.map { |ch| ch == "#" } }
    new(lines.size, lines[0].size, cells, 0)
  end

  def alive?(r, c)
    @cells[(r + @rows) % @rows][(c + @cols) % @cols]
  end

  def neighbours(r, c)
    n = 0
    [-1, 0, 1].each do |dr|
      [-1, 0, 1].each do |dc|
        next if dr == 0 && dc == 0
        n += 1 if alive?(r + dr, c + dc)
      end
    end
    n
  end

  def step
    @cells = (0...@rows).map do |r|
      (0...@cols).map do |c|
        n = neighbours(r, c)
        @cells[r][c] ? (n == 2 || n == 3) : n == 3
      end
    end
    @generation += 1
    self
  end

  def population = @cells.sum { |row| row.count { it } }

  def key = @cells.map { |row| row.map { it ? "#" : "." }.join }.join("/")

  def to_s = @cells.map { |row| row.map { it ? "#" : "." }.join }.join("\n")
end

def run(name, lines, max_gens)
  board = Board.parse(lines)
  seen = { board.key => 0 }
  puts "== #{name} (#{board.rows}x#{board.cols}) =="
  puts board
  history = [board.population]
  result = nil
  while board.generation < max_gens
    board.step
    gen = board.generation
    history << board.population
    k = board.key
    if (prev = seen[k])
      result = [prev, gen - prev]
      break
    end
    seen[k] = gen
  end
  puts "after #{board.generation} generations:"
  puts board
  puts "population: #{history.join(" ")}"
  if result
    first, period = result
    if period == 1
      puts "still life from generation #{first}"
    else
      puts "cycle of period #{period} entered at generation #{first}"
    end
  else
    puts "no repetition within #{max_gens} generations"
  end
  puts "peak population: #{history.max}, extinct: #{board.population == 0}"
end

run("blinker", [".....", ".....", ".###.", ".....", "....."], 10)
run("block", ["....", ".##.", ".##.", "...."], 5)
run("glider", ["#.....", ".##...", "##....", "......", "......", "......"], 30)
run("diehard-ish", [".......", "......#", "##.....", ".#...##", "......."], 12)
