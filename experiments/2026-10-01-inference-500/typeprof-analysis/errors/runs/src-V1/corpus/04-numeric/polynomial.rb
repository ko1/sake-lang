class Poly
  attr_reader :coeffs

  def initialize(coeffs)
    @coeffs = coeffs
  end

  def self.make(cs)
    trimmed = cs.dup
    trimmed.pop while trimmed.size > 1 && trimmed.last.abs < 1e-12
    new(trimmed)
  end

  def degree = @coeffs.size - 1
  def coef(i) = @coeffs.fetch(i, 0.0)

  def +(b)
    n = [@coeffs.size, b.coeffs.size].max
    Poly.make((0...n).map { |i| coef(i) + b.coef(i) })
  end

  def -(b)
    n = [@coeffs.size, b.coeffs.size].max
    Poly.make((0...n).map { |i| coef(i) - b.coef(i) })
  end

  def *(b)
    case b
    in Float then Poly.make(@coeffs.map { |c| c * b })
    in Poly
      out = Array.new(degree + b.degree + 1, 0.0)
      @coeffs.each_with_index do |ca, i|
        b.coeffs.each_with_index { |cb, j| out[i + j] += ca * cb }
      end
      Poly.make(out)
    end
  end

  def at(x) = @coeffs.reverse.reduce(0.0) { |acc, c| acc * x + c }

  def derivative
    return Poly.make([0.0]) if degree == 0
    Poly.make((1..degree).map { |i| @coeffs[i] * i })
  end

  def divmod(b)
    rem = @coeffs.dup
    db = b.degree
    lead = b.coeffs.last
    return [Poly.make([0.0]), self] if degree < db
    q = Array.new(degree - db + 1, 0.0)
    (degree - db).downto(0) do |k|
      factor = rem[k + db] / lead
      q[k] = factor
      (0..db).each { |j| rem[k + j] -= factor * b.coeffs[j] }
    end
    [Poly.make(q), Poly.make(rem.take([db, 1].max))]
  end

  def to_s
    terms = []
    degree.downto(0) do |i|
      c = @coeffs[i]
      next if c == 0.0 && degree > 0
      mag = format("%g", c.abs)
      body = case i
             in 0 then mag
             in 1 then mag == "1" ? "x" : "#{mag}x"
             else mag == "1" ? "x^#{i}" : "#{mag}x^#{i}"
             end
      sign = c < 0.0 ? "-" : "+"
      if terms.empty?
        terms << (c < 0.0 ? "-#{body}" : body)
      else
        terms << "#{sign} #{body}"
      end
    end
    terms.join(" ")
  end
end

def from_roots(roots) = roots.reduce(Poly.make([1.0])) { |acc, r| acc * Poly.make([-r, 1.0]) }

def newton_root(p, x0)
  d = p.derivative
  x = x0
  100.times do
    fx = p.at(x)
    dx = d.at(x)
    return nil if dx == 0.0
    step = fx / dx
    x -= step
    return x if step.abs < 1e-13
  end
  nil
end

def real_roots(p)
  roots = []
  q = p
  while q.degree > 0
    r = newton_root(q, 0.5)
    break if r.nil?
    r = newton_root(p, r) || r
    roots << r
    q, _rem = q.divmod(Poly.make([-r, 1.0]))
  end
  [roots.sort, q]
end

p1 = Poly.make([1.0, -3.0, 0.0, 2.0])
p2 = Poly.make([-1.0, 1.0])
puts "p1 = #{p1}"
puts "p2 = #{p2}"
puts "p1 + p2 = #{p1 + p2}"
puts "p1 - p1 = #{p1 - p1}"
puts "p1 * p2 = #{p1 * p2}"
puts "p1 * 0.5 = #{p1 * 0.5}"
puts "p1' = #{p1.derivative}, p1'' = #{p1.derivative.derivative}"
q, r = p1.divmod(p2)
puts "p1 / p2 = #{q} remainder #{r}"
puts format("p1(2.5) = %.4f", p1.at(2.5))

w = from_roots([1.0, 2.0, 3.0, 4.0, 5.0])
puts "w = #{w}"
roots, _rest = real_roots(w)
puts "roots of w: #{roots.map { |x| format("%.10f", x) }.join(", ")}"

perturbed = w + Poly.make([0.0, 0.0, 0.0, 0.0, 1e-4])
proots, _prest = real_roots(perturbed)
puts "after +1e-4 x^4: #{proots.map { |x| format("%.6f", x) }.join(", ")}"

mixed = Poly.make([2.0, 0.0, 1.0]) * Poly.make([-3.0, 1.0])
mroots, mrest = real_roots(mixed)
puts "#{mixed}: real roots #{mroots.map { |x| format("%.6f", x) }.join(", ")}; leftover #{mrest}"

cheb = [Poly.make([1.0]), Poly.make([0.0, 1.0])]
(2..6).each do |n|
  cheb << Poly.make([0.0, 2.0]) * cheb[n - 1] - cheb[n - 2]
end
cheb.each_with_index { |t, n| puts "T#{n} = #{t}" }
x = 0.3
puts format("T6(0.3) = %.8f, cos(6 acos 0.3) = %.8f", cheb[6].at(x), Math.cos(6.0 * Math.atan2(Math.sqrt(1.0 - x * x), x)))
