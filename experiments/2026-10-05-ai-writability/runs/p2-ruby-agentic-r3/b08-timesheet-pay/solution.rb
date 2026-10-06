require 'date'

emps = {}   # id => {name:, rate:, shifts: []}
out = []

def hm(m) = format("%d:%02d", m / 60, m % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(/ +/).reject(&:empty?)
  err = ->(m) { out << "line #{n}: error: #{m}" }
  case f[0]
  when "EMP"
    (err.("wrong field count"); next) if f.size != 4
    (err.("bad id"); next) unless f[1] =~ /\AE\d{3}\z/
    (err.("bad name"); next) unless f[2] =~ /\A[A-Za-z]{1,10}\z/
    (err.("bad rate"); next) unless f[3] =~ /\A(\d+)\.(\d\d)\z/
    rate = $1.to_i * 100 + $2.to_i
    (err.("duplicate employee #{f[1]}"); next) if emps[f[1]]
    emps[f[1]] = { name: f[2], rate: rate, shifts: [] }
  when "SHIFT"
    (err.("wrong field count"); next) unless [5, 6].include?(f.size)
    (err.("bad id"); next) unless f[1] =~ /\AE\d{3}\z/
    e = emps[f[1]]
    (err.("unknown employee #{f[1]}"); next) unless e
    ok = false
    if f[2] =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && (1970..2099).cover?($1.to_i) &&
       Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
      date = Date.new($1.to_i, $2.to_i, $3.to_i)
      ok = true
    end
    (err.("bad date"); next) unless ok
    tm = ->(s) { s =~ /\A(\d\d):(\d\d)\z/ && $1.to_i <= 23 && $2.to_i <= 59 ? $1.to_i * 60 + $2.to_i : nil }
    st = tm.(f[3])
    en = tm.(f[4])
    (err.("bad time"); next) unless st && en
    len = en - st
    len += 1440 if len <= 0
    brk = 0
    if f[5]
      (err.("bad break"); next) unless f[5] =~ /\A\d+\z/ && f[5].to_i < len
      brk = f[5].to_i
    end
    s = date.jd * 1440 + st
    t = s + len
    if e[:shifts].any? { |o| s < o[:e] && o[:s] < t }
      err.("overlapping shift"); next
    end
    brk = 30 if len > 360 && brk < 30
    e[:shifts] << { s: s, e: t, date: date.jd, week: date.jd - (date.cwday - 1), worked: len - brk }
  else
    err.("unknown command")
  end
end

rows = []
emps.keys.sort.each do |id|
  e = emps[id]
  daily = Hash.new(0)
  weekly = Hash.new(0)
  reg = ot = 0
  e[:shifts].sort_by { |x| x[:s] }.each do |x|
    w = x[:worked]
    d_ot = [w, [0, daily[x[:date]] + w - 480].max].min
    daily[x[:date]] += w
    rest = w - d_ot
    w_ot = [rest, [0, weekly[x[:week]] + rest - 2400].max].min
    weekly[x[:week]] += rest
    ot += d_ot + w_ot
    reg += rest - w_ot
  end
  num2 = 2 * reg * e[:rate] + 3 * ot * e[:rate]
  pay = (num2 * 2 + 120) / 240
  rows << [id, e[:name], reg, ot, pay]
end

fmt = "%-4s %-10s %8s %8s %10s"
out << format(fmt, "id", "name", "regular", "overtime", "pay")
rows.each { |id, nm, r, o, p| out << format(fmt, id, nm, hm(r), hm(o), money(p)) }
out << format(fmt, "", "total", hm(rows.sum { _1[2] }), hm(rows.sum { _1[3] }), money(rows.sum { _1[4] }))
puts out
