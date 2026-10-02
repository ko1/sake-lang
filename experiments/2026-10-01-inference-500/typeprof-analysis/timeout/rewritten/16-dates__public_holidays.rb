# Public holidays from rules (fixed date, nth weekday, last weekday, relative
# to Easter), with weekend observance shifting, for several years.

def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = y / 400
  yoe = y - era * 400
  doy = (153 * ((m + 9) % 12) + 2) / 5 + d - 1
  era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
end

def civil_from_days(z)
  z += 719468
  era = z / 146097
  doe = z - era * 146097
  yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  mp = (5 * doy + 2) / 153
  m = mp < 10 ? mp + 3 : mp - 9
  [yoe + era * 400 + (m <= 2 ? 1 : 0), m, doy - (153 * mp + 2) / 5 + 1]
end

def wday(z) = (z + 4) % 7

WDAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

def fmt(z)
  _y, m, d = civil_from_days(z)
  format("%02d-%02d %s", m, d, WDAY_NAMES[wday(z)])
end

def easter(y)
  a = y % 19
  b = y / 100
  c = y % 100
  h = (19 * a + b - b / 4 - (b - (b + 8) / 25 + 1) / 3 + 15) % 30
  l = (32 + 2 * (b % 4) + 2 * (c / 4) - h - c % 4) % 7
  m = (a + 11 * h + 22 * l) / 451
  days_from_civil(y, (h + l - 7 * m + 114) / 31, (h + l - 7 * m + 114) % 31 + 1)
end

class Rule
  attr_reader :name, :kind, :month, :a, :b

  def initialize(name, kind, month, a, b)
    @name = name
    @kind = kind
    @month = month
    @a = a
    @b = b
  end

  def date_in(y)
    case @kind
    in :fixed then days_from_civil(y, @month, @a)
    in :nth
      first = days_from_civil(y, @month, 1)
      first + (@b - wday(first) + 7) % 7 + (@a - 1) * 7
    in :last
      nm = @month == 12 ? days_from_civil(y + 1, 1, 1) : days_from_civil(y, @month + 1, 1)
      last = nm - 1
      last - (wday(last) - @b + 7) % 7
    in :easter then easter(y) + @a
    end
  end

  # Fixed-date holidays on a weekend are observed on the nearest weekday.
  def observe(z)
    return z if @kind != :fixed
    case wday(z)
    in 6 then z - 1
    in 0 then z + 1
    else z
    end
  end
end

class Holiday
  attr_reader :name, :date, :observed

  def initialize(name, date, observed)
    @name = name
    @date = date
    @observed = observed
  end
end

RULES = [
  Rule.new("New Year's Day", :fixed, 1, 1, 0),
  Rule.new("MLK Day", :nth, 1, 3, 1),
  Rule.new("Presidents' Day", :nth, 2, 3, 1),
  Rule.new("Good Friday", :easter, 0, -2, 0),
  Rule.new("Memorial Day", :last, 5, 0, 1),
  Rule.new("Juneteenth", :fixed, 6, 19, 0),
  Rule.new("Independence Day", :fixed, 7, 4, 0),
  Rule.new("Labor Day", :nth, 9, 1, 1),
  Rule.new("Thanksgiving", :nth, 11, 4, 4),
  Rule.new("Christmas Day", :fixed, 12, 25, 0)
]

def holidays_for(y)
  RULES.map do |r|
    z = r.date_in(y)
    Holiday.new(r.name, z, r.observe(z))
  end.sort_by(&:observed)
end

[2026, 2027].each do |y|
  puts "#{y}:"
  holidays_for(y).each do |h|
    note = h.observed == h.date ? "" : "  (observed #{fmt(h.observed)})"
    puts format("  %-17s %s%s", h.name, fmt(h.date), note)
  end
end

puts
puts "Long weekends per year:"
(2026..2031).each do |y|
  long = holidays_for(y).select { |h| [1, 5].include?(wday(h.observed)) }
  puts format("  %d: %2d  %s", y, long.size, long.map { |h| h.name.split(" ")[0] }.join(","))
end

puts
puts "Weekend hits 2026-2053:"
RULES.select { |r| r.kind == :fixed }.each do |r|
  hits = (2026..2053).count { |y| [0, 6].include?(wday(r.date_in(y))) }
  puts format("  %-17s %2d", r.name, hits)
end

tg = RULES.find { |r| r.name == "Thanksgiving" }
if tg
  dates = (2026..2053).map { |y| [y, tg.date_in(y) - days_from_civil(y, 11, 1) + 1] }
  lo = dates.min_by { |e__0| _y, d = e__0; d }
  hi = dates.max_by { |e__1| _y, d = e__1; d }
  puts "Thanksgiving ranges from Nov #{lo[1]} (#{lo[0]}) to Nov #{hi[1]} (#{hi[0]})" if lo && hi
end
