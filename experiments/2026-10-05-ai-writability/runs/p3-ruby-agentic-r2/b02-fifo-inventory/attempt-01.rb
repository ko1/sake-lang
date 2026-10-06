def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 ? $2.ljust(2, "0").to_i : 0)
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

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(/ +/).reject(&:empty?)
  cmd = f[0]
  unless %w[RECEIVE SHIP REPORT].include?(cmd)
    puts "line #{no}: error: unknown command #{cmd}"
    next
  end
  if f.size != (cmd == "REPORT" ? 1 : 4)
    puts "line #{no}: error: wrong field count"
    next
  end
  if cmd == "REPORT"
    report.call
    next
  end
  sku = f[1]
  err = nil
  err = "bad sku" unless sku =~ /\A[A-Z0-9-]{1,12}\z/
  qty = nil
  unless err
    if f[2] =~ /\A\d+\z/ && (1..1_000_000).cover?(f[2].to_i)
      qty = f[2].to_i
    else
      err = "bad quantity"
    end
  end
  price = nil
  unless err
    price = cents(f[3])
    err = "bad price" unless price
  end
  if !err && cmd == "SHIP"
    if !lots.key?(sku)
      err = "unknown sku #{sku}"
    else
      have = lots[sku].sum { |l| l[0] }
      err = "insufficient stock for #{sku} (have #{have}, need #{qty})" if have < qty
    end
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  if cmd == "RECEIVE"
    (lots[sku] ||= []) << [qty, price]
  else
    need = qty
    cost = 0
    while need > 0
      l = lots[sku][0]
      t = [need, l[0]].min
      cost += t * l[1]
      l[0] -= t
      need -= t
      lots[sku].shift if l[0] == 0
    end
    r = qty * price
    rev += r
    cogs += cost
    puts "line #{no}: shipped #{qty} #{sku}: revenue #{money(r)}, cost #{money(cost)}"
  end
end
puts "== final =="
report.call
puts "revenue: #{money(rev)}"
puts "cost of goods sold: #{money(cogs)}"
puts "gross profit: #{money(rev - cogs)}"
