# ISO-8601 week dates: conversion both ways, 53-week years, and grouping
# work logs by ISO week.

# Days since 1970-01-01 (Howard Hinnant's algorithm).
def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = (y >= 0 ? y : y - 399) / 400
  yoe = y - era * 400
  mp = (m + 9) % 12
  doy = (153 * mp + 2) / 5 + d - 1
  doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
end

def civil_from_days(z)
  z += 719468
  era = (z >= 0 ? z : z - 146096) / 146097
  doe = z - era * 146097
  yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  y = yoe + era * 400
  doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  mp = (5 * doy + 2) / 153
  d = doy - (153 * mp + 2) / 5 + 1
  m = mp < 10 ? mp + 3 : mp - 9
  y += 1 if m <= 2
  [y, m, d]
end

# ISO weekday: Monday = 1 ... Sunday = 7. 1970-01-01 was a Thursday.
def iso_wday(days) = (days + 3) % 7 + 1

def week1_monday(year)
  jan4 = days_from_civil(year, 1, 4)
  jan4 - (iso_wday(jan4) - 1)
end

def iso_week(y, m, d)
  days = days_from_civil(y, m, d)
  year = y
  if days < week1_monday(year)
    year -= 1
  elsif days >= week1_monday(year + 1)
    year += 1
  end
  week = (days - week1_monday(year)) / 7 + 1
  [year, week, iso_wday(days)]
end

def from_iso_week(year, week, wday)
  civil_from_days(week1_monday(year) + (week - 1) * 7 + wday - 1)
end

def weeks_in_year(year) = (week1_monday(year + 1) - week1_monday(year)) / 7

def fmt_date(y, m, d) = format("%04d-%02d-%02d", y, m, d)

def fmt_week(year, week, wday) = format("%04d-W%02d-%d", year, week, wday)

puts "Boundary dates:"
samples = [[2004, 12, 31], [2005, 1, 1], [2005, 1, 2], [2007, 12, 31], [2008, 12, 29],
           [2009, 12, 31], [2010, 1, 3], [2020, 12, 31], [2021, 1, 4], [2026, 10, 1]]
samples.each do |y, m, d|
  year, week, wday = iso_week(y, m, d)
  ok = from_iso_week(year, week, wday) == [y, m, d] ? "ok" : "MISMATCH"
  puts "  #{fmt_date(y, m, d)} -> #{fmt_week(year, week, wday)} #{ok}"
end

long_years = (2000..2040).select { |y| weeks_in_year(y) == 53 }
puts "Years with 53 ISO weeks (2000-2040): #{long_years.join(" ")}"

log = [
  ["2026-09-24", 7], ["2026-09-25", 6], ["2026-09-28", 8], ["2026-09-29", 9],
  ["2026-09-30", 7], ["2026-10-01", 8], ["2026-10-02", 4], ["2026-10-03", 2],
  ["2026-10-05", 8], ["2026-10-07", 10], ["2026-12-28", 5], ["2026-12-31", 6],
  ["2027-01-01", 3], ["2027-01-04", 8]
]

by_week = Hash.new { |h, k| h[k] = [] }
log.each do |date, hours|
  y, m, d = date.split("-").map(&:to_i)
  year, week, wday = iso_week(y, m, d)
  by_week[[year, week]] << [wday, hours]
end

puts "Hours per ISO week:"
by_week.keys.sort.each do |key|
  year, week = key
  entries = by_week[key]
  total = entries.sum { |_wday, hours| hours }
  weekend = entries.select { |wday, _hours| wday >= 6 }.sum { |_wday, hours| hours }
  mon_y, mon_m, mon_d = from_iso_week(year, week, 1)
  flag = total > 40 ? " overtime" : ""
  puts format("  %04d-W%02d (from %s): %3d h, weekend %d h%s", year, week, fmt_date(mon_y, mon_m, mon_d), total, weekend, flag)
end

busiest = by_week.max_by { |_key, entries| entries.size }
if busiest
  key, entries = busiest
  year, week = key
  puts "Most logged days: #{fmt_week(year, week, 1)[0, 8]} with #{entries.size} days"
end
