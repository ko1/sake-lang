class BadLine < StandardError; end

Employee = Struct.new(:id, :name, :rate, :shifts)
Shift = Struct.new(:day, :start, :length, :worked) do
  def from = day * 1440 + start
  def to = from + length
end

def hm(min) = format("%d:%02d", min / 60, min % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)

def parse_day(s)
  m = s.match(/\A(\d{4})-(\d\d)-(\d\d)\z/) or raise BadLine, "bad date"
  y, mo, d = m.captures.map(&:to_i)
  raise BadLine, "bad date" unless (1970..2099).cover?(y) && (1..12).cover?(mo) && (1..31).cover?(d)
  t = Time.new(y, mo, d, 0, 0, 0, "+00:00")
  raise BadLine, "bad date" unless t.month == mo
  t.to_i / 86_400
end

def parse_time(s)
  m = s.match(/\A(\d\d):(\d\d)\z/) or raise BadLine, "bad time"
  raise BadLine, "bad time" unless m[1].to_i < 24 && m[2].to_i < 60
  m[1].to_i * 60 + m[2].to_i
end

emps = {}
$stdin.each_line.with_index(1) do |raw, lineno|
  f = raw.split
  next if f.empty?
  begin
    case f[0]
    when "EMP"
      raise BadLine, "wrong field count" unless f.size == 4
      id, name, rate = f[1..]
      raise BadLine, "bad id" unless id.match?(/\AE\d{3,6}\z/)
      raise BadLine, "bad name" unless name.match?(/\A[A-Za-z]{1,10}\z/)
      m = rate.match(/\A(\d+)\.(\d\d)\z/) or raise BadLine, "bad rate"
      raise BadLine, "duplicate employee #{id}" if emps[id[1..].to_i]
      emps[id[1..].to_i] = Employee.new(id[1..].to_i, name, m[1].to_i * 100 + m[2].to_i, [])
    when "SHIFT"
      raise BadLine, "wrong field count" unless f.size == 5 || f.size == 6
      id = f[1]
      raise BadLine, "bad id" unless id.match?(/\AE\d{3,6}\z/)
      emp = emps[id[1..].to_i] or raise BadLine, "unknown employee #{id}"
      day = parse_day(f[2])
      start = parse_time(f[3])
      stop = parse_time(f[4])
      length = stop > start ? stop - start : stop + 1440 - start
      brk = f[5] || "0"
      raise BadLine, "bad break" unless brk.match?(/\A\d+\z/) && brk.to_i < length
      brk = brk.to_i
      brk = 30 if length > 360 && brk < 30
      s = Shift.new(day, start, length, length - brk)
      raise BadLine, "overlapping shift" if emp.shifts.any? { |o| o.from < s.to && s.from < o.to }
      emp.shifts << s
    else
      raise BadLine, "unknown command"
    end
  rescue BadLine => e
    puts "line #{lineno}: error: #{e.message}"
  end
end

# Splits worked minutes into regular and overtime: over 8h a day, then over 40h a Monday-based week.
def split_pay(emp)
  per_day = Hash.new(0)
  per_week = Hash.new(0)
  reg = ot = 0
  emp.shifts.sort_by(&:from).each do |s|
    r = [[480 - per_day[s.day], 0].max, s.worked].min
    per_day[s.day] += s.worked
    week = (s.day + 3) / 7
    w = [[2400 - per_week[week], 0].max, r].min
    per_week[week] += r
    reg += w
    ot += s.worked - w
  end
  [reg, ot]
end

puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
treg = tot = tpay = 0
emps.keys.sort.each do |num|
  e = emps[num]; id = format("E%03d", num)
  reg, ot = split_pay(e)
  pay = (reg * e.rate * 2 + ot * e.rate * 3 + 60) / 120
  treg += reg
  tot += ot
  tpay += pay
  puts format("%-4s %-10s %8s %8s %10s", id, e.name, hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(treg), hm(tot), money(tpay))
