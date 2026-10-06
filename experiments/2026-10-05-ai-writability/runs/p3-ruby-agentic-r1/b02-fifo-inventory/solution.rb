def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(s)
  i, f = s.split(".")
  i.to_i * 100 + (f ? (f + "0")[0, 2].to_i : 0)
end

lots = {}
rev = 0
cogs = 0

report = lambda do
  puts format("%-12s %5s %10s", "SKU", "QTY", "VALUE")
  tq = 0
  tv = 0
  lots.keys.sort_by(&:b).each do |k|
    q = lots[k].sum { |l| l[0] }
    v = lots[k].sum { |l| l[0] * l[1] }
    tq += q
    tv += v
    puts format("%-12s %5d %10s", k, q, money(v))
  end
  puts format("%-12s %5d %10s", "TOTAL", tq, money(tv))
end

$stdin.each_line.with_index(1) do |line, n|
  f = line.chomp.split(" ")
  next if f.empty?
  cmd = f[0]
  unless %w[RECEIVE SHIP REPORT].include?(cmd)
    puts "line #{n}: error: unknown command #{cmd}"; next
  end
  if f.size != (cmd == "REPORT" ? 1 : 4)
    puts "line #{n}: error: wrong field count"; next
  end
  if cmd == "REPORT"
    report.call; next
  end
  _, sku, qty, amt = f
  unless sku =~ /\A[A-Z0-9-]{1,12}\z/
    puts "line #{n}: error: bad sku"; next
  end
  unless qty =~ /\A\d+\z/ && (1..1_000_000).cover?(qty.to_i)
    puts "line #{n}: error: bad quantity"; next
  end
  unless amt =~ /\A\d+(\.\d{1,2})?\z/
    puts "line #{n}: error: bad price"; next
  end
  q = qty.to_i
  c = cents(amt)
  if cmd == "RECEIVE"
    (lots[sku] ||= []) << [q, c]
  else
    unless lots.key?(sku)
      puts "line #{n}: error: unknown sku #{sku}"; next
    end
    have = lots[sku].sum { |l| l[0] }
    if q > have
      puts "line #{n}: error: insufficient stock for #{sku} (have #{have}, need #{q})"; next
    end
    need = q
    cost = 0
    while need > 0
      l = lots[sku][0]
      t = [l[0], need].min
      cost += t * l[1]
      l[0] -= t
      need -= t
      lots[sku].shift if l[0] == 0
    end
    r = q * c
    rev += r
    cogs += cost
    puts "line #{n}: shipped #{q} #{sku}: revenue #{money(r)}, cost #{money(cost)}"
  end
end
puts "== final =="
report.call
puts "revenue: #{money(rev)}"
puts "cost of goods sold: #{money(cogs)}"
puts "gross profit: #{money(rev - cogs)}"
