# Exact ages in years, months and days, next-birthday countdowns (with
# Feb-29 birthdays), zodiac signs and a few roster statistics.

class Person
  attr_reader :name, :year, :month, :day

  def initialize(name, year, month, day)
    @name = name
    @year = year
    @month = month
    @day = day
  end
end

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def dim(y, m)
  return 29 if m == 2 && leap?(y)
  [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
end

def ordinal(y, m, d)
  (1...m).sum { |mm| dim(y, mm) } + d
end

def serial(y, m, d)
  yy = y - 1
  yy * 365 + yy / 4 - yy / 100 + yy / 400 + ordinal(y, m, d)
end

def age_between(y1, m1, d1, y2, m2, d2)
  years = y2 - y1
  months = m2 - m1
  days = d2 - d1
  if days < 0
    months -= 1
    pm = m2 == 1 ? 12 : m2 - 1
    py = m2 == 1 ? y2 - 1 : y2
    days = [dim(py, pm) - d1, 0].max + d2
  end
  if months < 0
    years -= 1
    months += 12
  end
  {years: years, months: months, days: days}
end

# A Feb-29 birthday is celebrated on Feb 28 in common years.
def birthday_in(p, y)
  m = p.month
  d = p.day
  d = 28 if m == 2 && d == 29 && !leap?(y)
  [m, d]
end

def next_birthday(p, y, m, d)
  today = serial(y, m, d)
  by = y
  bm, bd = birthday_in(p, by)
  if serial(by, bm, bd) < today
    by += 1
    bm, bd = birthday_in(p, by)
  end
  [by, serial(by, bm, bd) - today]
end

ZODIAC_CUTOFFS = [[1, 20, "Capricorn"], [2, 19, "Aquarius"], [3, 21, "Pisces"], [4, 20, "Aries"],
                  [5, 21, "Taurus"], [6, 21, "Gemini"], [7, 23, "Cancer"], [8, 23, "Leo"],
                  [9, 23, "Virgo"], [10, 23, "Libra"], [11, 22, "Scorpio"], [12, 22, "Sagittarius"]]

def zodiac(m, d)
  found = ZODIAC_CUTOFFS.find { |cm, _cd, _name| cm == m }
  return "?" if !found    
  _cm, cd, name = found
  if d < cd
    name
  else
    i = ZODIAC_CUTOFFS.index(found)
    ZODIAC_CUTOFFS[(i + 1) % 12][2]
  end
end

roster = [
  Person.new("Aiko", 1990, 5, 17),
  Person.new("Bram", 2000, 2, 29),
  Person.new("Chen", 1985, 10, 1),
  Person.new("Dana", 2012, 12, 31),
  Person.new("Emil", 1958, 3, 3),
  Person.new("Fay", 2026, 1, 15),
  Person.new("Gus", 1999, 10, 2)
]

ty = 2026
tm = 10
td = 1
puts "As of #{format("%04d-%02d-%02d", ty, tm, td)}:"
ages = {}
roster.each do |p|
  age = age_between(p.year, p.month, p.day, ty, tm, td)
  age => {years:, months:, days:}
  ages[p.name] = years
  ny, wait = next_birthday(p, ty, tm, td)
  turning = ny - p.year
  lived = serial(ty, tm, td) - serial(p.year, p.month, p.day)
  sign = zodiac(p.month, p.day)
  note = wait == 0 ? "today!" : "in #{wait} days"
  puts format("  %-5s %2dy %2dm %2dd  %6d days lived  %-11s turns %d %s", p.name, years, months, days, lived, sign, turning, note)
end

puts
oldest = roster.min_by { |p| serial(p.year, p.month, p.day) }
youngest = roster.max_by { |p| serial(p.year, p.month, p.day) }
puts "Oldest: #{oldest.name}, youngest: #{youngest.name}" if oldest && youngest
adults = roster.select { |p| ages.fetch(p.name) >= 18 }
puts "Adults: #{adults.map(&:name).join(", ")}"
decades = ages.values.map { |a| a / 10 * 10 }.tally
decades.keys.sort.each { |dcd| puts format("  %2ds: %d", dcd, decades[dcd]) }

bram = roster.find { |p| p.name == "Bram" }
if bram
  parties = (2026..2032).map do |y|
    m, d = birthday_in(bram, y)
    "#{y}-#{format("%02d-%02d", m, d)}"
  end
  puts "Bram celebrates: #{parties.join(" ")}"
  real = (2001..2032).count { |y| leap?(y) }
  puts "Real birthdays up to 2032: #{real}"
end

cases = [[2026, 1, 31, 2026, 3, 1], [2024, 1, 31, 2024, 3, 1], [2026, 3, 31, 2026, 4, 30], [2025, 12, 31, 2026, 1, 1]]
cases.each do |y1, m1, d1, y2, m2, d2|
  age_between(y1, m1, d1, y2, m2, d2) => {years:, months:, days:}
  puts format("  %04d-%02d-%02d -> %04d-%02d-%02d: %dy %dm %dd", y1, m1, d1, y2, m2, d2, years, months, days)
end
