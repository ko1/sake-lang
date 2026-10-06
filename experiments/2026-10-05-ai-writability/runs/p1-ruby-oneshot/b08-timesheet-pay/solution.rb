require "date"

def money(c) = format("%d.%02d", c / 100, c % 100)
def hm(m) = format("%d:%02d", m / 60, m % 60)

emps = {}   # id => { name:, rate:, shifts: [] }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = nil
  case f[0]
  when "EMP"
    if f.size != 4 then err = "wrong field count"
    elsif !f[1].match?(/\AE\d{3}\z/) then err = "bad id"
    elsif !f[2].match?(/\A[A-Za-z]{1,10}\z/) then err = "bad name"
    elsif !f[3].match?(/\A\d+\.\d\d\z/) then err = "bad rate"
    elsif emps.key?(f[1]) then err = "duplicate employee #{f[1]}"
    else
      a, b = f[3].split(".")
      emps[f[1]] = { name: f[2], rate: a.to_i * 100 + b.to_i, shifts: [] }
    end
  when "SHIFT"
    if f.size != 5 && f.size != 6 then err = "wrong field count"
    elsif !f[1].match?(/\AE\d{3}\z/) then err = "bad id"
    elsif !emps.key?(f[1]) then err = "unknown employee #{f[1]}"
    else
      date = nil
      if (m = f[2].match(/\A(\d{4})-(\d\d)-(\d\d)\z/)) &&
         (1970..2099).cover?(m[1].to_i) && Date.valid_date?(m[1].to_i, m[2].to_i, m[3].to_i)
        date = Date.new(m[1].to_i, m[2].to_i, m[3].to_i)
      end
      tre = /\A([01]\d|2[0-3]):([0-5]\d)\z/
      if date.nil? then err = "bad date"
      elsif !(ms = f[3].match(tre)) || !(me = f[4].match(tre)) then err = "bad time"
      else
        s = ms[1].to_i * 60 + ms[2].to_i
        e = me[1].to_i * 60 + me[2].to_i
        len = e > s ? e - s : e + 1440 - s
        brk = f[5] || "0"
        if !brk.match?(/\A\d+\z/) || brk.to_i >= len
          err = "bad break"
        else
          days = date.jd - Date.new(1970, 1, 1).jd
          as = days * 1440 + s
          ae = as + len
          if emps[f[1]][:shifts].any? { |x| as < x[:e] && x[:s] < ae }
            err = "overlapping shift"
          else
            emps[f[1]][:shifts] << { s: as, e: ae, days: days, len: len, brk: brk.to_i }
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
treg = tot = tpay = 0
emps.keys.sort.each do |id|
  em = emps[id]
  reg = ot = 0
  daily = Hash.new(0)
  weekly = Hash.new(0)
  em[:shifts].sort_by { |x| x[:s] }.each do |x|
    brk = x[:len] > 360 && x[:brk] < 30 ? 30 : x[:brk]
    w = x[:len] - brk
    before = daily[x[:days]]
    od = [before + w - [480, before].max, 0].max
    rest = w - od
    wk = (x[:days] + 3) / 7
    wb = weekly[wk]
    ow = [wb + rest - [2400, wb].max, 0].max
    r = rest - ow
    daily[x[:days]] += w
    weekly[wk] += r
    reg += r
    ot += od + ow
  end
  pay = ((reg * em[:rate] * 2 + ot * em[:rate] * 3) * 2 + 120) / 240
  treg += reg
  tot += ot
  tpay += pay
  puts format("%-4s %-10s %8s %8s %10s", id, em[:name], hm(reg), hm(ot), money(pay))
end
puts format("%-4s %-10s %8s %8s %10s", "", "total", hm(treg), hm(tot), money(tpay))
