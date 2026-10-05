# Business-day arithmetic for support tickets: working-day calendars with
# weekends and holidays, SLA due dates, and an overdue report.

require "set"

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

def date(s)
  m = s.match(/(\d+)-(\d+)-(\d+)/)
  raise ArgumentError, "bad date #{s}" unless m
  days_from_civil(m[1].to_i, m[2].to_i, m[3].to_i)
end

def show(z)
  y, m, d = civil_from_days(z)
  format("%04d-%02d-%02d", y, m, d)
end

def wday(z) = (z + 4) % 7

class WorkCalendar
  attr_reader :name, :weekend, :holidays

  def initialize(name, weekend, holidays)
    @name = name
    @weekend = weekend
    @holidays = holidays
  end

  def open?(z) = !@weekend.include?(wday(z)) && !@holidays.include?(z)

  # Moves n working days forward (or backward when n < 0).
  def add(z, n)
    step = n < 0 ? -1 : 1
    left = n.abs
    while left > 0
      z += step
      left -= 1 if open?(z)
    end
    z
  end

  # Working days in the half-open range (from, to].
  def between(from, to)
    return -between(to, from) if to < from
    ((from + 1)..to).count { |z| open?(z) }
  end

  def next_open(z)
    z += 1 until open?(z)
    z
  end
end

class Ticket
  attr_reader :id, :opened, :priority, :closed

  def initialize(id, opened, priority, closed)
    @id = id
    @opened = opened
    @priority = priority
    @closed = closed
  end
end

def sla_days(priority)
  case priority
  in :urgent then 1
  in :high then 3
  in :normal then 5
  in :low then 10
  end
end

holidays = ["2026-10-12", "2026-11-11", "2026-11-26", "2026-11-27", "2026-12-25", "2027-01-01"].map { |s| date(s) }.to_set
us = WorkCalendar.new("US office", Set[0, 6], holidays)
gulf = WorkCalendar.new("Gulf office", Set[5, 6], Set[date("2026-12-02")])

puts "Adding working days from Fri 2026-10-09:"
start = date("2026-10-09")
[1, 2, 5, 10, 30, -1, -5].each do |n|
  puts format("  %+3d  US %s   Gulf %s", n, show(us.add(start, n)), show(gulf.add(start, n)))
end

ranges = [["2026-10-01", "2026-10-31"], ["2026-11-01", "2026-11-30"], ["2026-12-20", "2027-01-05"], ["2026-11-30", "2026-11-01"]]
ranges.each do |a, b|
  puts format("Working days %s..%s: US %3d, Gulf %3d", a, b, us.between(date(a), date(b)), gulf.between(date(a), date(b)))
end

tickets = [
  Ticket.new(501, date("2026-11-20"), :high, date("2026-11-25")),
  Ticket.new(502, date("2026-11-24"), :urgent, date("2026-11-30")),
  Ticket.new(503, date("2026-11-25"), :normal, nil),
  Ticket.new(504, date("2026-12-18"), :low, date("2027-01-04")),
  Ticket.new(505, date("2026-12-23"), :high, nil),
  Ticket.new(506, date("2026-10-10"), :normal, date("2026-10-16")),
  Ticket.new(507, date("2026-12-28"), :urgent, nil)
]

today = date("2026-12-31")
puts
puts "Tickets (today #{show(today)}):"
late = []
tickets.each do |t|
  opened = us.next_open(t.opened)
  due = us.add(opened, sla_days(t.priority))
  closed = t.closed
  status =
    if closed
      closed <= due ? "met" : "missed by #{us.between(due, closed)}"
    elsif today > due
      "OVERDUE #{us.between(due, today)}"
    else
      "open, #{us.between(today, due)} left"
    end
  late << t if status.start_with?("missed") || status.start_with?("OVERDUE")
  puts format("  #%d %-7s opened %s due %s  %s", t.id, t.priority.to_s, show(t.opened), show(due), status)
end
by_priority = late.map(&:priority).tally
puts "Late by priority: #{by_priority.map { |pr, n| "#{pr}=#{n}" }.join(" ")}"
