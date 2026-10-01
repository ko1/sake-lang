class ColumnFull < StandardError
  attr_reader :column

  def initialize(message, column)
    super(message)
    @column = column
  end
end

ROWS = 6
COLS = 7

class Board
  attr_reader :grid, :heights, :moves

  def initialize(grid, heights, moves)
    @grid = grid
    @heights = heights
    @moves = moves
  end

  def self.fresh = new(Array.new(ROWS) { Array.new(COLS, ".") }, Array.new(COLS, 0), 0)

  def copy = Board.new(@grid.map(&:dup), @heights.dup, @moves)

  def drop(col, piece)
    raise ArgumentError, "no column #{col}" if col < 0 || col >= COLS
    h = @heights[col]
    raise ColumnFull.new("column #{col} is full", col) if h >= ROWS
    @grid[h][col] = piece
    @heights[col] = h + 1
    @moves += 1
    h
  end

  def count_dir(r, c, dr, dc, piece)
    n = 0
    rr = r + dr
    cc = c + dc
    while rr >= 0 && rr < ROWS && cc >= 0 && cc < COLS && @grid[rr][cc] == piece
      n += 1
      rr += dr
      cc += dc
    end
    n
  end

  def wins_at?(r, c)
    piece = @grid[r][c]
    [[0, 1], [1, 0], [1, 1], [1, -1]].any? do |dr, dc|
      1 + count_dir(r, c, dr, dc, piece) + count_dir(r, c, -dr, -dc, piece) >= 4
    end
  end

  def legal = (0...COLS).select { |c| @heights[c] < ROWS }

  def full? = @moves == ROWS * COLS

  def to_s
    lines = @grid.reverse.map { |row| "|#{row.join}|" }
    lines << "+#{"-" * COLS}+" << " #{(0...COLS).to_a.join}"
    lines.join("\n")
  end
end

def other(piece) = piece == "X" ? "O" : "X"

def winning_column(b, piece)
  b.legal.find do |c|
    trial = b.copy
    r = trial.drop(c, piece)
    trial.wins_at?(r, c)
  end
end

def choose(b, piece)
  win = winning_column(b, piece)
  return [win, "win"] if win
  block = winning_column(b, other(piece))
  return [block, "block"] if block
  [b.legal.min_by { |c| (c - 3).abs * 10 + c }, "centre"]
end

def play(title, script)
  puts "== #{title} =="
  b = Board.fresh
  piece = "X"
  queue = script.chars.map(&:to_i)
  result = nil
  until result
    if b.full?
      result = "draw"
      next
    end
    col = queue.shift
    reason = "scripted"
    col, reason = choose(b, piece) if col.nil?
    begin
      r = b.drop(col, piece)
    rescue ColumnFull => e
      puts "  #{piece}: #{e.message}, choosing instead"
      col, reason = choose(b, piece)
      r = b.drop(col, piece)
    end
    puts "  #{piece} -> #{col} (#{reason})" if reason != "scripted"
    result = "#{piece} wins after #{b.moves} moves" if b.wins_at?(r, col)
    piece = other(piece)
  end
  puts b
  puts result
end

play("vertical race", "3434343")
play("scripted start, AI finish", "33332")
play("full column", "0000000")
play("diagonal", "0112232335")
