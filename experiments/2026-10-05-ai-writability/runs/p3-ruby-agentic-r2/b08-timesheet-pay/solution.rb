require 'date'
def money(c) = format("%d.%02d", c / 100, c % 100)
def hm(m) = format("%d:%02d", m / 60, m % 60)
emps = {}
shifts = Hash.new { |h, k| h[k] = [] }
$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = ->(m) { puts "line #{n}: error: #{m}" }
  case f[0]
  when "EMP"
    (err.("wrong field count"); next) unless f.size == 4
    (err.("bad id"); next) unless f[1] =~ /\AE\d{3}\z/
    (err.("bad name"); next) unless f[2] =~ /\A[A-Za-z]{1,10}\z/
    (err.("bad rate"); next) unless f[3] =~ /\A(\d+)\.(\d\d)\z/
    rate = $1.to_i * 100 + $2.to_i
    (err.("duplicate employee #{f[1]}"); next) if emps.key?(f[1])
    emps[f[1]] = [f[2], rate]
  when "SHIFT"
    (err.("wrong field count"); next) unless f.size == 5 || f.size == 6
    id = f[1]
    (err.("bad id"); next) unless id =~ /\AE\d{3}\z/
    (err.("unknown employee #{id}"); next) unless emps.key?(id)
    unless f[2] =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && $1.to_i.between?(1970, 2099) && Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
      err.("bad date"); next
    end
    date = Date.new($1.to_i, $2.to_i, $3.to_i)
    tm = ->(s) { s =~ /\A(\d\d):(\d\d)\z/ && $1.to_i <= 23 && $2.to_i <= 59 ? $1.to_i * 60 + $2.to_i : nil }
    s = tm.(f[3]); e = tm.(f[4])
    (err.("bad time"); next) unless s && e
    len = e > s ? e - s : e - s + 1440
    brk = 0
    if f[5]
      (err.("bad break"); next) unless f[5] =~ /\A\d+\z/ && f[5].to_i < len
      brk = f[5].to_i
    end
    st = date.jd * 1440 + s
    en = st + len
    if shifts[id].any? { |a| st < a[1] && a[0] < en }
      err.("overlapping shift"); next
    end
    brk = 30 if len > 360 && brk < 30
    shifts[id] << [st, en, date, len - brk]
  else
    err.("unknown command")
  end
end
puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
tr = to = tp = 0
emps.keys.sort.each do |id|
  name, rate = emps[id]
  reg = ot = 0
  day = Hash.new(0); week = Hash.new(0)
  shifts[id].sort_by { |a| a[0] }.each do |_, _, date, w|
    d = day[date]
    o1 = [w, [0, d + w - 480].max].min
    rest = w - o1
    wk = date - ((date.wday + 6) % 7)
    o2 = [rest, [0, week[wk] + rest - 2400].max].min
    r = rest - o2
    week[wk] += r; day[date] += w
    reg += r; ot += o1 + o2
  end
  pay = (reg * rate * 2 + ot * rate * 3 + 60) / 120
  tr += reg; to += ot; tp += pay
  puts format("%-4s %-10s %8s %8s %10s", id, name, hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(tr), hm(to), money(tp))
