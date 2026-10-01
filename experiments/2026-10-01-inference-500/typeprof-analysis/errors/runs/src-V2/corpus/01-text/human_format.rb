def delimit(n, sep)
  s = n.abs.to_s
  groups = []
  while s.size > 3
    groups.unshift(s[-3..])
    s = s[0...-3]
  end
  groups.unshift(s)
  (n < 0 ? "-" : "") + groups.join(sep)
end

def currency(amount, symbol)
  cents = (amount.abs * 100).round
  whole, frac = cents.divmod(100)
  body = "#{symbol}#{delimit(whole, ",")}.#{frac.to_s.rjust(2, "0")}"
  amount < 0 ? "(#{body})" : body
end

def percent(part, total)
  return "n/a" if total == 0
  pct = part * 100.0 / total
  pct < 1 && pct > 0 ? "<1%" : "#{pct.round(1)}%"
end

def bytes(n, binary)
  base = binary ? 1024 : 1000
  units = binary ? ["B", "KiB", "MiB", "GiB", "TiB"] : ["B", "kB", "MB", "GB", "TB"]
  return "#{n} B" if n < base
  value = n.to_f
  i = 0
  while value >= base && i < units.size - 1
    value /= base
    i += 1
  end
  digits = value >= 100 ? 0 : (value >= 10 ? 1 : 2)
  format("%.#{digits}f %s", value, units[i])
end

def duration(seconds)
  return "0s" if seconds == 0
  parts = []
  rest = seconds
  [[86_400, "d"], [3600, "h"], [60, "m"], [1, "s"]].each do |size, label|
    q, rest = rest.divmod(size)
    next unless q > 0 || !parts.empty?
    parts << (parts.empty? ? "#{q}#{label}" : "#{q.to_s.rjust(2, "0")}#{label}")
  end
  parts.take(2).join(" ")
end

def relative(delta)
  future = delta < 0
  secs = delta.abs
  text =
    if secs < 45 then "a few seconds"
    elsif secs < 90 then "a minute"
    elsif secs < 45 * 60 then "#{(secs / 60.0).round} minutes"
    elsif secs < 90 * 60 then "an hour"
    elsif secs < 22 * 3600 then "#{(secs / 3600.0).round} hours"
    elsif secs < 36 * 3600 then "a day"
    elsif secs < 26 * 86_400 then "#{(secs / 86_400.0).round} days"
    else "#{(secs / (30 * 86_400.0)).round} months"
    end
  future ? "in #{text}" : "#{text} ago"
end

def sig_figs(x, n)
  return "0" if x == 0
  mag = Math.log10(x.abs).floor
  decimals = n - 1 - mag
  if decimals > 0
    format("%.#{decimals}f", x)
  else
    factor = 10**-decimals
    delimit((x / factor).round * factor, ",")
  end
end

puts "== delimit"
[0, 999, 1000, 1_234_567, -9_876_543_210].each { |n| puts "  #{n.to_s.rjust(12)} -> #{delimit(n, ",")} | #{delimit(n, " ")}" }
puts "== currency"
[0.0, 5.5, 1234.567, -42.0, 1_000_000.004].each { |a| puts "  #{a.to_s.rjust(12)} -> #{currency(a, "$")}" }
puts "== percent"
[[1, 3], [2, 1000], [0, 7], [7, 7], [5, 0]].each { |p, t| puts "  #{p}/#{t} -> #{percent(p, t)}" }
puts "== bytes"
[512, 1024, 1536, 1_000_000, 123_456_789, 5_000_000_000_000_000].each do |n|
  puts "  #{n.to_s.rjust(16)} -> #{bytes(n, false).ljust(10)} #{bytes(n, true)}"
end
puts "== duration"
[0, 59, 61, 3600, 3725, 86_399, 90_061, 1_000_000].each { |s| puts "  #{s.to_s.rjust(8)}s -> #{duration(s)}" }
puts "== relative"
[10, 75, 600, 4000, 30_000, 100_000, 400_000, 5_000_000, -120, -200_000].each { |d| puts "  #{d.to_s.rjust(8)} -> #{relative(d)}" }
puts "== significant figures"
[3.14159, 0.000123456, 98765.4, 12.0].each { |x| puts "  #{x} -> #{sig_figs(x, 3)}" }
