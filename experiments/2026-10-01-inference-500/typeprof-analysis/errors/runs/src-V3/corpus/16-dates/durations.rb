# A Duration type in whole seconds with arithmetic and ordering, parsed from
# "1h30m", "2d4h", "1:30:00", "45:10" or "90s", and printed in several styles.

class BadDuration < StandardError
  attr_reader :text

  def initialize(message, text)
    super(message)
    @text = text
  end
end

class Duration
  include Comparable
  attr_reader :secs

  UNITS = { "d" => 86400, "h" => 3600, "m" => 60, "s" => 1 }

  def initialize(secs)
    @secs = secs
  end

  def +(other) = Duration.new(@secs + other.secs)
  def -(other) = Duration.new(@secs - other.secs)

  def *(k)
    case k
    in Integer then Duration.new(@secs * k)
    in Float then Duration.new((@secs * k).round)
    end
  end

  def /(k) = Duration.new(@secs / k)

  def <=>(other) = @secs <=> other.secs

  def self.parse(text)
    s = text.strip
    if (m = s.match(/\A(\d+):(\d{2}):(\d{2})\z/))
      return new(m[1].to_i * 3600 + m[2].to_i * 60 + m[3].to_i)
    end
    if (m = s.match(/\A(\d+):(\d{2})\z/))
      return new(m[1].to_i * 60 + m[2].to_i)
    end
    raise BadDuration.new("unparseable duration", text) unless s.match?(/\A(\d+[dhms])+\z/)
    total = s.scan(/(\d+)([dhms])/).sum { |num, unit| num.to_i * UNITS.fetch(unit) }
    new(total)
  end

  def clock
    format("%d:%02d:%02d", @secs / 3600, (@secs % 3600) / 60, @secs % 60)
  end

  def human
    return "0s" if @secs == 0
    rest = @secs
    parts = UNITS.filter_map do |unit, size|
      n, rest = rest.divmod(size)
      "#{n}#{unit}" if n > 0
    end
    parts.join(" ")
  end

  def to_s = human
end

ZERO = Duration.new(0)

puts "Parsing:"
inputs = ["1h30m", "2d4h", "1:30:00", "45:10", "90s", "3m", "1h1h", "  10m5s ", "1.5h", "4:7", "0s"]
good = []
inputs.each do |text|
  d = Duration.parse(text)
  good << d
  puts format("  %-10s %8d s  %-12s %s", "'#{text}'", d.secs, d.clock, d.human)
rescue BadDuration => e
  puts format("  %-10s rejected: %s", "'#{e.text}'", e.message)
end

total = good.reduce(ZERO) { |acc, d| acc + d }
puts "Sum: #{total}, longest: #{good.max}, shortest: #{good.min}"

tracks = [["Overture", "4:12"], ["Slow Tide", "6:45"], ["Glass", "3:58"], ["Northbound", "5:31"],
          ["Interlude", "1:20"], ["Harbor Lights", "7:02"], ["Coda", "2:49"]]
puts
puts "Album:"
running = ZERO
tracks.each_with_index do |(name, len), i|
  d = Duration.parse(len)
  running += d
  puts format("  %d. %-14s %s  ends at %s", i + 1, name, d.clock, running.clock)
end
half = running / 2
acc = ZERO
split = 0
best_gap = nil
tracks.each_with_index do |(_name, len), i|
  acc += Duration.parse(len)
  gap = (acc - half).secs.abs
  if best_gap.nil? || gap < best_gap
    best_gap = gap
    split = i + 1
  end
end
puts "Total #{running.clock}; side A gets #{split} tracks (#{best_gap}s from half)"

laps = ["1:32:10", "1:31:58", "1:33:40", "1:31:12", "1:36:05", "1:31:50"].map { |s| Duration.parse(s) }
avg = laps.reduce(ZERO, :+) / laps.size
best = laps.min
if best
  limit = best * 1.05
  slow = laps.select { |l| l > limit }
  puts
  puts "Laps: avg #{avg.clock}, best #{best.clock}, 105% #{limit.clock}, slow laps: #{slow.size}"
  puts "Deltas: #{laps.map { |l| "+#{(l - best).secs}" }.join(" ")}"
end
week = Duration.parse("37h30m") * 4
puts "Four 37.5h weeks: #{week} = #{week.clock}"
