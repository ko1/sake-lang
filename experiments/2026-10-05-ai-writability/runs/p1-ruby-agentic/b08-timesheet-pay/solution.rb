require "date"

def hm(m) = format("%d:%02d", m / 60, m % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)

emps = {}   # id => {name, rate, shifts: [[start, end, break, date_jd]]}

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = nil
  case f[0]
  when "EMP"
    if f.size != 4
      err = "wrong field count"
    elsif f[1] !~ /\AE\d{3}\z/
      err = "bad id"
    elsif f[2] !~ /\A[A-Za-z]{1,10}\z/
      err = "bad name"
    elsif f[3] !~ /\A(\d+)\.(\d\d)\z/
      err = "bad rate"
    elsif emps[f[1]]
      err = "duplicate employee #{f[1]}"
    else
      emps[f[1]] = { name: f[2], rate: $1.to_i * 100 + $2.to_i, shifts: [] }
    end
  when "SHIFT"
    if f.size != 5 && f.size != 6
      err = "wrong field count"
    elsif f[1] !~ /\AE\d{3}\z/
      err = "bad id"
    elsif !emps[f[1]]
      err = "unknown employee #{f[1]}"
    else
      jd = nil
      if f[2] =~ /\A(\d{4})-(\d\d)-(\d\d)\z/ && (1970..2099).cover?($1.to_i) &&
         Date.valid_date?($1.to_i, $2.to_i, $3.to_i)
        jd = Date.new($1.to_i, $2.to_i, $3.to_i).jd
      end
      tm = ->(s) { s =~ /\A([01]\d|2[0-3]):([0-5]\d)\z/ ? $1.to_i * 60 + $2.to_i : nil }
      if !jd
        err = "bad date"
      elsif !(st = tm[f[3]]) || !(en = tm[f[4]])
        err = "bad time"
      else
        en += 1440 if en <= st
        len = en - st
        brk = f[5] || "0"
        if brk !~ /\A\d+\z/ || brk.to_i >= len
          err = "bad break"
        else
          s = jd * 1440 + st
          e = s + len
          if emps[f[1]][:shifts].any? { |a, b, *| s < b && a < e }
            err = "overlapping shift"
          else
            emps[f[1]][:shifts] << [s, e, brk.to_i, jd, len]
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
  em = emps[id]
  reg = ot = 0
  daily = Hash.new(0)
  weekly = Hash.new(0)
  em[:shifts].sort_by(&:first).each do |_s, _e, brk, jd, len|
    brk = 30 if len > 360 && brk < 30
    w = len - brk
    d_ot = (daily[jd] + w - 480).clamp(0, w)
    daily[jd] += w
    rest = w - d_ot
    wk = jd / 7
    w_ot = (weekly[wk] + rest - 2400).clamp(0, rest)
    r = rest - w_ot
    weekly[wk] += r
    reg += r
    ot += d_ot + w_ot
  end
  num = em[:rate] * (2 * reg + 3 * ot)
  pay = (2 * num + 120) / 240
  tr += reg; to += ot; tp += pay
  puts format("%-4s %-10s %8s %8s %10s", id, em[:name], hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(tr), hm(to), money(tp))
