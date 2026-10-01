# Matrix arithmetic with operators on a Matrix type; shape mismatches and singular inversions raise errors.
class DimensionError < StandardError
  attr_reader :left, :right

  def initialize(message, left, right)
    super(message)
    @left = left
    @right = right
  end
end

class SingularMatrix < StandardError
  attr_reader :det

  def initialize(message, det)
    super(message)
    @det = det
  end
end

class Matrix
  attr_reader :rows

  def initialize(rows)
    @rows = rows
  end

  def shape = [@rows.size, @rows.first.size]

  def [](pos)
    i, j = pos
    @rows.fetch(i).fetch(j)
  end

  def []=(pos, v)
    i, j = pos
    @rows.fetch(i)[j] = v
  end

  def +(other)
    check_same(other, "+")
    Matrix.new(@rows.zip(other.rows).map { |r, s| r.zip(s).map { |x, y| x + y } })
  end

  def -(other)
    check_same(other, "-")
    Matrix.new(@rows.zip(other.rows).map { |r, s| r.zip(s).map { |x, y| x - y } })
  end

  def *(other)
    n, k = shape
    k2, m = other.shape
    raise DimensionError.new("cannot multiply #{n}x#{k} by #{k2}x#{m}", shape, other.shape) if k != k2
    Matrix.new((0...n).map do |i|
      (0...m).map do |j|
        (0...k).sum { |t| self[[i, t]] * other[[t, j]] }
      end
    end)
  end

  def check_same(other, op)
    return if shape == other.shape
    sa = shape
    sb = other.shape
    raise DimensionError.new("#{op}: shapes #{sa[0]}x#{sa[1]} and #{sb[0]}x#{sb[1]} differ", sa, sb)
  end

  def det2
    raise DimensionError.new("det2 needs 2x2", shape, [2, 2]) unless shape == [2, 2]
    self[[0, 0]] * self[[1, 1]] - self[[0, 1]] * self[[1, 0]]
  end

  # exact inverse of a 2x2 matrix with Rational entries
  def inverse2
    d = det2
    raise SingularMatrix.new("matrix is singular", d) if d == 0
    r = Rational(1, d)
    Matrix.new([[self[[1, 1]] * r, -self[[0, 1]] * r], [-self[[1, 0]] * r, self[[0, 0]] * r]])
  end

  def to_s = @rows.map { |r| "[#{r.map(&:to_s).join(" ")}]" }.join(" ")
end

def m(rows) = Matrix.new(rows)

a = m([[1, 2], [3, 4]])
b = m([[5, 6], [7, 8]])
c = m([[1, 0, 2], [0, 1, 3]])
s = m([[2, 4], [1, 2]])

def attempt(label)
  result = yield
  puts "#{label} = #{result}"
rescue DimensionError => e
  puts "#{label}: dimension error: #{e.message}"
rescue SingularMatrix => e
  puts "#{label}: #{e.message} (det #{e.det})"
rescue IndexError
  puts "#{label}: index out of range"
end

attempt("a + b") { a + b }
attempt("b - a") { b - a }
attempt("a * c") { a * c }
attempt("c * a") { c * a }
attempt("a + c") { a + c }
attempt("det(a)") { a.det2 }
attempt("det(c)") { c.det2 }
attempt("inv(a)") { a.inverse2 }
attempt("inv(s)") { s.inverse2 }
attempt("a * inv(a)") { a * a.inverse2 }
attempt("a[2,0]") { a[[2, 0]] }
attempt("c[1,2]") { c[[1, 2]] }
b[[0, 1]] = 60
attempt("b") { b }

total = 0
[[a, b], [c, a], [a, c], [s, s]].each do |x, y|
  total += (x * y).rows.sum(&:sum)
rescue DimensionError
  total += 0
end
puts "sum of all valid products: #{total}"
