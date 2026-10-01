class DimensionError < StandardError
  attr_reader :left, :right

  def initialize(message, left, right)
    super(message)
    @left = left
    @right = right
  end
end

class Matrix
  attr_reader :rows, :cols, :data

  def initialize(rows, cols, data)
    @rows = rows
    @cols = cols
    @data = data
  end

  def self.zeros(r, c) = new(r, c, Array.new(r * c, 0.0))

  def self.identity(n)
    m = zeros(n, n)
    n.times { |i| m[i, i] = 1.0 }
    m
  end

  def self.from_rows(rows)
    new(rows.size, rows[0].size, rows.flatten)
  end

  def [](i, j)
    @data[i * @cols + j]
  end

  def []=(i, j, v)
    @data[i * @cols + j] = v
  end

  def shape = "#{@rows}x#{@cols}"

  def check_same(b)
    if @rows != b.rows || @cols != b.cols
      raise DimensionError.new("shape mismatch", shape, b.shape)
    end
  end

  def +(b)
    check_same(b)
    Matrix.new(@rows, @cols, @data.zip(b.data).map { |x, y| x + y })
  end

  def -(b)
    check_same(b)
    Matrix.new(@rows, @cols, @data.zip(b.data).map { |x, y| x - y })
  end

  def *(b)
    case b
    in Float | Integer
      Matrix.new(@rows, @cols, @data.map { |x| x * b })
    in Matrix
      raise DimensionError.new("inner dimensions differ", shape, b.shape) if @cols != b.rows
      out = Matrix.zeros(@rows, b.cols)
      @rows.times do |i|
        b.cols.times do |j|
          s = 0.0
          @cols.times { |k| s += self[i, k] * b[k, j] }
          out[i, j] = s
        end
      end
      out
    end
  end

  def transpose
    t = Matrix.zeros(@cols, @rows)
    @rows.times { |i| @cols.times { |j| t[j, i] = self[i, j] } }
    t
  end

  def trace = (0...@rows).sum { |i| self[i, i] }

  def minor(skip_r, skip_c)
    rows = []
    @rows.times do |i|
      next if i == skip_r
      row = []
      @cols.times { |j| row << self[i, j] if j != skip_c }
      rows << row
    end
    Matrix.from_rows(rows)
  end

  def det
    raise DimensionError.new("determinant needs a square matrix", shape, shape) if @rows != @cols
    return self[0, 0] if @rows == 1
    return self[0, 0] * self[1, 1] - self[0, 1] * self[1, 0] if @rows == 2
    total = 0.0
    @cols.times do |j|
      sign = j.even? ? 1.0 : -1.0
      total += sign * self[0, j] * minor(0, j).det
    end
    total
  end

  def power(n)
    result = Matrix.identity(@rows)
    base = self
    while n > 0
      result = result * base if n.odd?
      base = base * base
      n /= 2
    end
    result
  end

  def frobenius = Math.sqrt(@data.sum { |x| x * x })

  def to_s
    (0...@rows).map do |i|
      cells = (0...@cols).map { |j| format("%9.3f", self[i, j]) }
      "[" + cells.join(" ") + " ]"
    end.join("\n")
  end
end

a = Matrix.from_rows([[2.0, -1.0, 0.0], [-1.0, 2.0, -1.0], [0.0, -1.0, 2.0]])
b = Matrix.from_rows([[1.0, 2.0], [0.5, -1.0], [3.0, 0.25]])

puts "A ="
puts a
puts "A * B ="
puts a * b
puts "B^T * B ="
puts b.transpose * b
puts "2A - I ="
puts a * 2 - Matrix.identity(3)
puts format("trace(A)=%.3f det(A)=%.3f |A|_F=%.4f", a.trace, a.det, a.frobenius)

r = Matrix.from_rows([[0.0, -1.0], [1.0, 0.0]])
puts "rotation^4 is identity: #{(r.power(4) - Matrix.identity(2)).frobenius < 1e-12}"
fib = Matrix.from_rows([[1.0, 1.0], [1.0, 0.0]])
puts format("fib(30) via matrix power: %.0f", fib.power(30)[0, 1])

h = Matrix.zeros(4, 4)
4.times { |i| 4.times { |j| h[i, j] = 1.0 / (i + j + 1) } }
puts format("det(Hilbert 4) = %.6e", h.det)
h[3, 3] += 0.001
puts format("after perturbing: %.6e", h.det)

tests = [[a, b], [b, a], [b, b]]
tests.each do |x, y|
  begin
    s = x + y
    puts "sum shape #{s.shape}"
  rescue DimensionError => e
    puts "cannot add: #{e.message} (#{e.left} vs #{e.right})"
  end
end

begin
  b * b
rescue DimensionError => e
  puts "cannot multiply: #{e.message} (#{e.left} vs #{e.right})"
end
