# Easter dates (Gregorian and Orthodox) and the movable feasts derived from them.

class Feast
  attr_reader :name, :offset

  def initialize(name, offset)
    @name = name
    @offset = offset
  end
end

MONTH_ABBR = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def month_lengths(y) = [31, leap?(y) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

def day_of_year(y, m, d) = month_lengths(y).take(m - 1).sum + d

def from_day_of_year(y, n)
  lengths = month_lengths(y)
  m = 0
  while n > lengths[m]
    n -= lengths[m]
    m += 1
  end
  [m + 1, n]
end

# Anonymous Gregorian algorithm (Meeus/Jones/Butcher).
def gregorian_easter(y)
  a = y % 19
  b = y / 100
  c = y % 100
  d = b / 4
  e = b % 4
  f = (b + 8) / 25
  g = (b - f + 1) / 3
  h = (19 * a + b - d - g + 15) % 30
  i = c / 4
  k = c % 4
  l = (32 + 2 * e + 2 * i - h - k) % 7
  m = (a + 11 * h + 22 * l) / 451
  month = (h + l - 7 * m + 114) / 31
  day = (h + l - 7 * m + 114) % 31 + 1
  [month, day]
end

# Meeus's Julian algorithm, shifted to the Gregorian calendar (valid 1900-2099).
def orthodox_easter(y)
  a = y % 4
  b = y % 7
  c = y % 19
  d = (19 * c + 15) % 30
  e = (2 * a + 4 * b - d + 34) % 7
  month = (d + e + 114) / 31
  day = (d + e + 114) % 31 + 1
  from_day_of_year(y, day_of_year(y, month, day) + 13)
end

def show(m, d) = format("%s %2d", MONTH_ABBR[m - 1], d)

feasts = [
  Feast.new("Ash Wednesday", -46),
  Feast.new("Palm Sunday", -7),
  Feast.new("Good Friday", -2),
  Feast.new("Easter Monday", 1),
  Feast.new("Ascension", 39),
  Feast.new("Pentecost", 49),
  Feast.new("Corpus Christi", 60)
]

puts "Year  Western  Orthodox  Gap"
(2024..2032).each do |y|
  wm, wd = gregorian_easter(y)
  om, od = orthodox_easter(y)
  gap = (day_of_year(y, om, od) - day_of_year(y, wm, wd)) / 7
  puts format("%d  %s   %s    %dw", y, show(wm, wd), show(om, od), gap)
end

y = 2027
em, ed = gregorian_easter(y)
easter_doy = day_of_year(y, em, ed)
puts
puts "Movable feasts in #{y}:"
feasts.each do |f|
  m, d = from_day_of_year(y, easter_doy + f.offset)
  puts format("  %-15s %s (%+d)", f.name, show(m, d), f.offset)
end

dates = Hash.new(0)
same_day = []
earliest = nil
latest = nil
(1900..2099).each do |yy|
  m, d = gregorian_easter(yy)
  key = m * 100 + d
  dates[key] += 1
  earliest = [yy, key] if earliest.nil? || key < earliest[1]
  latest = [yy, key] if latest.nil? || key > latest[1]
  same_day << yy if orthodox_easter(yy) == [m, d]
end
puts
puts "Distinct Easter dates 1900-2099: #{dates.size}"
if earliest && latest
  ey, ek = earliest
  ly, lk = latest
  puts "Earliest: #{show(ek / 100, ek % 100)} (#{ey}), latest: #{show(lk / 100, lk % 100)} (#{ly})"
end
top = dates.sort_by { |k, n| [-n, k] }.take(3)
top.each { |k, n| puts "  #{show(k / 100, k % 100)}: #{n} times" }
puts "Both churches together in #{same_day.size} years, first few: #{same_day.take(5).join(", ")}"
march = dates.count { |k, _n| k < 400 }
puts "Dates in March: #{march}, in April: #{dates.size - march}"
