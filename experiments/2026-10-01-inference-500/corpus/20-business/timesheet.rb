class Shift
  attr_reader :day, :start, :finish

  def initialize(day, start, finish)
    @day = day
    @start = start
    @finish = finish
  end

  def minutes = finish - start
end

class EntryError < StandardError
  attr_reader :employee, :day

  def initialize(message, employee, day)
    super(message)
    @employee = employee
    @day = day
  end
end

RATES = { "Aiko" => 24.0, "Ben" => 19.5, "Cleo" => 31.0 }

# clock times are rounded to the nearest quarter hour
def round_quarter(min) = (min + 7) / 15 * 15

def parse_clock(s)
  m = s.strip.match(/\A(\d{1,2}):(\d\d)\z/)
  raise ArgumentError, "unreadable time '#{s.strip}'" unless m
  m[1].to_i * 60 + m[2].to_i
end

def fmt_hours(min) = format("%d:%02d", min / 60, min % 60)

def parse_day(employee, line)
  day, rest = line.split(" ", 2)
  shifts = rest.split(",").map do |part|
    a, b = part.split("-")
    start = round_quarter(parse_clock(a))
    finish = round_quarter(parse_clock(b))
    raise EntryError.new("#{part.strip} ends before it starts", employee, day) if finish <= start
    Shift.new(day, start, finish)
  end
  sorted = shifts.sort_by(&:start)
  sorted.each_cons(2) do |a, b|
    raise EntryError.new("overlapping shifts", employee, day) if b.start < a.finish
  end
  sorted
end

# a day over 6 hours needs a 30-minute break; if none was taken, 30 minutes are deducted
def paid_minutes(shifts)
  worked = shifts.sum(&:minutes)
  longest_gap = shifts.each_cons(2).map { |a, b| b.start - a.finish }.max || 0
  worked > 360 && longest_gap < 30 ? worked - 30 : worked
end

timesheets = {
  "Aiko" => "Mon 08:55-12:31, 13:02-17:40\nTue 09:00-17:10\nWed 08:50-12:00\nThu 09:05-13:00, 13:30-19:20\nFri 09:00-15:00",
  "Ben" => "Mon 10:00-18:00\nTue 10:00-14:00, 13:30-18:00\nWed 10:00-18:30\nThu 18:00-10:00\nFri 10:00-1x:00",
  "Cleo" => "Mon 07:00-11:00\nWed 07:00-11:00, 11:30-15:45\nSat 08:00-12:07"
}

payroll = []
timesheets.each do |employee, text|
  puts "#{employee}:"
  week = 0
  daily_overtime = 0
  text.lines.each do |line|
    begin
      shifts = parse_day(employee, line.chomp)
    rescue EntryError => e
      puts "  #{e.day}: REJECTED #{e.message}"
      next
    rescue ArgumentError => e
      puts "  #{line.chomp}: REJECTED #{e.message}"
      next
    end
    paid = paid_minutes(shifts)
    over = [paid - 480, 0].max
    week += paid
    daily_overtime += over
    spans = shifts.map { |s| "#{fmt_hours(s.start)}-#{fmt_hours(s.finish)}" }
    note = over > 0 ? "  (+#{fmt_hours(over)} OT)" : ""
    puts format("  %s %-24s %6s%s", shifts.first.day, spans.join(" "), fmt_hours(paid), note)
  end
  weekly_overtime = [week - 2400, 0].max
  overtime = [daily_overtime, weekly_overtime].max
  rate = RATES.fetch(employee)
  pay = (week - overtime) / 60.0 * rate + overtime / 60.0 * rate * 1.5
  puts "  total #{fmt_hours(week)}, overtime #{fmt_hours(overtime)}, pay #{format("%.2f", pay)}"
  payroll << [employee, week, pay]
end

puts
total_pay = payroll.sum { |_e, _w, p| p }
payroll.each do |e, w, p|
  puts format("%-5s %6s %8.2f %5.1f%%", e, fmt_hours(w), p, p * 100 / total_pay)
end
puts format("%-5s %6s %8.2f", "all", fmt_hours(payroll.sum { |_e, w, _p| w }), total_pay)
