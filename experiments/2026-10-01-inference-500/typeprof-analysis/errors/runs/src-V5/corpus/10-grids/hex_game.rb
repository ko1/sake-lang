class Hex
  attr_reader :q, :r

  def initialize(q, r)
    @q = q
    @r = r
  end

  def +(other) = Hex.new(@q + other.q, @r + other.r)
  def -(other) = Hex.new(@q - other.q, @r - other.r)
  def key = [@q, @r]

  def length
    s = -@q - @r
    (@q.abs + @r.abs + s.abs) / 2
  end

  def to_s = "(#{@q},#{@r})"
end

HEX_DIRS = [Hex.new(1, 0), Hex.new(1, -1), Hex.new(0, -1), Hex.new(-1, 0), Hex.new(-1, 1), Hex.new(0, 1)].freeze

def distance(a, b) = (a - b).length

# union-find over keys, with path halving and two virtual edge nodes per player
class UnionFind
  attr_reader :parent

  def initialize(parent = {})
    @parent = parent
  end

  def find(x)
    @parent[x] = x unless @parent.key?(x)
    while @parent[x] != x
      @parent[x] = @parent[@parent[x]]
      x = @parent[x]
    end
    x
  end

  def union(a, b)
    ra = find(a)
    rb = find(b)
    @parent[ra] = rb if ra != rb
  end

  def same?(a, b) = find(a) == find(b)
end

class Game
  attr_reader :size, :stones, :sets, :winner

  def initialize(size, stones, sets, winner)
    @size = size
    @stones = stones
    @sets = sets
    @winner = winner
  end

  def self.start(size) = new(size, {}, UnionFind.new, nil)

  def inside?(h) = h.q >= 0 && h.q < @size && h.r >= 0 && h.r < @size

  def key_text(h) = "#{h.q},#{h.r}"

  # red joins left/right (q edges), blue joins top/bottom (r edges)
  def place(player, h)
    raise ArgumentError, "#{h} is off the board" unless inside?(h)
    raise ArgumentError, "#{h} is taken" if @stones.key?(h.key)
    @stones[h.key] = player
    k = key_text(h)
    HEX_DIRS.each do |d|
      n = h + d
      @sets.union(k, key_text(n)) if @stones[n.key] == player
    end
    if player == :red
      @sets.union(k, "red-west") if h.q == 0
      @sets.union(k, "red-east") if h.q == @size - 1
      @winner = :red if @sets.same?("red-west", "red-east")
    else
      @sets.union(k, "blue-north") if h.r == 0
      @sets.union(k, "blue-south") if h.r == @size - 1
      @winner = :blue if @sets.same?("blue-north", "blue-south")
    end
    @winner
  end

  def to_s
    (0...@size).map do |r|
      cells = (0...@size).map do |q|
        case @stones[[q, r]]
        in :red then "R"
        in :blue then "B"
        in nil then "."
        end
      end
      "#{" " * r}#{cells.join(" ")}"
    end.join("\n")
  end
end

origin = Hex.new(0, 0)
puts "neighbours of #{origin}: #{HEX_DIRS.map { |d| origin + d }.join(" ")}"
puts "distance (0,0)-(3,-1): #{distance(origin, Hex.new(3, -1))}, (2,2)-(-1,0): #{distance(Hex.new(2, 2), Hex.new(-1, 0))}"
ring = (-2..2).flat_map { |q| (-2..2).map { |r| Hex.new(q, r) } }.select { |h| distance(origin, h) == 2 }
puts "ring of radius 2 has #{ring.size} cells: #{ring.take(4).join(" ")} ..."

def play(title, size, moves)
  puts "== #{title} =="
  g = Game.start(size)
  player = :red
  moves.each do |q, r|
    break if g.winner
    begin
      w = g.place(player, Hex.new(q, r))
      puts "#{player} wins with (#{q},#{r}) on move #{g.stones.size}" if w
    rescue ArgumentError => e
      puts "#{player}: #{e.message}; turn lost"
    end
    player = player == :red ? :blue : :red
  end
  puts g
  puts "no winner yet" unless g.winner
end

play("red straight", 4, [[0, 1], [0, 0], [1, 1], [1, 0], [2, 1], [2, 0], [3, 1]])
play("blue zigzag", 4, [[0, 0], [2, 0], [1, 0], [2, 1], [3, 3], [1, 2], [0, 3], [1, 3]])
play("mistakes", 3, [[0, 0], [0, 0], [5, 1], [1, 1], [2, 2]])
