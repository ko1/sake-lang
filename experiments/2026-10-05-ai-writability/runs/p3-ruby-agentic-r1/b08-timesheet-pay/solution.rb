require "date"

def hm(m) = format("%d:%02d", m / 60, m % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)

emps = {}   # id => {name, rate, shifts: [[s, e, worked, date]]}
out = []

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.strip.split(" ")
  next if f.empty?
  err = ->(m) { out << "line #{n}: error: #{m}" }
  case f[0]
  when "EMP"
    (err.("wrong field count"); next) unless f.size == 4
    (err.("bad id"); next) unless f[1] =~ /\AE\d{3}\z/
    (err.("bad name"); next) unless f[2] =~ /\A[A-Za-z]{1,10}\z/
    (err.("bad rate"); next) unless f[3] =~ /\A(\d+)\.(\d\d)\z/
    rate = $1.to_i * 100 + $2.to_i
    (err.("duplicate employee #{f[1]}"); next) if emps[f[1]]
    emps[f[1]] = { name: f[2], rate: rate, shifts: [] }
  when "SHIFT"
    (err.("wrong field count"); next) unless f.size == 5 || f.size == 6
    (err.("bad id"); next) unless f[1] =~ /\AE\d{3}\z/
    e = emps[f[1]]
    (err.("unknown employee #{f[1]}"); next) unless e
    unless f[2] =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && $1.to_i.between?(1970, 2099) &&
           Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
      err.("bad date"); next
    end
    date = Date.new($1.to_i, $2.to_i, $3.to_i)
    tm = /\A([01]\d|2[0-3]):([0-5]\d)\z/
    (err.("bad time"); next) unless f[3] =~ tm
    st = $1.to_i * 60 + $2.to_i
    (err.("bad time"); next) unless f[4] =~ tm
    en = $1.to_i * 60 + $2.to_i
    en += 1440 if en <= st
    len = en - st
    brk = 0
    if f[5]
      (err.("bad break"); next) unless f[5] =~ /\A\d+\z/
      brk = f[5].to_i
    end
    (err.("bad break"); next) unless brk < len
    a = date.jd * 1440 + st
    b = a + len
    (err.("overlapping shift"); next) if e[:shifts].any? { |s| a < s[1] && s[0] < b }
    brk = 30 if len > 360 && brk < 30
    e[:shifts] << [a, b, len - brk, date]
  else
    err.("unknown command")
  end
end

rows = []
emps.keys.sort.each do |id|
  e = emps[id]
  daily = Hash.new(0)
  weekreg = Hash.new(0)
  reg = ot = 0
  e[:shifts].sort_by { |s| s[0] }.each do |_, _, w, date|
    dp = daily[date]
    dn = dp + w
    otd = [dn - 480, 0].max - [dp - 480, 0].max
    daily[date] = dn
    rest = w - otd
    wk = date.jd - date.cwday + 1
    wp = weekreg[wk]
    otw = [wp + rest - 2400, 0].max - [wp - 2400, 0].max
    r = rest - otw
    weekreg[wk] += r
    reg += r
    ot += otd + otw
  end
  pay = (reg * e[:rate] * 2 + ot * e[:rate] * 3 + 60) / 120
  rows << [id, e[:name], reg, ot, pay]
end

fmt = "%-4s %-10s %8s %8s %10s"
out << format(fmt, "id", "name", "regular", "overtime", "pay")
rows.each { |id, nm, r, o, p| out << format(fmt, id, nm, hm(r), hm(o), money(p)) }
out << format(fmt, "", "total", hm(rows.sum { _1[2] }), hm(rows.sum { _1[3] }), money(rows.sum { _1[4] }))
puts out
