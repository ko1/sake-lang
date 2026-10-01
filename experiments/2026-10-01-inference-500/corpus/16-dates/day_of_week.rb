# Day-of-week computations: Sakamoto's method, Zeller's congruence, and a
# cross-check between them, then a scan for Friday-the-13ths.

DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
MONTH_ABBR = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def sakamoto(y, m, d)
  t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
  y -= 1 if m < 3
  (y + y / 4 - y / 100 + y / 400 + t[m - 1] + d) % 7
end

# Zeller gives 0 = Saturday; convert to 0 = Sunday.
def zeller(y, m, d)
  if m < 3
    m += 12
    y -= 1
  end
  k = y % 100
  j = y / 100
  h = (d + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
  (h + 6) % 7
end

def parse_date(s)
  s.split("-").map(&:to_i)
end

events = [
  ["1969-07-20", "Moon landing"],
  ["1989-11-09", "Berlin Wall opens"],
  ["2000-01-01", "Y2K"],
  ["2000-02-29", "Leap day 2000"],
  ["1900-03-01", "After non-leap 1900"],
  ["2026-10-01", "Today in the experiment"],
  ["1752-09-14", "Gregorian adoption in Britain"]
]

puts "Historic dates:"
mismatches = 0
events.each do |date, label|
  y, m, d = parse_date(date)
  a = sakamoto(y, m, d)
  b = zeller(y, m, d)
  mismatches += 1 if a != b
  puts format("  %s  %-9s %s", date, DAY_NAMES[a], label)
end
puts "Methods disagree on #{mismatches} dates"

checked = 0
bad = []
(1999..2004).each do |y|
  (1..12).each do |m|
    dim = [31, leap?(y) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
    (1..dim).each do |d|
      checked += 1
      bad << [y, m, d] if sakamoto(y, m, d) != zeller(y, m, d)
    end
  end
end
puts "Cross-checked #{checked} days, #{bad.size} differences"

puts "Friday the 13th:"
per_year = {}
(2024..2030).each do |y|
  months = (1..12).select { |m| sakamoto(y, m, 13) == 5 }
  per_year[y] = months
  names = months.map { |m| MONTH_ABBR[m - 1] }
  puts format("  %d: %d (%s)", y, months.size, names.join(", "))
end
best = per_year.max_by { |_y, ms| ms.size }
if best
  year, months = best
  puts "Most in #{year}: #{months.size}"
end

counts = Hash.new(0)
(2001..2400).each { |y| counts[sakamoto(y, 1, 1)] += 1 }
puts "January 1st over 400 years:"
(0..6).each { |w| puts format("  %-9s %3d", DAY_NAMES[w], counts[w]) }
