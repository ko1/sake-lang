require "date"

def hm(m) = format("%d:%02d", m / 60, m % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)

emps = {} # id => [name, rate_cents, shifts]  shift = [start_abs, end_abs, break, date]

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  err = nil
  if !%w[EMP SHIFT].include?(cmd)
    err = "unknown command"
  elsif cmd == "EMP" ? f.size != 4 : !(5..6).cover?(f.size)
    err = "wrong field count"
  elsif cmd == "EMP"
    err = if f[1] !~ /\AE\d{3}\z/ then "bad id"
          elsif f[2] !~ /\A[A-Za-z]{1,10}\z/ then "bad name"
          elsif f[3] !~ /\A\d+\.\d\d\z/ then "bad rate"
          elsif emps.key?(f[1]) then "duplicate employee #{f[1]}"
          end
    unless err
      emps[f[1]] = [f[2], f[3].delete(".").to_i, []]
    end
  else
    id, date, st, en, brk = f[1], f[2], f[3], f[4], f[5] || "0"
    d = nil
    if date =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && (1970..2099).cover?($1.to_i) && Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
      d = Date.new($1.to_i, $2.to_i, $3.to_i)
    end
    tm = lambda do |s|
      s =~ /\A(\d\d):(\d\d)\z/ && $1.to_i <= 23 && $2.to_i <= 59 ? $1.to_i * 60 + $2.to_i : nil
    end
    s = tm.call(st) if d
    e = tm.call(en) if d
    err = if id !~ /\AE\d{3}\z/ then "bad id"
          elsif !emps.key?(id) then "unknown employee #{id}"
          elsif d.nil? then "bad date"
          elsif s.nil? || e.nil? then "bad time"
          end
    unless err
      e += 1440 if e <= s
      len = e - s
      if brk !~ /\A\d+\z/ || brk.to_i >= len
        err = "bad break"
      else
        base = d.jd * 1440
        a = base + s
        b = base + e
        if emps[id][2].any? { |x| x[0] < b && a < x[1] }
          err = "overlapping shift"
        else
          emps[id][2] << [a, b, brk.to_i, d]
        end
      end
    end
  end
  puts "line #{no}: error: #{err}" if err
end

puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
tr = to = tp = 0
emps.keys.sort_by(&:b).each do |id|
  name, rate, shifts = emps[id]
  day = Hash.new(0)
  week = Hash.new(0)
  reg = ot = 0
  shifts.sort_by { |x| x[0] }.each do |a, b, brk, d|
    len = b - a
    brk = 30 if len > 360 && brk < 30
    w = len - brk
    od = [w, [0, day[d] + w - 480].max].min
    day[d] += w
    r = w - od
    wk = d.jd - d.cwday + 1
    ow = [r, [0, week[wk] + r - 2400].max].min
    week[wk] += r
    reg += r - ow
    ot += od + ow
  end
  num = 2 * reg * rate + 3 * ot * rate
  pay = (num * 2 + 120) / 240
  tr += reg
  to += ot
  tp += pay
  puts format("%-4s %-10s %8s %8s %10s", id, name, hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(tr), hm(to), money(tp))
