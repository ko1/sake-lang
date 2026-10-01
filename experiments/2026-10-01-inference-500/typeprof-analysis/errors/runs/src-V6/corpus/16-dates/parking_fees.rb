# Parking fees from entry/exit timestamps: a grace period, day and night
# tariffs charged per started block, a daily cap per calendar day, weekend
# rates, and monthly pass holders.

require "set"

class Tariff
  attr_reader :day_block, :day_rate, :night_block, :night_rate, :daily_cap, :grace

  def initialize(day_block, day_rate, night_block, night_rate, daily_cap, grace)
    @day_block = day_block
    @day_rate = day_rate
    @night_block = night_block
    @night_rate = night_rate
    @daily_cap = daily_cap
    @grace = grace
  end

  # Charge one calendar day's portion [from, to): blocks start at `from` and
  # take the rate of the period they start in.
  def charge_day(from, to)
    cents = 0
    at = from
    while at < to
      if night?(at)
        cents += @night_rate
        at += @night_block
      else
        cents += @day_rate
        at += @day_block
      end
    end
    [cents, @daily_cap].min
  end
end

class Visit
  attr_reader :plate, :entry, :exit

  def initialize(plate, entry, exit)
    @plate = plate
    @entry = entry
    @exit = exit
  end
end

class BadVisit < StandardError
  attr_reader :plate

  def initialize(message, plate)
    super(message)
    @plate = plate
  end
end

def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = y / 400
  yoe = y - era * 400
  doy = (153 * ((m + 9) % 12) + 2) / 5 + d - 1
  era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
end

def ts(s)
  m = s.match(/\A(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})\z/)
  raise ArgumentError, "bad timestamp: #{s}" unless m
  y, mo, d, h, mi = m.captures.map(&:to_i)
  raise ArgumentError, "no such time: #{s}" if h > 23 || mi > 59
  (days_from_civil(y, mo, d) * 24 + h) * 60 + mi
end

def weekend?(minute) = (minute / 1440 + 4) % 7 >= 5

def night?(minute)
  h = (minute % 1440) / 60
  h >= 20 || h < 7
end

WEEKDAY_TARIFF = Tariff.new(30, 250, 60, 150, 2400, 15)
WEEKEND_TARIFF = Tariff.new(60, 300, 60, 150, 1800, 15)

def money(c) = format("%d.%02d", c / 100, c % 100)

def fee(visit, passes)
  entry = visit.entry
  leave = visit.exit
  raise BadVisit.new("exit before entry", visit.plate) if leave < entry
  return [0, "pass"] if passes.include?(visit.plate)
  return [0, "grace"] if leave - entry <= WEEKDAY_TARIFF.grace
  total = 0
  parts = []
  day_start = entry
  while day_start < leave
    midnight = (day_start / 1440 + 1) * 1440
    day_end = [midnight, leave].min
    tariff = weekend?(day_start) ? WEEKEND_TARIFF : WEEKDAY_TARIFF
    c = tariff.charge_day(day_start, day_end)
    total += c
    parts << money(c)
    day_start = day_end
  end
  [total, parts.join("+")]
end

RAW_VISITS = [
  ["KA-101", "2026-09-28 08:10", "2026-09-28 08:20"],
  ["KA-102", "2026-09-28 08:10", "2026-09-28 09:45"],
  ["KA-103", "2026-09-28 18:30", "2026-09-28 22:10"],
  ["KA-104", "2026-09-28 07:00", "2026-09-28 19:00"],
  ["KA-105", "2026-09-29 22:00", "2026-09-30 08:30"],
  ["KA-106", "2026-10-02 17:00", "2026-10-05 09:00"],
  ["KA-107", "2026-10-03 10:00", "2026-10-03 13:00"],
  ["PASS-1", "2026-09-28 06:00", "2026-09-28 23:00"],
  ["KA-108", "2026-09-30 12:00", "2026-09-30 11:00"],
  ["KA-109", "2026-09-30 25:00", "2026-09-30 26:00"]
]

passes = Set["PASS-1"]
revenue = Hash.new(0)
stays = []
RAW_VISITS.each do |plate, a, b|
  visit = Visit.new(plate, ts(a), ts(b))
  cents, how = fee(visit, passes)
  mins = visit.exit - visit.entry
  stays << [plate, mins, cents]
  revenue[a.split(" ")[0]] += cents
  puts format("%-7s %s -> %s  %3dh%02dm  %7s  %s", plate, a, b.split(" ")[1], mins / 60, mins % 60, money(cents), how)
rescue BadVisit => e
  puts format("%-7s rejected: %s", e.plate, e.message)
rescue ArgumentError => e
  puts format("%-7s rejected: %s", plate, e.message)
end

puts
puts "Revenue by entry day:"
revenue.keys.sort.each { |day| puts "  #{day}  #{money(revenue[day])}" }
paying = stays.select { |_plate, _mins, cents| cents > 0 }
total = paying.sum { |_plate, _mins, cents| cents }
hours = paying.sum { |_plate, mins, _cents| mins }
puts "Paying visits: #{paying.size}, total #{money(total)}, average #{money(total / paying.size)}"
puts "Average per hour parked: #{money(total * 60 / hours)}"
longest = stays.max_by { |_plate, mins, _cents| mins }
if longest
  plate, mins, cents = longest
  puts "Longest stay: #{plate} #{mins / 1440}d #{mins % 1440 / 60}h, paid #{money(cents)}"
end
