# A small Date type built on Julian Day Numbers: validation, + days, - date,
# comparison, and a few questions answered with it.

class InvalidDate < StandardError
  attr_reader :text

  def initialize(message, text)
    super(message)
    @text = text
  end
end

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def days_in_month(y, m)
  return 29 if m == 2 && leap?(y)
  [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
end

class Date
  include Comparable
  attr_reader :jdn

  def initialize(jdn)
    @jdn = jdn
  end

  def self.civil(y, m, d)
    if m < 1 || m > 12 || d < 1 || d > days_in_month(y, m)
      raise InvalidDate.new("invalid date", format("%04d-%02d-%02d", y, m, d))
    end
    a = (14 - m) / 12
    yy = y + 4800 - a
    mm = m + 12 * a - 3
    new(d + (153 * mm + 2) / 5 + 365 * yy + yy / 4 - yy / 100 + yy / 400 - 32045)
  end

  def self.parse(s)
    m = s.match(/\A(\d{4})-(\d{2})-(\d{2})\z/)
    raise InvalidDate.new("bad format", s) if m.nil?
    civil(m[1].to_i, m[2].to_i, m[3].to_i)
  end

  def ymd
    a = @jdn + 32044
    b = (4 * a + 3) / 146097
    c = a - 146097 * b / 4
    d = (4 * c + 3) / 1461
    e = c - 1461 * d / 4
    m = (5 * e + 2) / 153
    day = e - (153 * m + 2) / 5 + 1
    month = m + 3 - 12 * (m / 10)
    year = 100 * b + d - 4800 + m / 10
    [year, month, day]
  end

  def wday = (@jdn + 1) % 7

  def +(n) = Date.new(@jdn + n)

  def -(other)
    case other
    in Integer then Date.new(@jdn - other)
    in Date then @jdn - other.jdn
    end
  end

  def <=>(other) = @jdn <=> other.jdn

  def to_s
    y, m, d = ymd
    format("%04d-%02d-%02d", y, m, d)
  end
end

WEEKDAY_ABBR = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

today = Date.civil(2026, 10, 1)
puts "Today: #{today} (#{WEEKDAY_ABBR[today.wday]})"

puts "Offsets:"
[1, 7, 30, 100, 365, 1000, -1, -365].each do |n|
  puts format("  %+5d days -> %s", n, (today + n).to_s)
end

events = {
  "New Year" => "2027-01-01",
  "Leap day" => "2028-02-29",
  "Moon landing" => "1969-07-20",
  "Bad leap" => "2027-02-29",
  "Typo" => "2026-13-01",
  "Garbled" => "26/10/01"
}

parsed = []
events.each do |name, text|
  dt = Date.parse(text)
  parsed << [name, dt]
  diff = dt - today
  rel = diff >= 0 ? "in #{diff} days" : "#{-diff} days ago"
  puts format("%-13s %s  %s", name, dt.to_s, rel)
rescue InvalidDate => e
  puts format("%-13s %-10s  rejected: %s", name, e.text, e.message)
end

sorted = parsed.sort_by { |_name, dt| dt.jdn }
puts "Chronological: #{sorted.map(&:first).join(", ")}"
upcoming = sorted.find { |_name, dt| dt > today }
if upcoming
  name, dt = upcoming
  puts "Next event: #{name} on #{dt}"
end

start = Date.civil(1999, 12, 25)
errors = 0
3000.times do |i|
  dt = start + i
  y, m, d = dt.ymd
  errors += 1 if Date.civil(y, m, d) != dt
end
puts "Round-trip errors over 3000 days: #{errors}"

born = Date.parse("1990-05-17")
puts "Day 10000 after #{born}: #{born + 10000}"
weekdays = (2026..2032).map do |y|
  b = Date.civil(y, 5, 17)
  "#{y}:#{WEEKDAY_ABBR[b.wday]}"
end
puts weekdays.join(" ")
puts "Earliest parsed: #{parsed.map { |_name, dt| dt }.min}"
