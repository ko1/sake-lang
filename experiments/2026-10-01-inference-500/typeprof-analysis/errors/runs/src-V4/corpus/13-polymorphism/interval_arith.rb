class EmptyInterval < StandardError
  attr_reader :lo, :hi
  def initialize(message, lo, hi)
    super(message)
    @lo = lo
    @hi = hi
  end
end

class Interval
  attr_reader :lo, :hi

  def initialize(lo, hi)
    @lo = lo
    @hi = hi
  end

  def self.of(lo, hi)
    raise EmptyInterval.new("empty interval [#{lo}, #{hi}]", lo, hi) if lo > hi
    Interval.new(lo, hi)
  end

  def self.point(x) = Interval.new(x, x)
  def lift(b) = b.is_a?(Interval) ? b : Interval.point(b)

  def +(b)
    b = lift(b)
    Interval.new(@lo + b.lo, @hi + b.hi)
  end

  def -(b)
    b = lift(b)
    Interval.new(@lo - b.hi, @hi - b.lo)
  end

  def *(b)
    b = lift(b)
    ps = [@lo * b.lo, @lo * b.hi, @hi * b.lo, @hi * b.hi]
    Interval.new(ps.min, ps.max)
  end

  def /(b)
    b = lift(b)
    if b.contains?(0)
      raise ZeroDivisionError, "divisor #{b} contains zero"
    end
    self * Interval.new(1.0 / b.hi, 1.0 / b.lo)
  end

  def **(n)
    return Interval.new(1, 1) if n == 0
    if n.odd? || @lo >= 0
      Interval.new(@lo ** n, @hi ** n)
    elsif @hi <= 0
      Interval.new(@hi ** n, @lo ** n)
    else
      Interval.new(0, [@lo ** n, @hi ** n].max)
    end
  end

  def width = @hi - @lo
  def mid = (@lo + @hi) / 2.0
  def contains?(x) = @lo <= x && x <= @hi
  def overlaps?(b) = @lo <= b.hi && b.lo <= @hi

  def intersect(b)
    lo = [@lo, b.lo].max
    hi = [@hi, b.hi].min
    lo <= hi ? Interval.new(lo, hi) : nil
  end

  def hull(b) = Interval.new([@lo, b.lo].min, [@hi, b.hi].max)

  def to_s = "[#{num(@lo)}, #{num(@hi)}]"
  def num(x) = x.is_a?(Float) ? format("%.4g", x) : x.to_s
end

def merge_all(intervals)
  sorted = intervals.sort_by(&:lo)
  merged = []
  sorted.each do |iv|
    last = merged.last
    if last && last.overlaps?(iv)
      merged[-1] = last.hull(iv)
    else
      merged << iv
    end
  end
  merged
end

# f(x) = x^3 - 2x - 5 evaluated on intervals; also works on plain numbers.
def f(x) = x ** 3 - x * 2 - 5

def bisect_roots(iv, depth, out)
  y = f(iv)
  return out unless y.contains?(0)
  if depth == 0 || iv.width < 0.0001
    out << iv
    return out
  end
  m = iv.mid
  bisect_roots(Interval.new(iv.lo, m), depth - 1, out)
  bisect_roots(Interval.new(m, iv.hi), depth - 1, out)
  out
end

a = Interval.of(1, 3)
b = Interval.of(-2, 4)
puts "a = #{a}, b = #{b}"
puts "a + b = #{a + b}"
puts "a - b = #{a - b}"
puts "a * b = #{a * b}"
puts "a + 10 = #{a + 10}, a * -1 = #{a * -1}"
puts "b ** 2 = #{b ** 2}, b ** 3 = #{b ** 3}"
puts "a / Interval[2, 4] = #{a / Interval.of(2, 4)}"
begin
  puts a / b
rescue ZeroDivisionError => e
  puts "error: #{e.message}"
end
begin
  Interval.of(5, 1)
rescue EmptyInterval => e
  puts "error: #{e.message}"
end

inter = a.intersect(Interval.of(2, 8))
puts "a & [2, 8] = #{inter}" if inter
none = a.intersect(Interval.of(5, 6))
puts "a & [5, 6] = #{!none     ? "empty" : none}"

puts "== dependency problem =="
x = Interval.of(0, 1)
puts "x - x = #{x - x} (width #{(x - x).width})"
puts "x * (1 - x) on [0, 1] = #{x * (Interval.point(1) - x)}"

puts "== bookings =="
bookings = [Interval.of(9, 10), Interval.of(13, 15), Interval.of(9.5, 11), Interval.of(14, 16),
            Interval.of(18, 19), Interval.of(11, 12), Interval.of(15.5, 17)]
busy = merge_all(bookings)
puts "busy: #{busy.join(" ")}"
total = busy.sum(&:width)
puts "busy hours: #{total}"
free = []
busy.each_cons(2) { |pair| free << Interval.new(pair[0].hi, pair[1].lo) }
puts "gaps: #{free.join(" ")}"
longest = free.max_by(&:width)
puts "longest gap: #{longest}" if longest

puts "== root of x^3 - 2x - 5 =="
puts "f(2) = #{f(2)}, f(3) = #{f(3)}, f(2.5) = #{f(2.5)}"
puts "f([1, 3]) = #{f(Interval.of(1.0, 3.0))}"
roots = bisect_roots(Interval.of(-3.0, 3.0), 20, [])
puts "candidate boxes: #{roots.size}"
unless roots.empty?
  hull = roots.reduce(roots[0]) { |acc, iv| acc.hull(iv) }
  puts "root enclosure: #{hull}"
  puts format("root ~ %.5f", hull.mid)
end
