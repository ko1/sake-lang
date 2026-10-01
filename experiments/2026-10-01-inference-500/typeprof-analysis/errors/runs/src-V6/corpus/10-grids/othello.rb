DIRS = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]].freeze

def opponent(color) = color == :black ? :white : :black

def symbol(color)
  case color
  in :black then "X"
  in :white then "O"
  in nil then "."
  end
end

class Board
  attr_reader :size, :cells

  def initialize(size, cells)
    @size = size
    @cells = cells
  end

  def self.initial(size)
    cells = Array.new(size) { Array.new(size) }
    m = size / 2
    cells[m - 1][m - 1] = :white
    cells[m][m] = :white
    cells[m - 1][m] = :black
    cells[m][m - 1] = :black
    new(size, cells)
  end

  def inside?(r, c) = r >= 0 && r < @size && c >= 0 && c < @size

  def flips(r, c, color)
    return [] unless !@cells[r][c]    
    DIRS.flat_map do |dr, dc|
      line = []
      rr = r + dr
      cc = c + dc
      while inside?(rr, cc) && @cells[rr][cc] == opponent(color)
        line << [rr, cc]
        rr += dr
        cc += dc
      end
      !line.empty? && inside?(rr, cc) && @cells[rr][cc] == color ? line : []
    end
  end

  def legal_moves(color)
    moves = []
    @size.times do |r|
      @size.times do |c|
        f = flips(r, c, color)
        moves << { row: r, col: c, gain: f.size } unless f.empty?
      end
    end
    moves
  end

  def apply(r, c, color)
    f = flips(r, c, color)
    raise ArgumentError, "illegal move #{r},#{c}" if f.empty?
    @cells[r][c] = color
    f.each { |fr, fc| @cells[fr][fc] = color }
    f.size
  end

  def count(color) = @cells.sum { |row| row.count(color) }

  def to_s
    header = "  #{(0...@size).map { (97 + it).chr }.join(" ")}"
    rows = (0...@size).map { |r| "#{r + 1} #{@cells[r].map { symbol(it) }.join(" ")}" }
    [header, *rows].join("\n")
  end
end

def corner?(size, r, c) = (r == 0 || r == size - 1) && (c == 0 || c == size - 1)

# greedy with a corner bonus; ties go to the first move in reading order
def choose(b, color)
  moves = b.legal_moves(color)
  return nil if moves.empty?
  moves.max_by do |m|
    m => { row:, col:, gain: }
    gain + (corner?(b.size, row, col) ? 10 : 0)
  end
end

b = Board.initial(6)
color = :black
passes = 0
turn = 0
while passes < 2
  move = choose(b, color)
  if move
    passes = 0
    move => { row:, col: }
    gained = b.apply(row, col, color)
    turn += 1
    puts "#{turn}. #{symbol(color)} #{(97 + col).chr}#{row + 1} flips #{gained}"
  else
    passes += 1
    puts "   #{symbol(color)} passes"
  end
  color = opponent(color)
end
puts b
black = b.count(:black)
white = b.count(:white)
puts "black #{black}, white #{white}, empty #{36 - black - white}"
puts(black == white ? "draw" : "#{black > white ? "black" : "white"} wins")
begin
  b.apply(0, 0, :black)
rescue ArgumentError => e
  puts "check: #{e.message}"
end
