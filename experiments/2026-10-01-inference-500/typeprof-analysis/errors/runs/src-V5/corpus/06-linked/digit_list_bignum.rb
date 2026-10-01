class Digit
  attr_accessor :d, :next

  def initialize(d, nxt)
    @d = d
    @next = nxt
  end
end

class BigNat
  include Comparable
  attr_reader :low

  def self.parse(s)
    low = nil
    s.each_char do |c|
      raise ArgumentError, "not a digit: #{c.inspect}" unless c.match?(/\d/)
      low = Digit.new(c.to_i, low)
    end
    BigNat.new(trim(low))
  end

  def self.from_int(n) = parse(n.to_s)

  def self.trim(low)
    digits = []
    node = low
    while node
      digits << node.d
      node = node.next
    end
    digits.pop while digits.size > 1 && digits.last == 0
    build(digits)
  end

  def self.build(digits_low_first)
    head = nil
    digits_low_first.reverse_each { |d| head = Digit.new(d, head) }
    head
  end

  def initialize(low)
    @low = low
  end

  def +(other)
    x = @low
    y = other.low
    carry = 0
    out = []
    while x || y || carry > 0
      s = carry
      if x
        s += x.d
        x = x.next
      end
      if y
        s += y.d
        y = y.next
      end
      out << s % 10
      carry = s / 10
    end
    BigNat.new(BigNat.build(out))
  end

  def scale(k, shift)
    out = [0] * shift
    carry = 0
    x = @low
    while x || carry > 0
      s = carry
      if x
        s += x.d * k
        x = x.next
      end
      out << s % 10
      carry = s / 10
    end
    BigNat.new(BigNat.trim(BigNat.build(out)))
  end

  def *(other)
    total = BigNat.from_int(0)
    shift = 0
    y = other.low
    while y
      total += scale(y.d, shift)
      y = y.next
      shift += 1
    end
    total
  end

  def length
    n = 0
    x = @low
    while x
      n += 1
      x = x.next
    end
    n
  end

  def <=>(other)
    la = length
    lb = other.length
    return la <=> lb if la != lb
    result = 0
    x = @low
    y = other.low
    while x && y
      c = x.d <=> y.d
      result = c if c != 0
      x = x.next
      y = y.next
    end
    result
  end

  def to_s
    s = +""
    x = @low
    while x
      s.prepend(x.d.to_s)
      x = x.next
    end
    s
  end
end

def factorial(n)
  acc = BigNat.from_int(1)
  (2..n).each { |k| acc *= BigNat.from_int(k) }
  acc
end

a = BigNat.parse("987654321987654321")
b = BigNat.parse("123456789123456789")
puts "a + b = #{a + b}"
puts "a * b = #{a * b}"
puts "check   #{987654321987654321 * 123456789123456789}"
puts "a > b: #{a > b}, b < a: #{b < a}, a == a': #{a == BigNat.parse("000987654321987654321")}"
puts "00042 -> #{BigNat.parse("00042")} (#{BigNat.parse("00042").length} digits)"
puts "0 * a = #{BigNat.from_int(0) * a}"

f30 = factorial(30)
puts "30! = #{f30}"
puts "matches Integer: #{f30.to_s == (1..30).reduce(1) { |p, k| p * k }.to_s}"
fib_a = BigNat.from_int(0)
fib_b = BigNat.from_int(1)
99.times do
  fib_a, fib_b = fib_b, fib_a + fib_b
end
puts "fib(100) = #{fib_b}"
digit_sum = f30.to_s.chars.sum(&:to_i)
puts "digit sum of 30! = #{digit_sum}"
nums = %w[31415926535 2718281828 31415926536 999 1000].map { BigNat.parse(it) }
puts "sorted: #{nums.sort.map(&:to_s).join(" ")}"
puts "max: #{nums.max}"
begin
  BigNat.parse("12a4")
rescue ArgumentError => e
  puts "error: #{e.message}"
end
