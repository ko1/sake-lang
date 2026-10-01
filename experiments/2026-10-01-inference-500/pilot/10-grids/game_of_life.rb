# Conway's Game of Life on a bounded board, with cycle detection.

class Board
  attr_reader :width, :height, :cells

  def initialize(width, height, cells)
    @width = width
    @height = height
    @cells = cells
  end

  def self.parse(rows)
    h = rows.size
    w = rows[0].size
    cells = []
    rows.each do |row|
      cells.push(row.chars.map { |c| c == "#" })
    end
    Board.new(w, h, cells)
  end

  def self.blank(w, h)
    Board.new(w, h, (0...h).map { (0...w).map { false } })
  end

  def [](pos)
    x, y = pos
    return false if x < 0 || y < 0 || x >= @width || y >= @height
    @cells[y][x]
  end

  def []=(pos, v)
    x, y = pos
    row = @cells[y]
    row[x] = v
  end

  def neighbors(x, y)
    count = 0
    [-1, 0, 1].each do |dy|
      [-1, 0, 1].each do |dx|
        next if dx == 0 && dy == 0
        count += 1 if self[[x + dx, y + dy]]
      end
    end
    count
  end

  def step
    nb = Board.blank(@width, @height)
    @height.times do |y|
      @width.times do |x|
        n = neighbors(x, y)
        alive = self[[x, y]]
        nb[[x, y]] = alive ? (n == 2 || n == 3) : n == 3
      end
    end
    nb
  end

  def population
    @cells.map { |row| row.count { |c| c } }.sum
  end

  def key
    @cells.map { |row| row.map { |c| c ? "1" : "0" }.join("") }.join("/")
  end

  def to_s
    @cells.map { |row| row.map { |c| c ? "#" : "." }.join("") }.join("\n")
  end
end

def run(name, rows, max_steps)
  board = Board.parse(rows)
  seen = {}
  history = []
  puts("== #{name} (#{board.width}x#{board.height}) ==")
  puts(board)
  gen = 0
  while gen < max_steps
    k = board.key
    prev = seen[k]
    if prev
      puts("cycle: generation #{gen} repeats generation #{prev} (period #{gen - prev})")
      break
    end
    seen[k] = gen
    history.push(board.population)
    board = board.step
    gen += 1
  end
  puts("after #{gen} generations:")
  puts(board)
  puts("population: #{history.join(" ")}")
  peak = history.max
  puts("peak #{peak} at generation #{history.index(peak)}")
  puts
end

run("blinker", [".....", "..#..", "..#..", "..#..", "....."], 10)
run("glider", [".#......", "..#.....", "###.....", "........", "........", "........"], 30)
run("beehive", ["......", "..##..", ".#..#.", "..##..", "......"], 5)
run("r-pentomino", ["........", "........", "...##...", "..##....", "...#....", "........", "........"], 40)
