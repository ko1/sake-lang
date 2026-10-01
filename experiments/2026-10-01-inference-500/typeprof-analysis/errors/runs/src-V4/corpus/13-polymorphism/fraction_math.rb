class BadFraction < StandardError
  attr_reader :text
  def initialize(message, text)
    super(message)
    @text = text
  end
end

class Frac
  include Comparable
  attr_reader :num, :den

  def initialize(num, den)
    @num = num
    @den = den
  end

  def self.of(n, d)
    raise ZeroDivisionError, "zero denominator" if d == 0
    g = n.gcd(d)
    g = -g if d < 0
    Frac.new(n / g, d / g)
  end

  def self.parse(s)
    m = s.strip.match(/\A(-?\d+)(?:\/(\d+))?\z/)
    raise BadFraction.new("cannot parse #{s.inspect}", s) if !m    
    d = m[2]
    of(m[1].to_i, d ? d.to_i : 1)
  end

  def lift(b) = b.is_a?(Integer) ? Frac.new(b, 1) : b

  def +(b)
    b = lift(b)
    Frac.of(@num * b.den + b.num * @den, @den * b.den)
  end
  def -(b)
    b = lift(b)
    Frac.of(@num * b.den - b.num * @den, @den * b.den)
  end
  def *(b)
    b = lift(b)
    Frac.of(@num * b.num, @den * b.den)
  end
  def /(b)
    b = lift(b)
    Frac.of(@num * b.den, @den * b.num)
  end
  def **(n) = Frac.of(@num ** n, @den ** n)
  def <=>(b)
    b = lift(b)
    (@num * b.den) <=> (b.num * @den)
  end

  def reciprocal = Frac.of(@den, @num)
  def floor = @num / @den
  def to_f = @num / (@den * 1.0)
  def to_s = @den == 1 ? @num.to_s : "#{@num}/#{@den}"

  def mixed
    whole = floor
    rest = self - whole
    return to_s if whole == 0 || rest.num == 0
    "#{whole} #{rest}"
  end

  def egyptian
    parts = []
    rest = self
    while rest.num > 0
      d = rest.den.ceildiv(rest.num)
      unit = Frac.new(1, d)
      parts << unit
      rest -= unit
    end
    parts
  end

  def continued
    terms = []
    cur = self
    while true
      f = cur.floor
      terms << f
      rest = cur - f
      break if rest.num == 0
      cur = rest.reciprocal
    end
    terms
  end
end

def harmonic(n) = (1..n).reduce(Frac.of(0, 1)) { |acc, k| acc + Frac.new(1, k) }

def farey(n)
  seen = []
  (1..n).each do |d|
    (0..d).each do |k|
      f = Frac.of(k, d)
      seen << f unless seen.include?(f)
    end
  end
  seen.sort
end

inputs = ["3/4", "-2/6", "7", "10/4", " 22/7 ", "5/0", "x/2", "355/113"]
fracs = []
inputs.each do |s|
  begin
    f = Frac.parse(s)
    fracs << f
    puts format("%-9s -> %-7s mixed %-8s %.5f", "'#{s}'", f, f.mixed, f.to_f)
  rescue BadFraction => e
    puts "'#{s}' -> error: #{e.message}"
  rescue ZeroDivisionError => e
    puts "'#{s}' -> error: #{e.message}"
  end
end

puts "sorted: #{fracs.sort.join(" < ")}"
puts "min #{fracs.min}, max #{fracs.max}"
total = fracs.reduce(Frac.of(0, 1)) { |acc, f| acc + f }
puts "sum: #{total} = #{total.mixed}"
product = fracs.reduce(Frac.of(1, 1)) { |acc, f| acc * f }
puts "product: #{product}"

a = Frac.of(3, 4)
b = Frac.of(5, 6)
puts "#{a} + #{b} = #{a + b}"
puts "#{a} - #{b} = #{a - b}"
puts "#{a} * #{b} = #{a * b}"
puts "#{a} / #{b} = #{a / b}"
puts "#{a} ^ 3 = #{a ** 3}"
puts "#{a} + 2 = #{a + 2}, #{a} * 4 = #{a * 4}"
puts "#{a} < #{b}: #{a < b}; #{a} == 6/8: #{a == Frac.of(6, 8)}; #{b} >= 1: #{b >= 1}"

puts "== egyptian =="
[Frac.of(4, 13), Frac.of(5, 6), Frac.of(7, 15)].each do |f|
  puts "#{f} = #{f.egyptian.join(" + ")}"
end

puts "== continued fractions =="
[Frac.of(355, 113), Frac.of(415, 93), Frac.of(-7, 3)].each do |f|
  puts "#{f} = [#{f.continued.join("; ")}]"
end

puts "== harmonic =="
[1, 2, 5, 10].each { |n| puts "H(#{n}) = #{harmonic(n)}" }
first_over_2 = (1..20).find { |n| harmonic(n) > 2 }
puts "first H(n) > 2: n = #{first_over_2}"

puts "== Farey F5 =="
puts farey(5).join(" ")
