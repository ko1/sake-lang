require "date"

def hm(m) = format("%d:%02d", m / 60, m % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)
def tmin(s) = s =~ /\A([01]\d|2[0-3]):([0-5]\d)\z/ ? $1.to_i * 60 + $2.to_i : nil

emps = {}
n = 0
$stdin.each_line do |raw|
  n += 1
  line = raw.strip
  next if line.empty?
  f = line.split(/ +/)
  err = ->(m) { puts "line #{n}: error: #{m}" }
  case f[0]
  when "EMP"
    if f.size != 4 then err.("wrong field count")
    elsif f[1] !~ /\AE\d{3}\z/ then err.("bad id")
    elsif f[2] !~ /\A[A-Za-z]{1,10}\z/ then err.("bad name")
    elsif f[3] !~ /\A(\d+)\.(\d\d)\z/ then err.("bad rate")
    elsif emps[f[1]] then err.("duplicate employee #{f[1]}")
    else
      f[3] =~ /\A(\d+)\.(\d\d)\z/
      emps[f[1]] = { name: f[2], rate: $1.to_i * 100 + $2.to_i, shifts: [] }
    end
  when "SHIFT"
    if f.size != 5 && f.size != 6
      err.("wrong field count")
      next
    end
    id, date, st, en, br = f[1], f[2], f[3], f[4], f[5]
    if id !~ /\AE\d{3}\z/
      err.("bad id")
      next
    end
    e = emps[id]
    if e.nil?
      err.("unknown employee #{id}")
      next
    end
    jd = nil
    if date =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && $1.to_i.between?(1970, 2099) && Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
      jd = Date.new($1.to_i, $2.to_i, $3.to_i).jd
    end
    if jd.nil?
      err.("bad date")
      next
    end
    s = tmin(st)
    en_m = tmin(en)
    if s.nil? || en_m.nil?
      err.("bad time")
      next
    end
    len = en_m > s ? en_m - s : en_m - s + 1440
    b = 0
    if br
      if br !~ /\A\d+\z/ || br.to_i >= len
        err.("bad break")
        next
      end
      b = br.to_i
    end
    a0 = jd * 1440 + s
    a1 = a0 + len
    if e[:shifts].any? { |x| a0 < x[:b] && x[:a] < a1 }
      err.("overlapping shift")
      next
    end
    b = 30 if len > 360 && b < 30
    e[:shifts] << { a: a0, b: a1, jd: jd, w: len - b }
  else
    err.("unknown command")
  end
end

puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
tr = to = tp = 0
emps.keys.sort.each do |id|
  e = emps[id]
  daily = Hash.new(0)
  weekly = Hash.new(0)
  reg = ot = 0
  e[:shifts].sort_by { |x| x[:a] }.each do |x|
    w = x[:w]
    od = [w, [daily[x[:jd]] + w - 480, 0].max].min
    rest = w - od
    wk = x[:jd] / 7
    ow = [rest, [weekly[wk] + rest - 2400, 0].max].min
    r = rest - ow
    daily[x[:jd]] += w
    weekly[wk] += r
    reg += r
    ot += od + ow
  end
  pay = (2 * reg * e[:rate] + 3 * ot * e[:rate] + 60) / 120
  tr += reg; to += ot; tp += pay
  puts format("%-4s %-10s %8s %8s %10s", id, e[:name], hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(tr), hm(to), money(tp))
