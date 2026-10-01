class SingularError < StandardError
  attr_reader :step

  def initialize(message, step)
    super(message)
    @step = step
  end
end

class LU
  attr_reader :a, :perm, :sign

  def initialize(a, perm, sign)
    @a = a
    @perm = perm
    @sign = sign
  end

  def self.factor(m)
    n = m.size
    a = m.map(&:dup)
    perm = (0...n).to_a
    sign = 1
    (0...n).each do |k|
      best = k
      ((k + 1)...n).each { |i| best = i if a[i][k].abs > a[best][k].abs }
      raise SingularError.new("zero pivot", k) if a[best][k].abs < 1e-13
      if best != k
        a[k], a[best] = a[best], a[k]
        perm[k], perm[best] = perm[best], perm[k]
        sign = -sign
      end
      ((k + 1)...n).each do |i|
        a[i][k] /= a[k][k]
        f = a[i][k]
        ((k + 1)...n).each { |j| a[i][j] -= f * a[k][j] }
      end
    end
    new(a, perm, sign)
  end

  def size = @a.size

  def solve(b)
    n = size
    y = @perm.map { |p| b[p] }
    (0...n).each { |i| (0...i).each { |j| y[i] -= @a[i][j] * y[j] } }
    (n - 1).downto(0) do |i|
      ((i + 1)...n).each { |j| y[i] -= @a[i][j] * y[j] }
      y[i] /= @a[i][i]
    end
    y
  end

  def det = (0...size).reduce(@sign * 1.0) { |acc, i| acc * @a[i][i] }

  def inverse
    n = size
    cols = (0...n).map { |j| solve((0...n).map { |i| i == j ? 1.0 : 0.0 }) }
    (0...n).map { |i| (0...n).map { |j| cols[j][i] } }
  end

  def lower
    n = size
    (0...n).map { |i| (0...n).map { |j| j < i ? @a[i][j] : (i == j ? 1.0 : 0.0) } }
  end

  def upper
    n = size
    (0...n).map { |i| (0...n).map { |j| j >= i ? @a[i][j] : 0.0 } }
  end
end

def norm1(m)
  (0...m.size).map { |j| m.map { |row| row[j].abs }.sum }.max
end

def matmul(x, y)
  x.map { |row| (0...y[0].size).map { |j| (0...row.size).reduce(0.0) { |acc, k| acc + row[k] * y[k][j] } } }
end

def show(name, m)
  puts "#{name}:"
  m.each { |row| puts "  " + row.map { |x| format("%9.4f", x) }.join(" ") }
end

a = [
  [2.0, 1.0, 1.0, 0.0],
  [4.0, 3.0, 3.0, 1.0],
  [8.0, 7.0, 9.0, 5.0],
  [6.0, 7.0, 9.0, 8.0]
]

lu = LU.factor(a)
puts "permutation: #{lu.perm}, sign #{lu.sign}"
show("L", lu.lower)
show("U", lu.upper)
pa = lu.perm.map { |p| a[p] }
diff = matmul(lu.lower, lu.upper)
err = 0.0
diff.each_with_index { |row, i| row.each_with_index { |v, j| err = [err, (v - pa[i][j]).abs].max } }
puts format("max |LU - PA| = %.2e", err)
puts format("det(A) = %.6f", lu.det)

rhs_list = [[1.0, 2.0, 3.0, 4.0], [0.0, 0.0, 0.0, 1.0], [5.0, -1.0, 2.5, 0.0]]
rhs_list.each do |b|
  x = lu.solve(b)
  puts "solve #{b} -> [#{x.map { |v| format("%.6f", v) }.join(", ")}]"
end

inv = lu.inverse
show("inverse", inv)
cond = norm1(a) * norm1(inv)
puts format("condition number (1-norm) = %.3f", cond)

[4, 6, 8].each do |n|
  h = (0...n).map { |i| (0...n).map { |j| 1.0 / (i + j + 1) } }
  hl = LU.factor(h)
  puts format("hilbert %d: det=%.3e cond=%.3e", n, hl.det, norm1(h) * norm1(hl.inverse))
end

begin
  LU.factor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]])
rescue SingularError => e
  puts "singular: #{e.message} at step #{e.step}"
end
