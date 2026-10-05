# Builds a four-week shift rota greedily: three shifts a day, rest rules
# (11 hours between shifts, at most 5 shifts per week), requested days off,
# and fairness by fewest hours so far. Then prints the rota and per-person totals.

require "set"

class Shift
  attr_reader :name, :start, :hours

  def initialize(name, start, hours)
    @name = name
    @start = start
    @hours = hours
  end
end

SHIFTS = [Shift.new("E", 6, 8), Shift.new("L", 14, 8), Shift.new("N", 22, 8)]
DOW_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

class Worker
  attr_reader :name, :off, :assigned, :hours

  def initialize(name, off)
    @name = name
    @off = off
    @assigned = []
    @hours = 0
  end

  # Absolute hour at which the worker's last shift ended, or nil.
  def last_end
    return nil if @assigned.empty?
    day, shift = @assigned.last
    day * 24 + shift.start + shift.hours
  end

  def shifts_in_week(week) = @assigned.count { |day, _shift| day / 7 == week }

  def can_take?(day, shift)
    return false if @off.include?(day)
    return false if @assigned.any? { |d, _s| d == day }
    return false if shifts_in_week(day / 7) >= 5
    ended = last_end
    return true if ended.nil?
    day * 24 + shift.start - ended >= 11
  end

  def take(day, shift)
    @assigned << [day, shift]
    @hours += shift.hours
  end
end

def build_rota(workers, days)
  rota = []
  gaps = []
  days.times do |day|
    row = SHIFTS.map do |shift|
      candidates = workers.select { |w| w.can_take?(day, shift) }
      pick = candidates.min_by { |w| [w.hours, workers.index(w)] }
      if pick
        pick.take(day, shift)
        pick.name
      else
        gaps << [day, shift.name]
        "--"
      end
    end
    rota << row
  end
  [rota, gaps]
end

workers = [
  Worker.new("Ada", Set[5, 6]),
  Worker.new("Bo", Set[0, 1, 2]),
  Worker.new("Cy", Set[]),
  Worker.new("Di", Set[12, 13, 19, 20]),
  Worker.new("Ed", Set[7, 8, 9, 10, 11]),
  Worker.new("Flo", Set[26, 27])
]

rota, gaps = build_rota(workers, 28)

puts "Day        " + SHIFTS.map { |s| format("%-4s", "#{s.name}#{format("%02d", s.start)}") }.join(" ")
rota.each_with_index do |row, day|
  sep = day % 7 == 6 ? "\n" : ""
  puts format("W%d %s %2d  %s%s", day / 7 + 1, DOW_NAMES[day % 7], day + 1, row.map { |n| format("%-4s", n) }.join(" "), sep)
end

puts "Unfilled: #{gaps.size}#{gaps.empty? ? "" : " " + gaps.map { |d, s| "day#{d + 1}/#{s}" }.join(", ")}"
puts
puts "Who     hours  E  L  N  weekend  max-in-a-week"
workers.each do |w|
  kinds = w.assigned.map { |_day, shift| shift.name }.tally
  weekend = w.assigned.count { |day, _shift| day % 7 >= 5 }
  per_week = (0..3).map { |wk| w.shifts_in_week(wk) }
  puts format("%-6s %6d %2d %2d %2d %8d %8d", w.name, w.hours,
              kinds.fetch("E", 0), kinds.fetch("L", 0), kinds.fetch("N", 0), weekend, per_week.max)
end

hours = workers.map(&:hours)
puts "Spread between most and least hours: #{hours.max - hours.min}"

violations = 0
workers.each do |w|
  ends = w.assigned.map { |day, shift| [day * 24 + shift.start, day * 24 + shift.start + shift.hours] }
  ends.each_cons(2) do |a, b|
    violations += 1 if b[0] - a[1] < 11
  end
end
puts "Rest-rule violations: #{violations}"
