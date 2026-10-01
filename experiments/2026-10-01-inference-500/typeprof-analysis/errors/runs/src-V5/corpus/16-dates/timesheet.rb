# Payroll from clock punches: pairs IN/OUT events (shifts may cross midnight),
# flags broken sequences, splits hours into day/night, and applies daily and
# weekly overtime rules.

class Punch
  attr_reader :who, :kind, :at

  def initialize(who, kind, at)
    @who = who
    @kind = kind
    @at = at
  end
end

class Shift
  attr_reader :who, :start, :finish

  def initialize(who, start, finish)
    @who = who
    @start = start
    @finish = finish
  end
end

class PunchError < StandardError
  attr_reader :who, :at

  def initialize(message, who, at)
    super(message)
    @who = who
    @at = at
  end
end

def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = y / 400
  yoe = y - era * 400
  doy = (153 * ((m + 9) % 12) + 2) / 5 + d - 1
  era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
end

def parse_time(s)
  m = s.match(/\A(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})\z/)
  raise ArgumentError, "bad timestamp #{s}" if !m    
  y, mo, d, h, mi = m.captures.map(&:to_i)
  (days_from_civil(y, mo, d) * 24 + h) * 60 + mi
end

def hm(mins) = format("%d:%02d", mins / 60, mins % 60)

def stamp(t) = format("%s %02d:%02d", %w[Thu Fri Sat Sun Mon Tue Wed][t / 1440 % 7], (t % 1440) / 60, t % 60)

LOG_TEXT = <<~LOG
  ana IN 2026-09-28 08:58
  ana OUT 2026-09-28 17:30
  ben IN 2026-09-28 21:55
  ana IN 2026-09-29 09:05
  ben OUT 2026-09-29 06:10
  ana OUT 2026-09-29 19:45
  ben IN 2026-09-29 22:00
  ben OUT 2026-09-30 06:00
  ana IN 2026-09-30 08:30
  ana IN 2026-09-30 12:30
  ana OUT 2026-09-30 17:00
  cat IN 2026-09-30 10:00
  ben IN 2026-09-30 22:05
  ben OUT 2026-10-01 07:30
  cat OUT 2026-09-30 14:00
  ana IN 2026-10-01 07:00
  ana OUT 2026-10-01 19:00
  cat OUT 2026-10-01 18:00
  ben IN 2026-10-01 22:00
  ben OUT 2026-10-02 06:00
  ana IN 2026-10-02 08:00
  ana OUT 2026-10-02 18:30
  ben IN 2026-10-02 21:30
LOG

def load_punches
  LOG_TEXT.lines.map do |line|
    who, kind, date, time = line.split
    Punch.new(who, kind.to_sym, parse_time("#{date} #{time}"))
  end
end

def pair_shifts(punches, problems)
  open = {}
  shifts = []
  punches.sort_by(&:at).each do |p|
    who = p.who
    begin
      case p.kind
      in :IN
        raise PunchError.new("IN while already in since #{stamp(open[who])}", who, p.at) if open[who]
        open[who] = p.at
      in :OUT
        start = open[who]
        raise PunchError.new("OUT without IN", who, p.at) if !start    
        open.delete(who)
        raise PunchError.new("shift longer than 16h", who, p.at) if p.at - start > 16 * 60
        shifts << Shift.new(who, start, p.at)
      end
    rescue PunchError => e
      problems << "#{e.who} at #{stamp(e.at)}: #{e.message}"
    end
  end
  open.each { |who, at| problems << "#{who} at #{stamp(at)}: still clocked in" }
  shifts
end

# Minutes between 22:00 and 06:00 within [start, finish).
def night_minutes(start, finish)
  total = 0
  day = start / 1440 - 1
  while day * 1440 < finish
    [[day * 1440, day * 1440 + 360], [day * 1440 + 1320, day * 1440 + 1440]].each do |a, b|
      lo = [a, start].max
      hi = [b, finish].min
      total += hi - lo if hi > lo
    end
    day += 1
  end
  total
end

problems = []
shifts = pair_shifts(load_punches, problems)
puts "Problems:"
problems.each { |s| puts "  #{s}" }

rate = { "ana" => 2400, "ben" => 2600, "cat" => 2200 }
puts
puts "Who  shifts   worked  night  daily-OT  weekly-OT     pay"
shifts.map(&:who).uniq.sort.each do |who|
  mine = shifts.select { |s| s.who == who }
  worked = 0
  night = 0
  daily_ot = 0
  mine.each do |s|
    len = s.finish - s.start
    worked += len
    night += night_minutes(s.start, s.finish)
    daily_ot += len - 600 if len > 600
  end
  weekly_ot = [worked - daily_ot - 40 * 60, 0].max
  cents = rate.fetch(who, 2000)
  pay = (worked * cents + (daily_ot + weekly_ot) * cents / 2 + night * cents / 4) / 60
  puts format("%-4s %6d %8s %6s %9s %10s %7.2f", who, mine.size, hm(worked), hm(night), hm(daily_ot), hm(weekly_ot), pay / 100.0)
end

longest = shifts.max_by { |s| s.finish - s.start }
if longest
  puts "Longest shift: #{longest.who} #{stamp(longest.start)} -> #{stamp(longest.finish)} (#{hm(longest.finish - longest.start)})"
end
