class NotConverged < StandardError
  attr_reader :iterations

  def initialize(message, iterations)
    super(message)
    @iterations = iterations
  end
end

def mat_vec(a, v) = a.map { |row| row.zip(v).map { |x, y| x * y }.sum }
def dot(u, v) = u.zip(v).map { |x, y| x * y }.sum
def norm(v) = Math.sqrt(dot(v, v))
def scale(v, k) = v.map { |x| x * k }

def power_iteration(a, tol, max_iter)
  v = Array.new(a.size, 1.0)
  (1..max_iter).each do |it|
    w = mat_vec(a, v)
    v = scale(w, 1.0 / norm(w))
    av = mat_vec(a, v)
    lambda = dot(v, av)
    resid = norm(av.zip(v).map { |x, y| x - lambda * y })
    return { value: lambda, vector: v, iterations: it } if resid < tol
  end
  raise NotConverged.new("power iteration did not converge", max_iter)
end

def solve(a, b)
  n = a.size
  m = a.zip(b).map { |row, bi| row.dup << bi }
  (0...n).each do |c|
    p = (c...n).max_by { |r| m[r][c].abs }
    m[c], m[p] = m[p], m[c]
    ((c + 1)...n).each do |r|
      f = m[r][c] / m[c][c]
      (c..n).each { |k| m[r][k] -= f * m[c][k] }
    end
  end
  x = Array.new(n, 0.0)
  (n - 1).downto(0) do |i|
    s = m[i][n]
    ((i + 1)...n).each { |j| s -= m[i][j] * x[j] }
    x[i] = s / m[i][i]
  end
  x
end

def inverse_iteration(a, shift, iters)
  n = a.size
  shifted = (0...n).map { |i| (0...n).map { |j| a[i][j] - (i == j ? shift : 0.0) } }
  v = (0...n).map { |i| 1.0 + i * 0.1 }
  iters.times do
    w = solve(shifted, v)
    v = scale(w, 1.0 / norm(w))
  end
  [dot(v, mat_vec(a, v)), v]
end

def jacobi_eigenvalues(a)
  n = a.size
  m = a.map(&:dup)
  sweeps = 0
  loop do
    off = 0.0
    n.times { |i| n.times { |j| off += m[i][j] ** 2 if i != j } }
    break if off < 1e-20 || sweeps >= 50
    sweeps += 1
    (0...n).each do |p|
      ((p + 1)...n).each do |q|
        next if m[p][q].abs < 1e-30
        theta = (m[q][q] - m[p][p]) / (2.0 * m[p][q])
        t = (theta >= 0.0 ? 1.0 : -1.0) / (theta.abs + Math.sqrt(theta * theta + 1.0))
        c = 1.0 / Math.sqrt(t * t + 1.0)
        s = t * c
        n.times do |k|
          mkp = m[k][p]
          mkq = m[k][q]
          m[k][p] = c * mkp - s * mkq
          m[k][q] = s * mkp + c * mkq
        end
        n.times do |k|
          mpk = m[p][k]
          mqk = m[q][k]
          m[p][k] = c * mpk - s * mqk
          m[q][k] = s * mpk + c * mqk
        end
      end
    end
  end
  [(0...n).map { |i| m[i][i] }.sort, sweeps]
end

def symmetric?(a)
  (0...a.size).all? { |i| (0...i).all? { |j| a[i][j] == a[j][i] } }
end

def fmt(v) = v.map { |x| format("%8.5f", x) }.join(" ")

matrices = [
  ["symmetric 3x3", [[4.0, 1.0, 2.0], [1.0, 3.0, 0.0], [2.0, 0.0, 5.0]]],
  ["tridiagonal 5x5", (0...5).map { |i| (0...5).map { |j| i == j ? 2.0 : ((i - j).abs == 1 ? -1.0 : 0.0) } }],
  ["rotation-ish", [[0.0, -1.0], [1.0, 0.0]]]
]

matrices.each do |name, a|
  puts "== #{name}"
  begin
    r = power_iteration(a, 1e-9, 500)
    r => {value:, vector:, iterations:}
    puts format("  dominant eigenvalue %.8f after %d iterations", value, iterations)
    puts "  eigenvector #{fmt(vector)}"
    resid = norm(mat_vec(a, vector).zip(scale(vector, value)).map { |x, y| x - y })
    puts format("  |Av - lv| = %.2e", resid)
  rescue NotConverged => e
    puts "  #{e.message} (#{e.iterations} iterations)"
  end
  unless symmetric?(a)
    puts "  not symmetric: skipping Jacobi"
    next
  end
  eig, sweeps = jacobi_eigenvalues(a)
  puts "  jacobi (#{sweeps} sweeps): #{fmt(eig)}"
  smallest = eig.first
  val, _vec = inverse_iteration(a, smallest - 0.01, 8)
  puts format("  inverse iteration near %.4f -> %.8f", smallest - 0.01, val)
  trace = (0...a.size).sum { |i| a[i][i] }
  puts format("  trace %.6f vs sum of eigenvalues %.6f", trace, eig.sum)
end

n = 5
exact = (1..n).map { |k| 2.0 - 2.0 * Math.cos(k * Math::PI / (n + 1)) }
puts "exact tridiagonal eigenvalues: #{fmt(exact)}"
