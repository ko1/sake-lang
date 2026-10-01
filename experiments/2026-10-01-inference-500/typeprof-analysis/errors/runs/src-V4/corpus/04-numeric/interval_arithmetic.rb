class DivideByZeroInterval < StandardError
  attr_reader :divisor

  def initialize(message, divisor)
    super(message)
    @divisor = divisor
  end
end

class Interval
  attr_reader :lo, :hi

  def initialize(lo, hi)
    @lo = lo
    @hi = hi
  end

  def self.point(x) = new(x, x)

  def self.lift(v)
    case v
    in Interval then v
    in Float then point(v)
    in Integer then point(v.to_f)
    end
  end

  def +(b)
    o = Interval.lift(b)
    Interval.new(@lo + o.lo, @hi + o.hi)
  end

  def -(b)
    o = Interval.lift(b)
    Interval.new(@lo - o.hi, @hi - o.lo)
  end

  def *(b)
    o = Interval.lift(b)
    ps = [@lo * o.lo, @lo * o.hi, @hi * o.lo, @hi * o.hi]
    Interval.new(ps.min, ps.max)
  end

  def /(b)
    o = Interval.lift(b)
    raise DivideByZeroInterval.new("divisor contains zero", o) if o.lo <= 0.0 && o.hi >= 0.0
    self * Interval.new(1.0 / o.hi, 1.0 / o.lo)
  end

  def sqr
    return Interval.new(@lo * @lo, @hi * @hi) if @lo >= 0.0
    return Interval.new(@hi * @hi, @lo * @lo) if @hi <= 0.0
    Interval.new(0.0, [@lo * @lo, @hi * @hi].max)
  end

  def exp = Interval.new(Math.exp(@lo), Math.exp(@hi))
  def width = @hi - @lo
  def mid = (@lo + @hi) / 2.0
  def contains?(x) = @lo <= x && x <= @hi
  def split = [Interval.new(@lo, mid), Interval.new(mid, @hi)]
  def to_s = format("[%.6f, %.6f]", @lo, @hi)
end

# f(x) = x^4 - 3x^2 + x, written once with operations that work on Float and Interval
def poly_f(x, sq) = sq * sq - sq * 3.0 + x

def f_float(x) = poly_f(x, x * x)
def f_interval(iv) = poly_f(iv, iv.sqr)

def global_min(domain, tol)
  best_upper = f_float(domain.mid)
  queue = [domain]
  boxes = 0
  pruned = 0
  result = domain
  until queue.empty?
    box = queue.shift
    boxes += 1
    range = f_interval(box)
    if range.lo > best_upper
      pruned += 1
      next
    end
    m = box.mid
    fm = f_float(m)
    if fm < best_upper
      best_upper = fm
      result = box
    end
    queue.push(*box.split) if box.width > tol
  end
  { value: best_upper, box: result, boxes: boxes, pruned: pruned }
end

def roots_in(domain, tol)
  found = []
  stack = [domain]
  while (box = stack.pop)
    r = f_interval(box)
    next unless r.contains?(0.0)
    if box.width < tol
      last = found.last
      if !last     || box.lo - last.hi > tol
        found << box
      else
        found[-1] = Interval.new(last.lo, box.hi)
      end
      next
    end
    left, right = box.split
    stack.push(right, left)
  end
  found
end

a = Interval.new(1.0, 2.0)
b = Interval.new(-0.5, 3.0)
puts "a = #{a}, b = #{b}"
puts "a + b = #{a + b}"
puts "a - b = #{a - b}"
puts "a * b = #{a * b}"
puts "a / a = #{a / a}"
puts "a + 1 = #{a + 1}, a * 0.5 = #{a * 0.5}"
puts "sqr(b) = #{b.sqr} but b * b = #{b * b}"

begin
  puts a / b
rescue DivideByZeroInterval => e
  puts "a / b: #{e.message} #{e.divisor}"
end

x = Interval.new(0.9, 1.1)
puts "f over #{x} = #{f_interval(x)}"
samples = (0..20).map { |i| f_float(0.9 + i * 0.01) }
puts format("sampled range: [%.6f, %.6f]", samples.min, samples.max)

res = global_min(Interval.new(-3.0, 3.0), 1e-4)
res => {value:, box:, boxes:, pruned:}
puts format("global minimum ~ %.8f in %s (%d boxes, %d pruned)", value, box, boxes, pruned)

rs = roots_in(Interval.new(-3.0, 3.0), 1e-7)
puts "root enclosures:"
rs.each { |r| puts "  #{r} width #{format("%.1e", r.width)}" }

growth = Interval.new(1.0, 1.0)
rate = Interval.new(1.04, 1.06)
10.times { growth *= rate }
puts "10 years at 4-6%: #{growth}"
