require "date"

def money(c)
  format("%d.%02d", c / 100, c % 100)
end

def hm(m)
  format("%d:%02d", m / 60, m % 60)
end

def parse_time(s)
  return nil unless s =~ /\A([01]\d|2[0-3]):([0-5]\d)\z/
  $1.to_i * 60 + $2.to_i
end

emps = {}
$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  e = lambda { |m| puts "line #{n}: error: #{m}" }
  cmd = f[0]
  unless %w[EMP SHIFT].include?(cmd)
    e.call("unknown command"); next
  end
  if cmd == "EMP" ? f.size != 4 : !(5..6).cover?(f.size)
    e.call("wrong field count"); next
  end
  id = f[1]
  if cmd == "EMP"
    _, _, name, rate = f
    if id !~ /\AE\d{3}\z/ then e.call("bad id"); next end
    if name !~ /\A[A-Za-z]{1,10}\z/ then e.call("bad name"); next end
    if rate !~ /\A\d+\.\d\d\z/ then e.call("bad rate"); next end
    if emps.key?(id) then e.call("duplicate employee #{id}"); next end
    emps[id] = {name: name, rate: rate.delete(".").to_i, shifts: []}
  else
    _, _, date, st, en, brk = f
    if id !~ /\AE\d{3}\z/ then e.call("bad id"); next end
    if !emps.key?(id) then e.call("unknown employee #{id}"); next end
    d = nil
    if date =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && (1970..2099).cover?($1.to_i) && Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
      d = Date.new($1.to_i, $2.to_i, $3.to_i)
    end
    if d.nil? then e.call("bad date"); next end
    s = parse_time(st)
    t = s && parse_time(en)
    if s.nil? || t.nil? then e.call("bad time"); next end
    len = t > s ? t - s : t + 1440 - s
    brk ||= "0"
    if brk !~ /\A\d+\z/ || brk.to_i >= len then e.call("bad break"); next end
    a = d.jd * 1440 + s
    b = a + len
    if emps[id][:shifts].any? { |x| a < x[:b] && x[:a] < b }
      e.call("overlapping shift"); next
    end
    emps[id][:shifts] << {a: a, b: b, date: d, len: len, brk: brk.to_i}
  end
end

puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
tr = to = tp = 0
emps.keys.sort_by(&:b).each do |id|
  em = emps[id]
  reg = ot = 0
  daily = Hash.new(0)
  weekreg = Hash.new(0)
  em[:shifts].sort_by { |x| x[:a] }.each do |x|
    br = x[:brk]
    br = 30 if x[:len] > 360 && br < 30
    w = x[:len] - br
    dk = x[:date]
    prior = daily[dk]
    daily[dk] = prior + w
    od = [w, [prior + w - 480, 0].max].min
    rest = w - od
    wk = dk - (dk.cwday - 1)
    r = [rest, [2400 - weekreg[wk], 0].max].min
    weekreg[wk] += r
    reg += r
    ot += od + (rest - r)
  end
  pay = ((2 * reg + 3 * ot) * em[:rate] + 60) / 120
  tr += reg; to += ot; tp += pay
  puts format("%-4s %-10s %8s %8s %10s", id, em[:name], hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(tr), hm(to), money(tp))
