# A RangeSet of Integers stored as sorted, disjoint inclusive Ranges, with | & - operators; used to track
# which ticket numbers were sold, refunded, and scanned.

class RangeSet
  attr_reader :ranges

  def initialize(ranges)
    @ranges = ranges
  end

  def self.empty = new([])

  def self.of(nums)
    s = new([])
    nums.each { |n| s.add(n..n) }
    s
  end

  def add(r)
    lo = r.begin
    hi = r.end
    keep = []
    @ranges.each do |x|
      if x.end < lo - 1 || x.begin > hi + 1
        keep << x
      else
        lo = [lo, x.begin].min
        hi = [hi, x.end].max
      end
    end
    keep << (lo..hi)
    @ranges = keep.sort_by(&:begin)
    self
  end

  def remove(r)
    out = []
    @ranges.each do |x|
      unless x.overlap?(r)
        out << x
        next
      end
      out << (x.begin..(r.begin - 1)) if x.begin < r.begin
      out << ((r.end + 1)..x.end) if x.end > r.end
    end
    @ranges = out
    self
  end

  def include?(n) = @ranges.any? { |x| x.cover?(n) }

  def size = @ranges.sum(&:size)

  def |(other)
    out = RangeSet.new(@ranges.dup)
    other.ranges.each { |x| out.add(x) }
    out
  end

  def &(other)
    out = []
    @ranges.each do |x|
      other.ranges.each do |y|
        lo = [x.begin, y.begin].max
        hi = [x.end, y.end].min
        out << (lo..hi) if lo <= hi
      end
    end
    RangeSet.new(out)
  end

  def -(other) = other.ranges.reduce(RangeSet.new(@ranges.dup)) { |acc, r| acc.remove(r) }

  def gaps(within) = RangeSet.new([within]) - self

  def to_s
    parts = @ranges.map { |x| x.begin == x.end ? x.begin.to_s : "#{x.begin}-#{x.end}" }
    "{#{parts.join(",")}}"
  end
end

sold = RangeSet.empty
[1..20, 41..60, 21..25, 100..100, 61..70, 30..35].each { |r| sold.add(r) }
puts "sold:     #{sold} (#{sold.size} tickets)"

refunded = RangeSet.of([5, 6, 7, 33, 100, 64])
puts "refunded: #{refunded}"
valid = sold - refunded
puts "valid:    #{valid} (#{valid.size})"

scanned = RangeSet.of([1, 2, 3, 4, 5, 8, 9, 10, 44, 45, 46, 99, 100, 101])
puts "scanned:  #{scanned}"
ok = valid & scanned
puts "admitted: #{ok} (#{ok.size})"
bad = scanned - valid
puts "rejected: #{bad}"
puts "no-shows: #{(valid - scanned).size}"

unsold = sold.gaps(1..120)
puts "unsold in 1-120: #{unsold}"
largest = unsold.ranges.max_by(&:size)
puts "largest unsold block: #{largest.begin}-#{largest.end}"
everything = sold | unsold
puts "sold | unsold covers 1-120? #{everything.size == 120 && everything.ranges.size == 1}"

[7, 22, 36, 100, 120].each do |n|
  state = if valid.include?(n)
    "valid"
  elsif refunded.include?(n)
    "refunded"
  elsif sold.include?(n)
    "sold?"
  else
    "unsold"
  end
  puts "ticket #{n}: #{state}"
end

seen = Set[]
dupes = [3, 9, 3, 44, 9, 9, 70].select { |n| seen.add?(n).nil? }
puts "double scans: #{dupes.uniq.join(", ")}"
blocks = valid.ranges.map(&:size)
puts "valid block sizes: #{blocks.join(" ")}; singles: #{blocks.count(1)}"
