class Worker
  attr_reader :name, :rate, :exempt

  def initialize(name, rate, exempt)
    @name = name
    @rate = rate
    @exempt = exempt
  end
end

class Shift
  attr_reader :worker, :week, :day, :minutes

  def initialize(worker, week, day, minutes)
    @worker = worker
    @week = week
    @day = day
    @minutes = minutes
  end
end

def workers
  {
    "kim" => Worker.new("Kim", 22.50, false),
    "raj" => Worker.new("Raj", 31.00, false),
    "zoe" => Worker.new("Zoe", 27.75, false),
    "bo" => Worker.new("Bo", 45.00, true)
  }
end

def timesheet
  <<~TXT
    W14 kim Mon 08:00-16:30 Tue 08:00-17:00 Wed 08:00-16:30 Thu 08:00-18:15 Fri 08:00-16:00
    W14 raj Mon 09:00-17:00 Tue 09:00-17:00 Wed 09:00-21:00 Thu 09:00-17:00 Fri 09:00-17:00 Sat 10:00-14:00
    W14 zoe Mon 12:00-20:00 Wed 12:00-20:00 Fri 12:00-16:45
    W14 bo Mon 07:00-19:00 Tue 07:00-19:00 Wed 07:00-19:00 Thu 07:00-15:00
    W15 kim Mon 08:00-16:00 Tue 08:00-16:00 Wed 08:00-16:00 Thu 08:00-16:00 Fri 08:00-16:00
    W15 raj Mon 09:00-17:30 Tue 09:00-17:30 Wed 09:00-17:30 Thu 09:00-17:30 Fri 09:00-17:30
    W15 zoe Mon 12:00-23:30 Tue 12:00-22:00 Thu 22:00-06:00 Sat 12:00-20:00
    W15 lee Mon 09:00-17:00
  TXT
end

def to_minutes(hhmm)
  h, m = hhmm.split(":")
  h.to_i * 60 + m.to_i
end

def parse_shifts(text)
  text.lines.flat_map do |line|
    week, who, *rest = line.split
    rest.each_slice(2).map do |day, span|
      from, to = span.split("-")
      start = to_minutes(from)
      stop = to_minutes(to)
      stop += 24 * 60 if stop <= start
      Shift.new(who, week, day, stop - start)
    end
  end
end

def hours(min) = format("%5.2f", min / 60.0)

def split_overtime(day_minutes)
  daily_regular = day_minutes.map { |m| [m, 8 * 60].min }
  daily_ot = day_minutes.sum - daily_regular.sum
  regular = daily_regular.sum
  weekly_ot = regular > 40 * 60 ? regular - 40 * 60 : 0
  [regular - weekly_ot, daily_ot + weekly_ot]
end

staff = workers
shifts = parse_shifts(timesheet)
unknown = shifts.filter_map { |s| s.worker unless staff.key?(s.worker) }.uniq
known = shifts.select { |s| staff.key?(s.worker) }

grand = 0.0
known.group_by(&:worker).each do |id, list|
  w = staff.fetch(id)
  rate = w.rate
  puts "#{w.name} (#{w.exempt ? "exempt" : format("$%.2f/h", rate)})"
  total_pay = 0.0
  list.group_by(&:week).each do |week, ws|
    mins = ws.map(&:minutes)
    if w.exempt
      reg = mins.sum
      ot = 0
      pay = rate * 40
    else
      reg, ot = split_overtime(mins)
      pay = reg / 60.0 * rate + ot / 60.0 * rate * 1.5
    end
    long = ws.select { |s| s.minutes > 10 * 60 }
    warn = long.empty? ? "" : "  long shift: #{long.map(&:day).join(",")}"
    puts format("  %s days=%d regular=%s overtime=%s pay=%9.2f%s", week, ws.size, hours(reg), hours(ot), pay, warn)
    total_pay += pay
  end
  puts format("  total %.2f", total_pay)
  grand += total_pay
end
puts
puts format("Payroll total: %.2f", grand)
puts "Unknown worker ids: #{unknown.join(", ")}" unless unknown.empty?
