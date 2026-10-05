# Converts between calendar systems through the Julian Day Number:
# Gregorian, Julian, the tabular Islamic calendar and the Maya Long Count.
# Each calendar is its own type; shared behaviour lives in a mixin module.

module CalendarDate
  WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

  # Needs `to_jdn` and `to_s` from the including class.
  def jdn = to_jdn
  def weekday = WEEKDAYS[to_jdn % 7]
  def days_until(other_jdn) = other_jdn - to_jdn
  def describe = "#{to_s} (#{weekday}, JDN #{to_jdn})"
end

class Gregorian
  include CalendarDate
  attr_reader :year, :month, :day

  def initialize(year, month, day)
    @year = year
    @month = month
    @day = day
  end

  def to_jdn
    a = (14 - @month) / 12
    y = @year + 4800 - a
    m = @month + 12 * a - 3
    @day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
  end

  def self.from_jdn(j)
    a = j + 32044
    b = (4 * a + 3) / 146097
    c = a - 146097 * b / 4
    d = (4 * c + 3) / 1461
    e = c - 1461 * d / 4
    m = (5 * e + 2) / 153
    new(100 * b + d - 4800 + m / 10, m + 3 - 12 * (m / 10), e - (153 * m + 2) / 5 + 1)
  end

  def to_s = format("%04d-%02d-%02d", @year, @month, @day)
end

class Julian
  include CalendarDate
  attr_reader :year, :month, :day

  def initialize(year, month, day)
    @year = year
    @month = month
    @day = day
  end

  def to_jdn
    a = (14 - @month) / 12
    y = @year + 4800 - a
    m = @month + 12 * a - 3
    @day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
  end

  def self.from_jdn(j)
    c = j + 32082
    d = (4 * c + 3) / 1461
    e = c - 1461 * d / 4
    m = (5 * e + 2) / 153
    new(d - 4800 + m / 10, m + 3 - 12 * (m / 10), e - (153 * m + 2) / 5 + 1)
  end

  def to_s = format("%04d-%02d-%02d Julian", @year, @month, @day)
end

class Islamic
  include CalendarDate
  attr_reader :year, :month, :day

  EPOCH = 1948440
  MONTHS = ["Muharram", "Safar", "Rabi I", "Rabi II", "Jumada I", "Jumada II",
            "Rajab", "Shaban", "Ramadan", "Shawwal", "Dhu al-Qadah", "Dhu al-Hijjah"]

  def initialize(year, month, day)
    @year = year
    @month = month
    @day = day
  end

  def to_jdn
    @day + (59 * (@month - 1) + 1) / 2 + (@year - 1) * 354 + (3 + 11 * @year) / 30 + EPOCH - 1
  end

  def self.from_jdn(j)
    year = (30 * (j - EPOCH) + 10646) / 10631
    month = [12, (2 * (j - (29 + new(year, 1, 1).to_jdn)) + 58) / 59 + 1].min
    day = j - new(year, month, 1).to_jdn + 1
    new(year, month, day)
  end

  def to_s = "#{@day} #{MONTHS[@month - 1]} #{@year} AH"
end

class LongCount
  include CalendarDate
  attr_reader :baktun, :katun, :tun, :uinal, :kin

  CORRELATION = 584283

  def initialize(baktun, katun, tun, uinal, kin)
    @baktun = baktun
    @katun = katun
    @tun = tun
    @uinal = uinal
    @kin = kin
  end

  def to_jdn = CORRELATION + @baktun * 144000 + @katun * 7200 + @tun * 360 + @uinal * 20 + @kin

  def self.from_jdn(j)
    n = j - CORRELATION
    baktun, n = n.divmod(144000)
    katun, n = n.divmod(7200)
    tun, n = n.divmod(360)
    uinal, kin = n.divmod(20)
    new(baktun, katun, tun, uinal, kin)
  end

  def to_s = "#{@baktun}.#{@katun}.#{@tun}.#{@uinal}.#{@kin}"
end

dates = [
  ["Experiment day", Gregorian.new(2026, 10, 1)],
  ["Gregorian reform", Gregorian.new(1582, 10, 15)],
  ["Day before reform", Julian.new(1582, 10, 4)],
  ["Hijra epoch", Islamic.new(1, 1, 1)],
  ["Ramadan 1448 starts", Islamic.new(1448, 9, 1)],
  ["13th baktun", LongCount.new(13, 0, 0, 0, 0)],
  ["Unix epoch", Gregorian.new(1970, 1, 1)]
]

today_jdn = Gregorian.new(2026, 10, 1).to_jdn
dates.each do |label, date|
  j = date.jdn
  puts "#{label}: #{date.describe}"
  puts "    = #{Gregorian.from_jdn(j)} | #{Julian.from_jdn(j)} | #{Islamic.from_jdn(j)} | #{LongCount.from_jdn(j)}"
  puts "    #{date.days_until(today_jdn)} days before 2026-10-01" if j < today_jdn
end

puts
puts "Drift (Julian date behind Gregorian):"
[1500, 1700, 1800, 1900, 2100].each do |y|
  g = Gregorian.new(y, 3, 1)
  jl = Julian.from_jdn(g.to_jdn)
  drift = Gregorian.new(y, jl.month, jl.day).to_jdn - g.to_jdn
  puts format("  %d: Gregorian %s is Julian %s (%d days)", y, g.to_s, jl.to_s, -drift)
end

bad = 0
(2400000..2500000).step(997) do |j|
  bad += 1 if Gregorian.from_jdn(j).to_jdn != j
  bad += 1 if Julian.from_jdn(j).to_jdn != j
  bad += 1 if Islamic.from_jdn(j).to_jdn != j
  bad += 1 if LongCount.from_jdn(j).to_jdn != j
end
puts "Round-trip failures: #{bad}"
starts = (1..12).map { |m| Gregorian.from_jdn(Islamic.new(1448, m, 1).to_jdn) }
puts "1448 AH month starts: #{starts.map { |g| g.to_s[5..] }.join(" ")}"
