# Calendar arithmetic as modular arithmetic: Zeller's congruence, Conway's
# Doomsday rule, the Gregorian Easter computus, and Friday-the-13th statistics.

def day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

# 0 = Sunday
def zeller(y, m, d)
  if m < 3
    m += 12
    y -= 1
  end
  k = y % 100
  j = y / 100
  h = (d + 13 * (m + 1) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
  (h + 6) % 7
end

def doomsday(y)
  anchor = (2 + 5 * (y / 100 % 4)) % 7
  t = y % 100
  (anchor + t + t / 4) % 7
end

def doomsday_dates(y)
  jan = leap?(y) ? 4 : 3
  feb = leap?(y) ? 29 : 28
  { 1 => jan, 2 => feb, 3 => 14, 4 => 4, 5 => 9, 6 => 6, 7 => 11, 8 => 8, 9 => 5, 10 => 10, 11 => 7, 12 => 12 }
end

def weekday_by_doomsday(y, m, d)
  ref = doomsday_dates(y)[m]
  (doomsday(y) + d - ref) % 7
end

# anonymous Gregorian algorithm (Meeus/Jones/Butcher)
def easter(y)
  a = y % 19
  b, c = y.divmod(100)
  d, e = b.divmod(4)
  f = (b + 8) / 25
  g = (b - f + 1) / 3
  h = (19 * a + b - d - g + 15) % 30
  i, k = c.divmod(4)
  l = (32 + 2 * e + 2 * i - h - k) % 7
  m = (a + 11 * h + 22 * l) / 451
  month, day = (h + l - 7 * m + 114).divmod(31)
  [month, day + 1]
end

def march_april(k) = k > 31 ? "April #{k - 31}" : "March #{k}"

puts "weekdays:"
dates = [[1969, 7, 20], [2000, 1, 1], [2000, 2, 29], [1900, 3, 1], [2026, 10, 1], [1582, 10, 15], [2100, 12, 31]]
dates.each do |y, m, d|
  z = zeller(y, m, d)
  dd = weekday_by_doomsday(y, m, d)
  agree = z == dd ? "" : "  (doomsday says #{day_names[dd]})"
  puts format("  %04d-%02d-%02d %-9s%s", y, m, d, day_names[z], agree)
end

checked = 0
bad = 0
(1990..2030).each do |y|
  (1..12).each do |m|
    [1, 13, 28].each do |d|
      checked += 1
      bad += 1 if zeller(y, m, d) != Time.new(y, m, d).wday
    end
  end
end
puts "Zeller vs Time.wday on #{checked} dates: #{bad} differences"

puts "doomsdays:"
[1900, 1966, 2000, 2024, 2026].each do |y|
  puts "  #{y}: #{day_names[doomsday(y)]}"
end

puts "Easter Sundays:"
(2020..2030).each do |y|
  m, d = easter(y)
  month = m == 3 ? "March" : "April"
  puts format("  %d: %s %2d", y, month, d)
  raise "Easter #{y} is not a Sunday" if zeller(y, m, d) != 0
end

dist = Hash.new(0)
(1900..2299).each do |y|
  m, d = easter(y)
  dist[m == 3 ? d : d + 31] += 1
end
earliest, latest = dist.keys.minmax
ck, cv = dist.max_by { |k, v| [v, -k] }
puts "Easter 1900-2299: earliest #{march_april(earliest)}, latest #{march_april(latest)}, most common #{march_april(ck)} (#{cv} times)"

puts "Friday the 13th:"
weekday_counts = Array.new(7, 0)
(1601..2000).each do |y|
  (1..12).each { |m| weekday_counts[zeller(y, m, 13)] += 1 }
end
weekday_counts.each_with_index { |c, w| puts "  #{day_names[w].ljust(9)} #{c}" }
fridays = []
(2026..2027).each do |y|
  (1..12).each { |m| fridays << format("%d-%02d", y, m) if zeller(y, m, 13) == 5 }
end
puts "  in 2026-2027: #{fridays.join(" ")}"
