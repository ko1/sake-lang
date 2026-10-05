# Expands recurrence rules (every N days, weekly on given weekdays, monthly on a
# day, monthly on the nth weekday, yearly) into concrete dates in a window.

class Event
  attr_reader :title, :first, :rule, :count

  def initialize(title, first, rule, count)
    @title = title
    @first = first
    @rule = rule
    @count = count
  end
end

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
  d = doy - (153 * mp + 2) / 5 + 1
  m = mp < 10 ? mp + 3 : mp - 9
  [yoe + era * 400 + (m <= 2 ? 1 : 0), m, d]
end

def wday(z) = (z + 4) % 7

def days_in_month(y, m)
  ny = m == 12 ? y + 1 : y
  nm = m == 12 ? 1 : m + 1
  days_from_civil(ny, nm, 1) - days_from_civil(y, m, 1)
end

def parse(s)
  y, m, d = s.split("-").map(&:to_i)
  days_from_civil(y, m, d)
end

def show(z)
  y, m, d = civil_from_days(z)
  format("%04d-%02d-%02d %s", y, m, d, %w[Sun Mon Tue Wed Thu Fri Sat][wday(z)])
end

# nth = 1..4 counts from the start of the month, -1 means the last one.
def nth_weekday(y, m, nth, wd)
  if nth > 0
    first = days_from_civil(y, m, 1)
    first + (wd - wday(first) + 7) % 7 + (nth - 1) * 7
  else
    last = days_from_civil(y, m, days_in_month(y, m))
    last - (wday(last) - wd + 7) % 7
  end
end

def months_from(z, to)
  y, m, _d = civil_from_days(z)
  while days_from_civil(y, m, 1) <= to
    yield y, m
    m += 1
    if m > 12
      m = 1
      y += 1
    end
  end
end

def occurrences(ev, from, to)
  start = parse(ev.first)
  out = []
  case ev.rule
  in {every_days:}
    z = start
    while z <= to
      out << z
      z += every_days
    end
  in {weekdays:}
    (start..to).each { |z| out << z if weekdays.include?(wday(z)) }
  in {month_day:}
    months_from(start, to) do |y, m|
      z = days_from_civil(y, m, [month_day, days_in_month(y, m)].min)
      out << z if z >= start && z <= to
    end
  in {nth:, wd:}
    months_from(start, to) do |y, m|
      z = nth_weekday(y, m, nth, wd)
      out << z if z >= start && z <= to
    end
  in {yearly:}
    y, m, d0 = civil_from_days(start)
    z = start
    while z <= to
      out << z
      y += 1
      z = days_from_civil(y, m, [d0, days_in_month(y, m)].min)
    end
  end
  out = out.take(ev.count) if ev.count
  out.select { |z| z >= from }
end

events = [
  Event.new("Standup", "2026-09-28", {weekdays: [1, 2, 3, 4, 5]}, nil),
  Event.new("Plant watering", "2026-09-20", {every_days: 9}, nil),
  Event.new("Rent", "2026-01-31", {month_day: 31}, nil),
  Event.new("Board meeting", "2026-01-01", {nth: 2, wd: 2}, nil),
  Event.new("Payroll", "2026-01-01", {nth: -1, wd: 5}, nil),
  Event.new("Leap birthday", "2024-02-29", {yearly: true}, nil),
  Event.new("Course", "2026-09-07", {weekdays: [1, 3]}, 10)
]

from = parse("2026-10-01")
to = parse("2027-03-31")
puts "Window: #{show(from)} .. #{show(to)}"
all = []
events.each do |ev|
  dates = occurrences(ev, from, to)
  dates.each { |z| all << [z, ev.title] }
  preview = dates.take(3).map { |z| show(z) }
  puts format("%-15s %3d: %s%s", ev.title, dates.size, preview.join(", "), dates.size > 3 ? ", ..." : "")
end

puts
puts "Agenda for the first week of February 2027:"
week_start = parse("2027-02-01")
week = all.select { |z, _title| z >= week_start && z < week_start + 7 }
week.sort_by { |z, title| [z, title.size] }.each do |z, title|
  puts "  #{show(z)}  #{title}"
end

busy = all.map(&:first).tally
max_n = busy.values.max
crowded = busy.select { |_z, n| n == max_n }.keys.sort
puts "Most events on one day: #{max_n}, on #{crowded.size} days, first #{show(crowded.first)}"
