require "date"

def money(c) = format("%d.%02d", c / 100, c % 100)
def hm(m) = format("%d:%02d", m / 60, m % 60)

emps = {}   # id => {name:, rate:, shifts: []}
TIME_RE = /\A([01]\d|2[0-3]):([0-5]\d)\z/

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = nil
  case f[0]
  when "EMP"
    if f.size != 4
      err = "wrong field count"
    elsif !f[1].match?(/\AE\d{3}\z/)
      err = "bad id"
    elsif !f[2].match?(/\A[A-Za-z]{1,10}\z/)
      err = "bad name"
    elsif !f[3].match?(/\A\d+\.\d\d\z/)
      err = "bad rate"
    elsif emps.key?(f[1])
      err = "duplicate employee #{f[1]}"
    else
      emps[f[1]] = { name: f[2], rate: f[3].delete(".").to_i, shifts: [] }
    end
  when "SHIFT"
    if f.size != 5 && f.size != 6
      err = "wrong field count"
    elsif !f[1].match?(/\AE\d{3}\z/)
      err = "bad id"
    elsif !emps.key?(f[1])
      err = "unknown employee #{f[1]}"
    else
      date = nil
      if (md = f[2].match(/\A(\d{4})-(\d\d)-(\d\d)\z/))
        y, mo, d = md[1].to_i, md[2].to_i, md[3].to_i
        date = Date.new(y, mo, d).jd if y.between?(1970, 2099) && Date.valid_date?(y, mo, d)
      end
      st = f[3].match(TIME_RE)
      en = f[4].match(TIME_RE)
      brk = f[5] || "0"
      if date.nil?
        err = "bad date"
      elsif st.nil? || en.nil?
        err = "bad time"
      elsif !brk.match?(/\A\d+\z/)
        err = "bad break"
      else
        s = st[1].to_i * 60 + st[2].to_i
        e = en[1].to_i * 60 + en[2].to_i
        e += 1440 if e <= s
        len = e - s
        brk = brk.to_i
        if brk >= len
          err = "bad break"
        else
          as = date * 1440 + s
          ae = as + len
          if emps[f[1]][:shifts].any? { |sh| as < sh[:end] && sh[:start] < ae }
            err = "overlapping shift"
          else
            eff = len > 360 ? [brk, 30].max : brk
            emps[f[1]][:shifts] << { start: as, end: ae, date: date, worked: len - eff }
          end
        end
      end
    end
  else
    err = "unknown command"
  end
  puts "line #{n}: error: #{err}" if err
end

puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
tr = to = tp = 0
emps.keys.sort.each do |id|
  e = emps[id]
  daily = Hash.new(0)
  week = Hash.new(0)
  reg = ot = 0
  e[:shifts].sort_by { |s| s[:start] }.each do |s|
    w = s[:worked]
    before = daily[s[:date]]
    od = [w, [0, before + w - 480].max].min
    rest = w - od
    wk = s[:date] / 7
    ow = [rest, [0, week[wk] + rest - 2400].max].min
    r = rest - ow
    week[wk] += r
    daily[s[:date]] += w
    reg += r
    ot += od + ow
  end
  x = Rational(reg * e[:rate] * 2 + ot * e[:rate] * 3, 120)
  pay = (x + Rational(1, 2)).floor
  tr += reg; to += ot; tp += pay
  puts format("%-4s %-10s %8s %8s %10s", id, e[:name], hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(tr), hm(to), money(tp))
