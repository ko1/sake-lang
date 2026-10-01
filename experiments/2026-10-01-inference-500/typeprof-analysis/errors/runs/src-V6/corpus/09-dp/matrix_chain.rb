# a matrix known only by its shape, plus the multiplications spent to build it
class DimensionError < StandardError
  attr_reader :left, :right

  def initialize(message, left, right)
    super(message)
    @left = left
    @right = right
  end
end

class Shape
  attr_reader :name, :rows, :cols, :cost

  def initialize(name, rows, cols, cost)
    @name = name
    @rows = rows
    @cols = cols
    @cost = cost
  end

  def *(other)
    raise DimensionError.new("cannot multiply", @name, other.name) if @cols != other.rows
    work = @rows * @cols * other.cols
    Shape.new("(#{@name}#{other.name})", @rows, other.cols, @cost + other.cost + work)
  end

  def to_s = "#{@name} [#{@rows}x#{@cols}] cost=#{@cost}"
end

def optimal_order(dims)
  n = dims.size - 1
  cost = Array.new(n) { Array.new(n, 0) }
  split = Array.new(n) { Array.new(n, 0) }
  2.upto(n) do |len|
    0.upto(n - len) do |i|
      j = i + len - 1
      best = nil
      i.upto(j - 1) do |k|
        c = cost[i][k] + cost[k + 1][j] + dims[i] * dims[k + 1] * dims[j + 1]
        if !best     || c < best
          best = c
          split[i][j] = k
        end
      end
      cost[i][j] = best
    end
  end
  [cost[0][n - 1], split]
end

def parens(names, split, i, j)
  return names[i] if i == j
  k = split[i][j]
  "(" + parens(names, split, i, k) + parens(names, split, k + 1, j) + ")"
end

def evaluate(shapes, split, i, j)
  return shapes[i] if i == j
  k = split[i][j]
  evaluate(shapes, split, i, k) * evaluate(shapes, split, k + 1, j)
end

def left_to_right(shapes)
  shapes.drop(1).reduce(shapes[0]) { |acc, s| acc * s }
end

def make_shapes(dims)
  names = (0...(dims.size - 1)).map { |i| (65 + i).chr }
  names.each_with_index.map { |nm, i| Shape.new(nm, dims[i], dims[i + 1], 0) }
end

chains = [
  [10, 30, 5, 60],
  [40, 20, 30, 10, 30],
  [30, 35, 15, 5, 10, 20, 25],
  [5, 10, 3, 12, 5, 50, 6],
  [2, 3]
]

chains.each do |dims|
  shapes = make_shapes(dims)
  names = shapes.map(&:name)
  best, split = optimal_order(dims)
  n = shapes.size
  puts "dims #{dims.join("x")}"
  puts "  optimal: #{parens(names, split, 0, n - 1)} = #{best} multiplications"
  result = evaluate(shapes, split, 0, n - 1)
  naive = left_to_right(shapes)
  puts "  check:   #{result}"
  puts "  naive:   #{naive}"
  saved = naive.cost - result.cost
  pct = naive.cost == 0 ? 0.0 : 100.0 * saved / naive.cost
  puts format("  saved %d (%.1f%%)", saved, pct)
end

bad = [Shape.new("P", 4, 5, 0), Shape.new("Q", 6, 2, 0)]
begin
  left_to_right(bad)
rescue DimensionError => e
  puts "#{e.message}: #{e.left} and #{e.right}"
end
