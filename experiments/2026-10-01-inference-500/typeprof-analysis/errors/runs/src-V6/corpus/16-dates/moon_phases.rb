# Moon phases with fixed-point integer arithmetic (micro-days), a lunar
# calendar for one month, the year's full moons with traditional names, and
# the sexagenary (stem-branch) year cycle.

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

# Micro-days: 1 day = 1_000_000 units.
UNIT = 1_000_000
SYNODIC = 29_530_589
# Reference new moon: 2000-01-06 18:14 UTC.
EPOCH_NEW_MOON = days_from_civil(2000, 1, 6) * UNIT + (18 * 60 + 14) * UNIT / 1440

PHASES = ["new moon", "waxing crescent", "first quarter", "waxing gibbous",
          "full moon", "waning gibbous", "last quarter", "waning crescent"]
GLYPHS = ["@", ")", "D", "O", "O", "O", "C", "("]

def age_at(day) = (day * UNIT + UNIT / 2 - EPOCH_NEW_MOON) % SYNODIC

def phase_name(age)
  eighth = SYNODIC / 8
  PHASES[((age + eighth / 2) / eighth) % 8]
end

# Illuminated fraction in percent, approximated by a triangle wave.
def illumination(age)
  half = SYNODIC / 2
  dist = age <= half ? age : SYNODIC - age
  dist * 100 / half
end

def glyph(age) = GLYPHS[((age + SYNODIC / 16) / (SYNODIC / 8)) % 8]

def fmt(z)
  y, m, d = civil_from_days(z)
  format("%04d-%02d-%02d", y, m, d)
end

def fmt_moment(units)
  mins = (units % UNIT) * 1440 / UNIT
  "#{fmt(units / UNIT)} #{format("%02d:%02d", mins / 60, mins % 60)}"
end

puts "Phases for selected dates:"
[[2026, 10, 1], [2026, 10, 10], [2026, 10, 17], [2026, 10, 26], [2000, 1, 6], [1969, 7, 20]].each do |y, m, d|
  z = days_from_civil(y, m, d)
  age = age_at(z)
  puts format("  %s  age %5.2f d  %3d%%  %s", fmt(z), age / UNIT.to_f, illumination(age), phase_name(age))
end

puts
puts "October 2026:"
first = days_from_civil(2026, 10, 1)
line = (0..30).map { |i| glyph(age_at(first + i)) }.join
puts "  1#{" " * 8}10#{" " * 8}20#{" " * 8}30"
puts "  #{line}"

start_units = days_from_civil(2026, 1, 1) * UNIT
stop_units = days_from_civil(2027, 1, 1) * UNIT
k = (start_units - EPOCH_NEW_MOON) / SYNODIC
moons = []
while EPOCH_NEW_MOON + k * SYNODIC < stop_units
  new_at = EPOCH_NEW_MOON + k * SYNODIC
  full_at = new_at + SYNODIC / 2
  moons << [:new, new_at] if new_at >= start_units
  moons << [:full, full_at] if full_at >= start_units && full_at < stop_units
  k += 1
end

names = ["Wolf", "Snow", "Worm", "Pink", "Flower", "Strawberry", "Buck", "Sturgeon", "Harvest", "Hunter's", "Beaver", "Cold"]
fulls = moons.select { |kind, _at| kind == :full }
puts
puts "Full moons of 2026 (#{fulls.size}):"
by_month = fulls.group_by { |_kind, at| civil_from_days(at / UNIT)[1] }
fulls.each do |kind, at|
  m = civil_from_days(at / UNIT)[1]
  blue = by_month.fetch(m).size > 1 && by_month.fetch(m).index([kind, at]) == 1
  puts format("  %s  %s%s", fmt_moment(at), names[m - 1], blue ? " (blue moon)" : "")
end
puts "New moons: #{moons.count { |kind, _at| kind == :new }}"

puts
stems = ["Jia", "Yi", "Bing", "Ding", "Wu", "Ji", "Geng", "Xin", "Ren", "Gui"]
branches = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
elements = ["Wood", "Fire", "Earth", "Metal", "Water"]
puts "Sexagenary years:"
(2020..2031).each do |y|
  s = (y - 4) % 10
  b = (y - 4) % 12
  puts format("  %d  %-5s %-8s %-5s %s, cycle year %2d", y, stems[s], branches[b], elements[s / 2], s.even? ? "yang" : "yin", (y - 4) % 60 + 1)
end
puts "Golden numbers: #{(2024..2030).map { |y| "#{y}:#{y % 19 + 1}" }.join(" ")}"
