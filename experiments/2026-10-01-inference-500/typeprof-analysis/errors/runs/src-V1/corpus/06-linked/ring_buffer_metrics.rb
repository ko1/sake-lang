class BufferFull < StandardError
  attr_reader :capacity

  def initialize(message, capacity)
    super(message)
    @capacity = capacity
  end
end

class Ring
  include Enumerable
  attr_reader :capacity
  attr_accessor :start, :count, :overwrite, :dropped

  def initialize(capacity, overwrite)
    @slots = Array.new(capacity, 0.0)
    @capacity = capacity
    @start = 0
    @count = 0
    @overwrite = overwrite
    @dropped = 0
  end

  def full? = @count == @capacity

  def push(v)
    if full?
      raise BufferFull.new("ring of #{@capacity} is full", @capacity) unless @overwrite
      @slots[@start] = v
      @start = (@start + 1) % @capacity
      @dropped += 1
    else
      @slots[(@start + @count) % @capacity] = v
      @count += 1
    end
    self
  end

  def shift
    return nil if @count == 0
    v = @slots[@start]
    @start = (@start + 1) % @capacity
    @count -= 1
    v
  end

  def each
    @count.times { |i| yield @slots[(@start + i) % @capacity] }
    self
  end

  def mean
    return nil if @count == 0
    sum / @count
  end

  def to_s = "[" + map { |v| format("%.1f", v) }.join(" ") + "]"
end

READINGS = [
  ["cpu", 12.0], ["cpu", 15.5], ["mem", 61.0], ["cpu", 80.25], ["cpu", 79.0],
  ["mem", 62.5], ["cpu", 81.0], ["disk", 5.0], ["cpu", 20.0], ["mem", 90.0],
  ["cpu", 18.5], ["mem", 91.5], ["mem", 92.0], ["cpu", 95.0], ["disk", 5.5]
].freeze

windows = {}
alerts = []
READINGS.each_with_index do |(name, value), t|
  ring = (windows[name] ||= Ring.new(3, true))
  ring.push(value)
  avg = ring.mean
  if avg && ring.full? && avg > 75.0
    alerts << format("t=%02d %-4s avg %.2f over %s", t, name, avg, ring)
  end
end

windows.keys.sort.each do |name|
  ring = windows[name]
  puts format("%-4s window=%-18s mean=%6.2f dropped=%d", name, ring, ring.mean, ring.dropped)
end
puts "alerts:"
alerts.each { |a| puts "  " + a }

strict = Ring.new(4, false)
begin
  (1..6).each do |i|
    strict.push(i * 1.5)
    puts "pushed #{i * 1.5}, now #{strict}"
  end
rescue BufferFull => e
  puts "#{e.message} (capacity #{e.capacity})"
end
drained = []
while (v = strict.shift)
  drained << v
  strict.push(v * 10) if v < 3.0
end
p drained
p strict.shift
p strict.mean
