require 'date'

def money(c)
  format("%d.%02d", c / 100, c % 100)
end

def hm(m)
  format("%d:%02d", m / 60, m % 60)
end

def parse_time(s)
  return nil unless s =~ /\A(\d\d):(\d\d)\z/
  h = $1.to_i
  m = $2.to_i
  return nil if h > 23 || m > 59
  h * 60 + m
end

emps = {}   # id => {name:, rate:, shifts: []}
out = []

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = ->(m) { out << "line #{n}: error: #{m}" }
  case f[0]
  when "EMP"
    if f.size != 4
      err.("wrong field count")
    elsif f[1] !~ /\AE\d{3}\z/
      err.("bad id")
    elsif f[2] !~ /\A[A-Za-z]{1,10}\z/
      err.("bad name")
    elsif f[3] !~ /\A(\d+)\.(\d\d)\z/
      err.("bad rate")
    elsif emps.key?(f[1])
      err.("duplicate employee #{f[1]}")
    else
      f[3] =~ /\A(\d+)\.(\d\d)\z/
      emps[f[1]] = { name: f[2], rate: $1.to_i * 100 + $2.to_i, shifts: [] }
    end
  when "SHIFT"
    if f.size != 5 && f.size != 6
      err.("wrong field count")
      next
    end
    id = f[1]
    if id !~ /\AE\d{3}\z/
      err.("bad id")
      next
    end
    unless emps.key?(id)
      err.("unknown employee #{id}")
      next
    end
    jd = nil
    if f[2] =~ /\A(\d{4})-(\d\d)-(\d\d)\z/
      y, mo, d = $1.to_i, $2.to_i, $3.to_i
      if y >= 1970 && y <= 2099 && Date.valid_date?(y, mo, d)
        jd = Date.new(y, mo, d).jd
      end
    end
    if jd.nil?
      err.("bad date")
      next
    end
    st = parse_time(f[3])
    en = parse_time(f[4])
    if st.nil? || en.nil?
      err.("bad time")
      next
    end
    len = en > st ? en - st : en - st + 1440
    brk = 0
    if f.size == 6
      if f[5] !~ /\A\d+\z/ || f[5].to_i >= len
        err.("bad break")
        next
      end
      brk = f[5].to_i
    end
    s0 = jd * 1440 + st
    s1 = s0 + len
    if emps[id][:shifts].any? { |sh| s0 < sh[:e] && sh[:s] < s1 }
      err.("overlapping shift")
      next
    end
    eff = len > 360 ? [brk, 30].max : brk
    emps[id][:shifts] << { s: s0, e: s1, jd: jd, worked: len - eff }
  else
    err.("unknown command")
  end
end

rows = []
emps.keys.sort.each do |id|
  e = emps[id]
  daily = Hash.new(0)
  weekly = Hash.new(0)
  reg = 0
  ot = 0
  e[:shifts].sort_by { |s| s[:s] }.each do |s|
    w = s[:worked]
    od = [[daily[s[:jd]] + w - 480, 0].max, w].min
    daily[s[:jd]] += w
    rest = w - od
    wk = s[:jd] - (s[:jd] % 7)
    ow = [[weekly[wk] + rest - 2400, 0].max, rest].min
    weekly[wk] += rest - ow
    reg += rest - ow
    ot += od + ow
  end
  r = e[:rate]
  num = 2 * reg * r + 3 * ot * r
  pay = (num + 60) / 120
  rows << [id, e[:name], reg, ot, pay]
end

fmt = "%-4s %-10s %8s %8s %10s"
out << format(fmt, "id", "name", "regular", "overtime", "pay")
rows.each { |id, nm, rg, o, p| out << format(fmt, id, nm, hm(rg), hm(o), money(p)) }
out << format(fmt, "", "total", hm(rows.sum { |r| r[2] }), hm(rows.sum { |r| r[3] }), money(rows.sum { |r| r[4] }))
puts out
