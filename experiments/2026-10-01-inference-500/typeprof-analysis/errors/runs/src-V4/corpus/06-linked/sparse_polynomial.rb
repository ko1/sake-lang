class Term
  attr_accessor :coef, :exp, :next

  def initialize(coef, exp, nxt)
    @coef = coef
    @exp = exp
    @next = nxt
  end
end

class Poly
  attr_reader :terms

  def self.from_pairs(pairs)
    result = Poly.new
    pairs.each { |c, e| result.add_term!(c, e) }
    result
  end

  def initialize
    @terms = nil
  end

  def add_term!(coef, exp)
    return self if coef == 0
    prev = nil
    cur = @terms
    while cur && cur.exp > exp
      prev = cur
      cur = cur.next
    end
    if cur && cur.exp == exp
      sum = cur.coef + coef
      if sum == 0
        prev ? prev.next = cur.next : @terms = cur.next
      else
        cur.coef = sum
      end
    else
      fresh = Term.new(coef, exp, cur)
      prev ? prev.next = fresh : @terms = fresh
    end
    self
  end

  def each_term
    t = @terms
    while t
      yield t.coef, t.exp
      t = t.next
    end
  end

  def +(other)
    out = Poly.new
    each_term { |c, e| out.add_term!(c, e) }
    other.each_term { |c, e| out.add_term!(c, e) }
    out
  end

  def -(other)
    out = Poly.new
    each_term { |c, e| out.add_term!(c, e) }
    other.each_term { |c, e| out.add_term!(-c, e) }
    out
  end

  def *(other)
    out = Poly.new
    each_term do |c1, e1|
      other.each_term { |c2, e2| out.add_term!(c1 * c2, e1 + e2) }
    end
    out
  end

  def degree = @terms ? @terms.exp : 0

  def eval(x)
    total = 0
    each_term { |c, e| total += c * x**e }
    total
  end

  def derivative
    out = Poly.new
    each_term { |c, e| out.add_term!(c * e, e - 1) if e > 0 }
    out
  end

  def power(n)
    result = Poly.from_pairs([[1, 0]])
    n.times { result *= self }
    result
  end

  def to_s
    return "0" if !@terms    
    s = ""
    each_term do |c, e|
      sign = c < 0 ? "-" : "+"
      mag = c.abs.to_s
      body = if e == 0
        mag
      elsif e == 1
        (mag == "1" ? "" : mag) + "x"
      else
        (mag == "1" ? "" : mag) + "x^#{e}"
      end
      s = s.empty? ? (sign == "-" ? "-" : "") + body : s + " #{sign} " + body
    end
    s
  end
end

p1 = Poly.from_pairs([[3, 2], [-2, 1], [5, 0]])
p2 = Poly.from_pairs([[1, 1], [-1, 0]])
p3 = Poly.from_pairs([[1, 3], [2, 3], [-3, 3], [4, 0]])
puts "p1 = #{p1}"
puts "p2 = #{p2}"
puts "p3 = #{p3} (degree #{p3.degree})"
puts "p1 + p2 = #{p1 + p2}"
puts "p1 - p1 = #{p1 - p1}"
puts "p1 * p2 = #{p1 * p2}"
puts "(p1 * p2)' = #{(p1 * p2).derivative}"
puts "p2^5 = #{p2.power(5)}"
[-2, 0, 1, 3].each do |x|
  puts format("x=%2d  p1=%4d  p1*p2=%5d  p2^5=%6d", x, p1.eval(x), (p1 * p2).eval(x), p2.power(5).eval(x))
end

rational = Poly.from_pairs([[1/2r, 2], [1/3r, 0]])
puts "r = #{rational}, r(3) = #{rational.eval(3)}"
sum = Poly.new
(1..6).each { |k| sum += Poly.from_pairs([[k, k % 3]]) }
puts "sum of k*x^(k%3), k=1..6: #{sum}"
