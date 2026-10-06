require "date"

def hm(m) = format("%d:%02d", m / 60, m % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)

emps = {}
shifts = Hash.new { |h, k| h[k] = [] }

$stdin.each_line.with_index(1) do |raw, n|
  next if raw.strip.empty?
  f = raw.strip.split(/ +/)
  err = ->(m) { puts "line #{n}: error: #{m}" }
  case f[0]
  when "EMP"
    if f.size != 4 then err.("wrong field count"); next end
    unless f[1] =~ /\AE\d{3}\z/ then err.("bad id"); next end
    unless f[2] =~ /\A[A-Za-z]{1,10}\z/ then err.("bad name"); next end
    unless f[3] =~ /\A(\d+)\.(\d\d)\z/ then err.("bad rate"); next end
    rate = $1.to_i * 100 + $2.to_i
    if emps.key?(f[1]) then err.("duplicate employee #{f[1]}"); next end
    emps[f[1]] = { name: f[2], rate: rate }
  when "SHIFT"
    unless f.size == 5 || f.size == 6 then err.("wrong field count"); next end
    id = f[1]
    unless id =~ /\AE\d{3}\z/ then err.("bad id"); next end
    unless emps.key?(id) then err.("unknown employee #{id}"); next end
    unless f[2] =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && (1970..2099).cover?($1.to_i) && Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
      err.("bad date"); next
    end
    date = Date.new($1.to_i, $2.to_i, $3.to_i)
    times = f[3, 2].map do |t|
      t =~ /\A([01]\d|2[0-3]):([0-5]\d)\z/ ? $1.to_i * 60 + $2.to_i : nil
    end
    if times.any?(&:nil?) then err.("bad time"); next end
    s, e = times
    len = e > s ? e - s : e + 1440 - s
    brk = 0
    if f[5]
      unless f[5] =~ /\A\d+\z/ && f[5].to_i < len then err.("bad break"); next end
      brk = f[5].to_i
    end
    abs_s = date.jd * 1440 + s
    abs_e = abs_s + len
    if shifts[id].any? { |x| abs_s < x[:e] && x[:s] < abs_e }
      err.("overlapping shift"); next
    end
    brk = 30 if len > 360 && brk < 30
    shifts[id] << { s: abs_s, e: abs_e, date: date, worked: len - brk }
  else
    err.("unknown command")
  end
end

fmt = "%-4s %-10s %8s %8s %10s"
puts format(fmt, "id", "name", "regular", "overtime", "pay")
tr = to = tp = 0
emps.keys.sort.each do |id|
  r = emps[id][:rate]
  reg = ot = 0
  day = Hash.new(0)
  week = Hash.new(0)
  shifts[id].sort_by { |x| x[:s] }.each do |x|
    w = x[:worked]
    dreg = [w, [480 - day[x[:date]], 0].max].min
    day[x[:date]] += w
    wk = (x[:date] - (x[:date].cwday - 1)).jd
    wreg = [dreg, [2400 - week[wk], 0].max].min
    week[wk] += wreg
    reg += wreg
    ot += w - wreg
  end
  pay = (2 * reg * r + 3 * ot * r + 60) / 120
  tr += reg; to += ot; tp += pay
  puts format(fmt, id, emps[id][:name], hm(reg), hm(ot), money(pay))
end
puts format(fmt, "", "total", hm(tr), hm(to), money(tp))
