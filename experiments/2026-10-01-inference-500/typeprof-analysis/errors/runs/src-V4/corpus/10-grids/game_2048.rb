class Game
  attr_reader :board, :score, :spawns, :moves

  def initialize(board, score, spawns, moves)
    @board = board
    @score = score
    @spawns = spawns
    @moves = moves
  end

  def self.start(rows) = new(rows, 0, 0, 0)

  def shift(dir)
    turns = { "L" => 0, "U" => 1, "R" => 2, "D" => 3 }.fetch(dir)
    b = @board
    turns.times { b = rotate_left(b) }
    gained = 0
    moved = b.map do |row|
      out, points = slide_row(row)
      gained += points
      out
    end
    turns.times { moved = rotate_right(moved) }
    return false if moved == @board
    @board = moved
    @score += gained
    @moves += 1
    true
  end

  def spawn
    empties = []
    @board.each_with_index do |row, r|
      row.each_with_index { |v, c| empties << [r, c] if v == 0 }
    end
    return nil if empties.empty?
    @spawns += 1
    r, c = empties[(@spawns * 7) % empties.size]
    value = @spawns % 5 == 0 ? 4 : 2
    @board[r][c] = value
    [r, c, value]
  end

  def stuck?
    %w[L U R D].none? { |dir| Game.new(@board.map(&:dup), 0, 0, 0).shift(dir) }
  end

  def best = @board.flatten.max || 0

  def to_s
    @board.map { |row| row.map { |v| (v == 0 ? "." : v.to_s).rjust(5) }.join }.join("\n")
  end
end

# slide one row to the left, merging equal neighbours once; returns [row, points]
def slide_row(row)
  tiles = row.reject(&:zero?)
  out = []
  points = 0
  i = 0
  while i < tiles.size
    a = tiles[i]
    b = tiles[i + 1]
    if a == b
      out << a * 2
      points += a * 2
      i += 2
    else
      out << a
      i += 1
    end
  end
  out << 0 while out.size < row.size
  [out, points]
end

def rotate_left(board) = (0...4).map { |i| board.map { |row| row[3 - i] } }
def rotate_right(board) = (0...4).map { |i| board.reverse.map { |row| row[i] } }

p slide_row([2, 2, 2, 2])
p slide_row([4, 0, 4, 8])
p slide_row([2, 4, 8, 16])

g = Game.start([[2, 0, 0, 2], [0, 4, 0, 0], [0, 0, 0, 0], [2, 0, 0, 0]])
puts g
script = "LURDLLUURDDLURDLULLUDRLLUDDLURRDLLU"
ignored = 0
script.each_char do |dir|
  break if g.stuck?
  if g.shift(dir)
    placed = g.spawn
    if placed
      r, c, v = placed
      puts "#{dir}: score #{g.score}, new #{v} at #{r},#{c}" if g.moves % 5 == 0
    end
  else
    ignored += 1
  end
end
puts g
puts "moves #{g.moves}, ignored #{ignored}, score #{g.score}, best tile #{g.best}, stuck #{g.stuck?}"

late = Game.start([[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 8]])
puts "checkerboard stuck: #{late.stuck?}"
