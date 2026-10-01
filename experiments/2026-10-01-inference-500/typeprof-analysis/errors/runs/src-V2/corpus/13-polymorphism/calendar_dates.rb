class InvalidDate < StandardError
  attr_reader :text
  def initialize(message, text)
    super(message)
    @text = text
  end
end

WEEKDAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

class Date
  include Comparable
  attr_reader :y, :m, :d

  def initialize(y, m, d)
    @y = y
    @m = m
    @d = d
  end

  def self.leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

  def self.days_in_month(y, m)
    return 29 if m == 2 && leap?(y)
    [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
  end

  def self.of(y, m, d)
    raise InvalidDate.new("bad month in #{y}-#{m}-#{d}", "#{y}-#{m}-#{d}") unless m >= 1 && m <= 12
    raise InvalidDate.new("bad day in #{y}-#{m}-#{d}", "#{y}-#{m}-#{d}") unless d >= 1 && d <= days_in_month(y, m)
    Date.new(y, m, d)
  end

  def self.parse(s)
    m = s.match(/\A(\d{4})-(\d{2})-(\d{2})\z/)
    raise InvalidDate.new("not a date: #{s}", s) unless m
    of(m[1].to_i, m[2].to_i, m[3].to_i)
  end

  # days since 1970-01-01 (Howard Hinnant's days_from_civil)
  def ordinal
    y = @m <= 2 ? @y - 1 : @y
    era = y / 400
    yoe = y - era * 400
    mp = (@m + 9) % 12
    doy = (153 * mp + 2) / 5 + @d - 1
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    era * 146097 + doe - 719468
  end

  def self.from_ordinal(z)
    z += 719468
    era = z / 146097
    doe = z - era * 146097
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
    mp = (5 * doy + 2) / 153
    d = doy - (153 * mp + 2) / 5 + 1
    m = mp < 10 ? mp + 3 : mp - 9
    Date.new(yoe + era * 400 + (m <= 2 ? 1 : 0), m, d)
  end

  def +(n) = Date.from_ordinal(ordinal + n)

  def -(b)
    case b
    in Date then ordinal - b.ordinal
    in Integer then Date.from_ordinal(ordinal - b)
    end
  end

  def <=>(b) = ordinal <=> b.ordinal

  def wday = (ordinal + 3) % 7
  def weekend? = wday >= 5
  def weekday_name = WEEKDAY_NAMES[wday]

  def add_months(n)
    total = @y * 12 + (@m - 1) + n
    ny = total / 12
    nm = total % 12 + 1
    Date.new(ny, nm, [@d, Date.days_in_month(ny, nm)].min)
  end

  def to_s = format("%04d-%02d-%02d", @y, @m, @d)
end

HOLIDAYS = ["2026-01-01", "2026-05-01", "2026-12-25", "2026-12-26", "2027-01-01"].map { |s| Date.parse(s) }

def business_day?(d) = !d.weekend? && !HOLIDAYS.include?(d)

def add_business_days(d, n)
  cur = d
  while n > 0
    cur += 1
    n -= 1 if business_day?(cur)
  end
  cur
end

inputs = ["2026-10-01", "2024-02-29", "2023-02-29", "2026-13-01", "2026/10/01", "1970-01-01", "2000-03-01"]
dates = []
inputs.each do |s|
  begin
    d = Date.parse(s)
    dates << d
    puts format("%s %s ordinal %6d", d, d.weekday_name, d.ordinal)
  rescue InvalidDate => e
    puts "#{s}: #{e.message}"
  end
end

puts "sorted: #{dates.sort.join(" ")}"
puts "span: #{dates.max - dates.min} days"
today = Date.parse("2026-10-01")
puts "today + 100 = #{today + 100}, today - 365 = #{today - 365}"
puts "days until new year: #{Date.parse("2027-01-01") - today}"
puts "round trip ok: #{dates.all? { |d| Date.from_ordinal(d.ordinal) == d }}"

puts "== month arithmetic =="
jan31 = Date.parse("2026-01-31")
[1, 2, 13, -2].each { |n| puts "2026-01-31 + #{n} months = #{jan31.add_months(n)}" }

puts "== business days =="
[["2026-12-23", 3], ["2026-10-01", 10], ["2026-04-30", 1]].each do |s, n|
  start = Date.parse(s)
  puts "#{start} (#{start.weekday_name}) + #{n} business days = #{add_business_days(start, n)}"
end

puts "== recurring: every 2nd Tuesday, Oct 2026 - Jan 2027 =="
d = Date.parse("2026-10-01")
stop = Date.parse("2027-01-31")
count = 0
while d <= stop
  if d.weekday_name == "Tue" && (d.d - 1) / 7 == 1
    note = business_day?(d) ? "" : " (holiday)"
    puts "  #{d}#{note}"
    count += 1
  end
  d += 1
end
puts "meetings: #{count}"

by_wday = (0...31).map { |i| Date.parse("2026-12-01") + i }.map(&:weekday_name).tally
puts "December 2026 weekdays: #{WEEKDAY_NAMES.map { |n| "#{n}=#{by_wday[n]}" }.join(" ")}"
leap_years = (1896..1912).select { |y| Date.leap?(y) }
puts "leap years 1896-1912: #{leap_years.join(", ")}"
