# Maps sales dates onto fiscal calendars (an April-start fiscal year, and a
# 4-4-5 retail calendar starting on the Sunday nearest Feb 1) and reports
# totals per quarter and period with growth figures.

class Sale
  attr_reader :date, :region, :amount

  def initialize(date, region, amount)
    @date = date
    @region = region
    @amount = amount
  end
end

def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = y / 400
  yoe = y - era * 400
  doy = (153 * ((m + 9) % 12) + 2) / 5 + d - 1
  era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
end

def wday(z) = (z + 4) % 7

def ymd(s) = s.split("-").map(&:to_i)

class FiscalSpec
  attr_reader :name, :start_month

  def initialize(name, start_month)
    @name = name
    @start_month = start_month
  end

  # FY is named by the calendar year in which it ends (FY2027 = Apr 2026 .. Mar 2027).
  def quarter_of(date)
    y, m, _d = ymd(date)
    shifted = (m - @start_month + 12) % 12
    fy = @start_month == 1 || m < @start_month ? y : y + 1
    [fy, shifted / 3 + 1]
  end

  def label(fy, q) = format("FY%d Q%d", fy, q)
end

# Retail year: starts on the Sunday nearest Feb 1 of the calendar year.
def retail_start(y)
  feb1 = days_from_civil(y, 2, 1)
  w = wday(feb1)
  w <= 3 ? feb1 - w : feb1 + 7 - w
end

def retail_period(date)
  y, m, d = ymd(date)
  z = days_from_civil(y, m, d)
  ry = y
  ry -= 1 if z < retail_start(y)
  week = (z - retail_start(ry)) / 7
  weeks_in_year = (retail_start(ry + 1) - retail_start(ry)) / 7
  pattern = [4, 4, 5]
  period = 0
  left = week
  while period < 12 && left >= pattern[period % 3]
    left -= pattern[period % 3]
    period += 1
  end
  period = 11 if period > 11
  [ry, period + 1, week + 1, weeks_in_year]
end

RAW_SALES = <<~DATA
  2026-01-15 north 1200
  2026-02-02 south 800
  2026-03-28 north 1500
  2026-03-31 west 400
  2026-04-01 north 2200
  2026-05-19 south 950
  2026-06-30 west 1300
  2026-07-04 north 600
  2026-08-21 south 1750
  2026-09-30 west 2100
  2026-10-01 north 900
  2026-11-27 south 3200
  2026-12-24 north 2800
  2027-01-02 west 700
  2027-01-31 south 450
  2027-02-01 north 1000
  2027-03-15 west 1900
DATA

sales = RAW_SALES.lines.map do |line|
  date, region, amount = line.split
  Sale.new(date, region, amount.to_i)
end

specs = [FiscalSpec.new("Calendar", 1), FiscalSpec.new("April FY", 4), FiscalSpec.new("October FY", 10)]
specs.each do |spec|
  totals = Hash.new(0)
  sales.each { |s| totals[spec.quarter_of(s.date)] += s.amount }
  puts "#{spec.name}:"
  prev = nil
  totals.keys.sort.each do |key|
    fy, q = key
    amount = totals[key]
    growth = prev.nil? ? "" : format("  %+6.1f%%", (amount - prev) * 100.0 / prev)
    puts format("  %s %6d%s", spec.label(fy, q), amount, growth)
    prev = amount
  end
end

puts
puts "Retail 4-4-5 calendar:"
[2026, 2027].each do |y|
  start = retail_start(y)
  weeks = (retail_start(y + 1) - start) / 7
  puts format("  retail %d starts %d days after Jan 1, %d weeks", y, start - days_from_civil(y, 1, 1), weeks)
end
by_period = Hash.new(0)
sales.each do |s|
  ry, period, week, weeks = retail_period(s.date)
  by_period[[ry, period]] += s.amount
  puts format("  %s %-5s -> R%d P%02d W%02d/%d", s.date, s.region, ry, period, week, weeks)
end
best = by_period.max_by { |_key, amount| amount }
if best
  (ry, period), amount = best
  puts "Best period: R#{ry} P#{period} with #{amount}"
end

regions = sales.group_by(&:region)
grand = sales.sum(&:amount)
puts
regions.keys.sort.each do |region|
  list = regions.fetch(region)
  total = list.sum(&:amount)
  biggest = list.max_by(&:amount)
  share = Rational(total, grand)
  big = biggest ? biggest.date : "-"
  puts format("%-6s %5d  %5.1f%%  biggest on %s", region, total, share.to_f * 100, big)
end
