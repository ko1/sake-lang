# A contribution heatmap: daily activity counts over half a year rendered as a
# weekday-by-week grid, plus streaks, monthly totals and busiest weekdays.

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

# Deterministic pseudo activity: weekdays busier, a holiday gap, a crunch week.
def activity(z)
  h = (z * 2654435761) % 4294967296
  base = h % 9
  base /= 3 if wday(z) == 0 || wday(z) == 6
  base = 0 if h % 5 == 0
  _y, m, d = civil_from_days(z)
  base = 0 if m == 8 && d.between?(10, 23)
  base += 6 if m == 9 && d.between?(21, 25)
  base
end

def level(n, cuts)
  cuts.find_index { |c| n <= c } || cuts.size
end

MONTH_ABBR = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
DAY_ABBR = %w[Sun Mon Tue Wed Thu Fri Sat]

first = days_from_civil(2026, 4, 1)
last = days_from_civil(2026, 9, 30)
counts = (first..last).to_h { |z| [z, activity(z)] }

active = counts.values.select(&:positive?).sort
cuts = [0, active[active.size / 4], active[active.size / 2], active[active.size * 3 / 4]]
glyphs = [".", "-", "+", "*", "#"]

grid_start = first - wday(first)
weeks = (last - grid_start) / 7 + 1

header = "".ljust(4)
prev_month = 0
weeks.times do |w|
  _y, m, _d = civil_from_days(grid_start + w * 7)
  header += m != prev_month ? MONTH_ABBR[m - 1][0] : " "
  prev_month = m
end
puts header
DAY_ABBR.each_with_index do |name, wd|
  row = name + " "
  weeks.times do |w|
    n = counts[grid_start + w * 7 + wd]
    row += !n     ? " " : glyphs[level(n, cuts)]
  end
  puts row.rstrip
end
puts "Legend: #{(0..4).map { |i| "#{glyphs[i]}#{i == 0 ? "=0" : "<=#{i < 4 ? cuts[i] : "max"}"}" }.join(" ")}"

longest = 0
longest_end = first
current = 0
(first..last).each do |z|
  if counts.fetch(z) > 0
    current += 1
    if current > longest
      longest = current
      longest_end = z
    end
  else
    current = 0
  end
end
_sy, sm, sd = civil_from_days(longest_end - longest + 1)
_ey, em, ed = civil_from_days(longest_end)
puts format("Longest streak: %d days (%02d-%02d .. %02d-%02d), current streak: %d", longest, sm, sd, em, ed, current)

monthly = Hash.new(0)
counts.each { |z, n| monthly[civil_from_days(z)[1]] += n }
puts "Monthly: " + monthly.map { |m, n| "#{m}=#{n}" }.join(" ")

by_wday = [0] * 7
counts.each { |z, n| by_wday[wday(z)] += n }
top = (0..6).max_by { |wd| by_wday[wd] }
puts "Per weekday: #{by_wday.join(" ")}; busiest #{top}"
total = counts.values.sum
best_day = counts.max_by { |_z, n| n }
if best_day
  z, n = best_day
  y, m, d = civil_from_days(z)
  puts format("Total %d over %d days (%.2f/day); best day %04d-%02d-%02d with %d", total, counts.size,
              total.to_f / counts.size, y, m, d, n)
end
