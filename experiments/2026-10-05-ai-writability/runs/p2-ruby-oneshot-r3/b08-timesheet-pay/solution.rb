def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def day_index(y, m, d)
  # days since 1970-01-01
  y2 = m <= 2 ? y - 1 : y
  era = y2 / 400
  yoe = y2 - era * 400
  mp = (m + 9) % 12
  doy = (153 * mp + 2) / 5 + d - 1
  doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
end

def parse_date(s)
  return nil unless s =~ /\A(\d{4})-(\d{2})-(\d{2})\z/
  y, m, d = $1.to_i, $2.to_i, $3.to_i
  return nil unless y.between?(1970, 2099) && m.between?(1, 12)
  mdays = [31, leap?(y) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  return nil unless d.between?(1, mdays[m - 1])
  day_index(y, m, d)
end

def parse_time(s)
  return nil unless s =~ /\A(\d{2}):(\d{2})\z/
  h, m = $1.to_i, $2.to_i
  return nil unless h <= 23 && m <= 59
  h * 60 + m
end

def hm(min) = format("%d:%02d", min / 60, min % 60)
def money(c) = format("%d.%02d", c / 100, c % 100)

emps = {}   # id => [name, rate_cents]
shifts = Hash.new { |h, k| h[k] = [] }  # id => [[start, end, date, worked]]
out = []

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty?
  f = line.split
  err = nil
  case f[0]
  when "EMP"
    if f.size != 4
      err = "wrong field count"
    elsif f[1] !~ /\AE\d{3}\z/
      err = "bad id"
    elsif f[2] !~ /\A[A-Za-z]{1,10}\z/
      err = "bad name"
    elsif f[3] !~ /\A\d+\.\d\d\z/
      err = "bad rate"
    elsif emps.key?(f[1])
      err = "duplicate employee #{f[1]}"
    else
      emps[f[1]] = [f[2], f[3].delete(".").to_i]
    end
  when "SHIFT"
    if f.size != 5 && f.size != 6
      err = "wrong field count"
    elsif f[1] !~ /\AE\d{3}\z/
      err = "bad id"
    elsif !emps.key?(f[1])
      err = "unknown employee #{f[1]}"
    else
      date = parse_date(f[2])
      st = parse_time(f[3])
      en = parse_time(f[4])
      if date.nil?
        err = "bad date"
      elsif st.nil? || en.nil?
        err = "bad time"
      else
        len = en > st ? en - st : en + 1440 - st
        brk = 0
        if f.size == 6
          if f[5] =~ /\A\d+\z/ && f[5].to_i < len
            brk = f[5].to_i
          else
            err = "bad break"
          end
        end
        if err.nil?
          s = date * 1440 + st
          e = s + len
          if shifts[f[1]].any? { |(s2, e2, _, _)| s < e2 && s2 < e }
            err = "overlapping shift"
          else
            brk = 30 if len > 360 && brk < 30
            shifts[f[1]] << [s, e, date, len - brk]
          end
        end
      end
    end
  else
    err = "unknown command"
  end
  out << "line #{n}: error: #{err}" if err
end

out << format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
treg = tot = tpay = 0
emps.keys.sort.each do |id|
  name, rate = emps[id]
  daily = Hash.new(0)
  weekly = Hash.new(0)
  reg = ot = 0
  shifts[id].sort_by { |s| s[0] }.each do |(_, _, date, w)|
    prior = daily[date]
    ot_d = [w, [prior + w - 480, 0].max].min
    rest = w - ot_d
    daily[date] += w
    wk = date - (date + 3) % 7
    ot_w = [rest, [weekly[wk] + rest - 2400, 0].max].min
    r = rest - ot_w
    weekly[wk] += r
    reg += r
    ot += ot_d + ot_w
  end
  num = reg * rate * 2 + ot * rate * 3
  pay = (num + 60) / 120
  treg += reg
  tot += ot
  tpay += pay
  out << format("%-4s %-10s %8s %8s %10s", id, name, hm(reg), hm(ot), money(pay))
end
out << format("%-4s %-10s %8s %8s %10s", "", "total", hm(treg), hm(tot), money(tpay))
puts out
