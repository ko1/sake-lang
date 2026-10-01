class Pos
  attr_reader :row, :col

  def initialize(row, col)
    @row = row
    @col = col
  end

  def +(other) = Pos.new(@row + other.row, @col + other.col)
  def -(other) = Pos.new(@row - other.row, @col - other.col)
  def to_s = "#{("a".ord + @col).chr}#{@row + 1}"
end

JUMPS = [Pos.new(2, 1), Pos.new(1, 2), Pos.new(-1, 2), Pos.new(-2, 1),
         Pos.new(-2, -1), Pos.new(-1, -2), Pos.new(1, -2), Pos.new(2, -1)].freeze

class Board
  attr_reader :size, :order

  def initialize(size, order)
    @size = size
    @order = order
  end

  def self.empty(size) = new(size, Array.new(size) { Array.new(size, 0) })

  def inside?(p) = p.row >= 0 && p.row < @size && p.col >= 0 && p.col < @size

  def free?(p) = inside?(p) && @order[p.row][p.col] == 0

  def mark(p, n)
    @order[p.row][p.col] = n
  end

  def moves_from(p) = JUMPS.map { |j| p + j }.select { |q| free?(q) }

  def degree(p) = moves_from(p).size

  def to_s
    @order.reverse.map { |row| row.map { |n| n.to_s.rjust(2) }.join(" ") }.join("\n")
  end
end

# Warnsdorff: always jump to the square with the fewest onward moves
def tour(size, start)
  b = Board.empty(size)
  path = [start]
  b.mark(start, 1)
  cur = start
  step = 1
  while step < size * size
    options = b.moves_from(cur)
    break if options.empty?
    nxt = options.min_by { |q| b.degree(q) }
    step += 1
    b.mark(nxt, step)
    path << nxt
    cur = nxt
  end
  [b, path]
end

def knight_move?(a, b)
  d = b - a
  dr = d.row.abs
  dc = d.col.abs
  (dr == 1 && dc == 2) || (dr == 2 && dc == 1)
end

def check(path)
  path.each_cons(2).count { |a, b| !knight_move?(a, b) }
end

[[5, Pos.new(0, 0)], [5, Pos.new(0, 1)], [6, Pos.new(0, 0)], [8, Pos.new(3, 4)]].each do |size, start|
  b, path = tour(size, start)
  visited = path.size
  puts "#{size}x#{size} from #{start}: visited #{visited}/#{size * size}, bad jumps #{check(path)}"
  if visited == size * size
    first = path.first
    last = path.last
    closed = first && last && knight_move?(last, first)
    puts "  complete tour, #{closed ? "closed" : "open"}; ends at #{last}"
    puts b if size <= 6
  else
    puts "  stuck at #{path.last}; route: #{path.take(8).join(" ")} ..."
  end
end
