class DimensionError < StandardError
  attr_reader :op
  def initialize(message, op)
    super(message)
    @op = op
  end
end

class SingularError < StandardError
end

class Matrix
  attr_reader :rows

  def initialize(rows)
    @rows = rows
  end

  def self.build(n, m)
    rows = []
    n.times do |i|
      row = []
      m.times { |j| row << yield(i, j) }
      rows << row
    end
    Matrix.new(rows)
  end

  def self.identity(n) = build(n, n) { |i, j| i == j ? 1 : 0 }
  def nrows = @rows.size
  def ncols = @rows[0].size

  def [](r, c)
    @rows[r][c]
  end

  def []=(r, c, v)
    row = @rows[r]
    row[c] = v
  end

  def same_shape(b, op)
    unless nrows == b.nrows && ncols == b.ncols
      raise DimensionError.new("#{op}: #{nrows}x#{ncols} vs #{b.nrows}x#{b.ncols}", op)
    end
  end

  def +(b)
    same_shape(b, "+")
    Matrix.build(nrows, ncols) { |i, j| self[i, j] + b[i, j] }
  end

  def -(b)
    same_shape(b, "-")
    Matrix.build(nrows, ncols) { |i, j| self[i, j] - b[i, j] }
  end

  def *(b)
    case b
    in Matrix
      raise DimensionError.new("*: #{ncols} cols vs #{b.nrows} rows", "*") if ncols != b.nrows
      Matrix.build(nrows, b.ncols) do |i, j|
        sum = 0
        ncols.times { |k| sum += self[i, k] * b[k, j] }
        sum
      end
    in Integer | Float | Rational
      Matrix.build(nrows, ncols) { |i, j| self[i, j] * b }
    end
  end

  def **(n)
    result = Matrix.identity(nrows)
    base = self
    while n > 0
      result = result * base if n.odd?
      base = base * base
      n = n / 2
    end
    result
  end

  def transpose = Matrix.build(ncols, nrows) { |i, j| self[j, i] }

  def to_rational = Matrix.build(nrows, ncols) { |i, j| Rational(self[i, j], 1) }

  def determinant
    m = to_rational
    n = m.nrows
    det = Rational(1, 1)
    n.times do |col|
      pivot = (col...n).find { |r| m[r, col] != 0 }
      return Rational(0, 1) if !pivot    
      if pivot != col
        rows = m.rows
        rows[pivot], rows[col] = rows[col], rows[pivot]
        det *= -1
      end
      det *= m[col, col]
      ((col + 1)...n).each do |r|
        f = m[r, col] / m[col, col]
        (col...n).each { |c| m[r, c] = m[r, c] - f * m[col, c] }
      end
    end
    det
  end

  def inverse
    n = nrows
    aug = Matrix.build(n, 2 * n) { |i, j| j < n ? Rational(self[i, j], 1) : (j - n == i ? Rational(1, 1) : Rational(0, 1)) }
    n.times do |col|
      pivot = (col...n).find { |r| aug[r, col] != 0 }
      raise SingularError, "matrix is singular" if !pivot    
      rows = aug.rows
      rows[pivot], rows[col] = rows[col], rows[pivot]
      pv = aug[col, col]
      (2 * n).times { |c| aug[col, c] = aug[col, c] / pv }
      n.times do |r|
        next if r == col
        f = aug[r, col]
        (2 * n).times { |c| aug[r, c] = aug[r, c] - f * aug[col, c] }
      end
    end
    Matrix.build(n, n) { |i, j| aug[i, j + n] }
  end

  def cell_s(x)
    case x
    in Rational then x.denominator == 1 ? x.numerator.to_s : x.to_s
    in Integer then x.to_s
    in Float then format("%.2f", x)
    end
  end

  def to_s
    cells = @rows.map { |row| row.map { |x| cell_s(x) } }
    width = cells.flatten.map(&:size).max
    lines = cells.map { |row| "[ " + row.map { |s| s.rjust(width) }.join(" ") + " ]" }
    lines.join("\n")
  end
end

a = Matrix.new([[2, 1, 0], [1, 3, 1], [0, 1, 4]])
b = Matrix.new([[1, 0, 2], [0, 1, 0], [3, 0, 1]])

puts "A ="
puts a
puts "A + B ="
puts a + b
puts "A - B ="
puts a - b
puts "A * B ="
puts a * b
puts "A * 3 ="
puts a * 3
puts "A^T * 0.5 ="
puts a.transpose * 0.5
puts "det A = #{a.determinant}, det B = #{b.determinant}"
puts "det(A*B) = #{(a * b).determinant}"

inv = a.inverse
puts "inverse A ="
puts inv
puts "A * inverse A ="
puts a * inv

fib = Matrix.new([[1, 1], [1, 0]])
[1, 2, 10, 30, 60].each do |n|
  puts "fib(#{n}) = #{(fib ** n)[0, 1]}"
end

rect = Matrix.build(2, 3) { |i, j| i * 3 + j }
puts "R (2x3) ="
puts rect
puts "R * R^T ="
puts rect * rect.transpose

begin
  puts rect * rect
rescue DimensionError => e
  puts "error (#{e.op}): #{e.message}"
end
begin
  puts a + rect
rescue DimensionError => e
  puts "error (#{e.op}): #{e.message}"
end

sing = Matrix.new([[1, 2], [2, 4]])
puts "det singular = #{sing.determinant}"
begin
  sing.inverse
rescue SingularError => e
  puts "error: #{e.message}"
end

m = Matrix.identity(3)
m[0, 2] = 5
m[2, 0] += 7
puts "edited identity ="
puts m
puts "trace = #{(0...3).sum { |i| m[i, i] }}"
