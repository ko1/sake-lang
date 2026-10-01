# Polynomials with Integer or Rational coefficients, lowest degree first.
class Poly
  attr_reader :coeffs

  def initialize(coeffs)
    @coeffs = coeffs
  end

  def self.make(cs)
    out = cs.dup
    out.pop while out.size > 1 && out.last == 0
    out = [0] if out.empty?
    Poly.new(out)
  end

  def self.const(c) = Poly.new([c])
  def self.x = Poly.new([0, 1])
  def degree = @coeffs.size - 1
  def lead = @coeffs.last
  def zero? = degree == 0 && @coeffs[0] == 0
  def coef(i) = i < @coeffs.size ? @coeffs[i] : 0
  def ==(b) = b.is_a?(Poly) && @coeffs == b.coeffs

  def lift(b) = b.is_a?(Poly) ? b : Poly.const(b)

  def +(b)
    b = lift(b)
    n = [@coeffs.size, b.coeffs.size].max
    Poly.make((0...n).map { |i| coef(i) + b.coef(i) })
  end

  def -(b)
    b = lift(b)
    n = [@coeffs.size, b.coeffs.size].max
    Poly.make((0...n).map { |i| coef(i) - b.coef(i) })
  end

  def *(b)
    b = lift(b)
    bc = b.coeffs
    out = Array.new(@coeffs.size + bc.size - 1, 0)
    @coeffs.each_with_index do |ca, i|
      bc.each_with_index { |cb, j| out[i + j] += ca * cb }
    end
    Poly.make(out)
  end

  def **(n)
    result = Poly.const(1)
    n.times { result *= self }
    result
  end

  def divmod(b)
    raise ZeroDivisionError, "division by zero polynomial" if b.zero?
    q = Poly.const(0)
    r = Poly.make(@coeffs.map { |c| Rational(c, 1) })
    while !r.zero? && r.degree >= b.degree
      shift = r.degree - b.degree
      factor = r.lead / Rational(b.lead, 1)
      term_cs = Array.new(shift + 1, 0)
      term_cs[shift] = factor
      term = Poly.make(term_cs)
      q += term
      r -= term * b
    end
    [q, r]
  end

  def evaluate(x) = @coeffs.reverse.reduce(0) { |acc, c| acc * x + c }
  def compose(inner) = @coeffs.reverse.reduce(Poly.const(0)) { |acc, c| acc * inner + c }
  def derivative = Poly.make((1...@coeffs.size).map { |i| @coeffs[i] * i })

  def num_s(c)
    case c
    in Rational then c.denominator == 1 ? c.numerator.to_s : "(#{c})"
    in Integer then c.to_s
    end
  end

  def to_s
    return num_s(@coeffs[0]) if degree == 0
    parts = []
    degree.downto(0) do |i|
      c = @coeffs[i]
      next if c == 0
      neg = c < 0
      mag = neg ? -c : c
      body = if i == 0
        num_s(mag)
      else
        pre = mag == 1 ? "" : num_s(mag)
        pre + (i == 1 ? "x" : "x^#{i}")
      end
      if parts.empty?
        parts << (neg ? "-#{body}" : body)
      else
        parts << (neg ? "- #{body}" : "+ #{body}")
      end
    end
    parts.join(" ")
  end
end

x = Poly.x
p1 = x ** 2 * 3 - x * 2 + 1
p2 = x - 1
p3 = (x + 1) ** 3

puts "p1 = #{p1}"
puts "p2 = #{p2}"
puts "p3 = #{p3}"
puts "p1 + p2 = #{p1 + p2}"
puts "p1 - p1 = #{p1 - p1}"
puts "p1 * p2 = #{p1 * p2}"
puts "p3 + 5 = #{p3 + 5}"
puts "deg(p1 * p3) = #{(p1 * p3).degree}"

q, r = p3.divmod(p2)
puts "p3 / p2 = #{q} rem #{r}"
q2, r2 = p1.divmod(x * 2 + 1)
puts "p1 / (2x + 1) = #{q2} rem #{r2}"
check = q2 * (x * 2 + 1) + r2
puts "check: #{check} == p1? #{check == Poly.make(p1.coeffs.map { |c| Rational(c, 1) })}"

puts "p1' = #{p1.derivative}"
puts "p3'' = #{p3.derivative.derivative}"
puts "p1(p2) = #{p1.compose(p2)}"

puts "table:"
(-2..3).each do |v|
  puts format("  x=%2d p1=%4d p3=%4d", v, p1.evaluate(v), p3.evaluate(v))
end
puts "p1(1/2) = #{p1.evaluate(Rational(1, 2))}"
puts "p1(0.5) = #{p1.evaluate(0.5)}"

roots = (-10..10).select { |v| (x ** 3 - x * 7 - 6).evaluate(v) == 0 }
puts "integer roots of x^3 - 7x - 6: #{roots.join(", ")}"

begin
  p1.divmod(Poly.const(0))
rescue ZeroDivisionError => e
  puts "error: #{e.message}"
end
