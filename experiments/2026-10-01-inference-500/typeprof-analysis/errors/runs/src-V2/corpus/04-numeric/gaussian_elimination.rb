class SingularMatrix < StandardError
  attr_reader :column

  def initialize(message, column)
    super(message)
    @column = column
  end
end

def copy_rows(a) = a.map(&:dup)

def solve(a, b)
  n = a.size
  m = copy_rows(a)
  rhs = b.dup
  swaps = 0
  (0...n).each do |col|
    pivot = (col...n).max_by { |r| m[r][col].abs }
    raise SingularMatrix.new("matrix is singular", col) if m[pivot][col].abs < 1e-12
    if pivot != col
      m[col], m[pivot] = m[pivot], m[col]
      rhs[col], rhs[pivot] = rhs[pivot], rhs[col]
      swaps += 1
    end
    ((col + 1)...n).each do |r|
      factor = m[r][col] / m[col][col]
      next if factor == 0.0
      (col...n).each { |c| m[r][c] -= factor * m[col][c] }
      rhs[r] -= factor * rhs[col]
    end
  end
  x = Array.new(n, 0.0)
  (n - 1).downto(0) do |i|
    s = rhs[i]
    ((i + 1)...n).each { |j| s -= m[i][j] * x[j] }
    x[i] = s / m[i][i]
  end
  det = (0...n).reduce(1.0) { |acc, i| acc * m[i][i] }
  det = -det if swaps.odd?
  { x: x, det: det, swaps: swaps }
end

def inverse(a)
  n = a.size
  aug = (0...n).map do |i|
    a[i].dup + (0...n).map { |j| i == j ? 1.0 : 0.0 }
  end
  (0...n).each do |col|
    pivot = (col...n).max_by { |r| aug[r][col].abs }
    raise SingularMatrix.new("cannot invert", col) if aug[pivot][col].abs < 1e-12
    aug[col], aug[pivot] = aug[pivot], aug[col]
    p = aug[col][col]
    aug[col] = aug[col].map { |v| v / p }
    (0...n).each do |r|
      next if r == col
      f = aug[r][col]
      aug[r] = aug[r].each_with_index.map { |v, c| v - f * aug[col][c] }
    end
  end
  aug.map { |row| row.drop(n) }
end

def mat_vec(a, x) = a.map { |row| row.zip(x).sum { |p, q| p * q } }

def residual(a, x, b)
  mat_vec(a, x).zip(b).map { |ax, bi| (ax - bi).abs }.max
end

def fmt_vec(v) = "[" + v.map { |e| format("%.6f", e) }.join(", ") + "]"

systems = [
  ["3x3 well-conditioned",
   [[2.0, 1.0, -1.0], [-3.0, -1.0, 2.0], [-2.0, 1.0, 2.0]],
   [8.0, -11.0, -3.0]],
  ["needs pivoting",
   [[0.0, 2.0, 1.0], [1.0, -2.0, -3.0], [-1.0, 1.0, 2.0]],
   [-8.0, 0.0, 3.0]],
  ["4x4 circuit",
   [[10.0, -2.0, 0.0, -3.0], [-2.0, 8.0, -1.0, 0.0], [0.0, -1.0, 6.0, -2.0], [-3.0, 0.0, -2.0, 9.0]],
   [12.0, 0.0, 5.0, -4.0]],
  ["singular",
   [[1.0, 2.0, 3.0], [2.0, 4.0, 6.0], [1.0, 0.0, 1.0]],
   [1.0, 2.0, 3.0]]
]

systems.each do |name, a, b|
  puts "== #{name}"
  begin
    res = solve(a, b)
    res => {x:, det:, swaps:}
    puts "  x = #{fmt_vec(x)}"
    puts format("  det = %.4f (row swaps: %d), residual = %.2e", det, swaps, residual(a, x, b))
    inv = inverse(a)
    prod = a.map { |row| (0...a.size).map { |j| row.each_with_index.reduce(0.0) { |acc, (v, k)| acc + v * inv[k][j] } } }
    off = 0.0
    prod.each_with_index do |row, i|
      row.each_with_index { |v, j| off = [off, (v - (i == j ? 1.0 : 0.0)).abs].max }
    end
    puts format("  |A * inv(A) - I|max = %.2e", off)
    puts "  inv row 0 = #{fmt_vec(inv[0])}"
  rescue SingularMatrix => e
    puts "  #{e.message} at column #{e.column}"
  end
end

# Hilbert matrices: watch the residual vs. the error grow
[3, 5, 7, 9].each do |n|
  h = (0...n).map { |i| (0...n).map { |j| 1.0 / (i + j + 1) } }
  ones = Array.new(n, 1.0)
  b = mat_vec(h, ones)
  x = solve(h, b)[:x]
  err = x.map { |v| (v - 1.0).abs }.max
  puts format("hilbert n=%d residual=%.2e error=%.2e", n, residual(h, x, b), err)
end
