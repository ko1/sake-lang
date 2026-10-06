def money(c)
  (c < 0 ? "-" : "") + format("%d.%02d", c.abs / 100, c.abs % 100)
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i
end

lots = {}
revenue = 0
cogs = 0

report = lambda do
  puts format("%-12s %5s %10s", "SKU", "QTY", "VALUE")
  tq = 0
  tv = 0
  lots.keys.sort_by(&:b).each do |sku|
    q = lots[sku].sum { |l| l[0] }
    v = lots[sku].sum { |l| l[0] * l[1] }
    tq += q
    tv += v
    puts format("%-12s %5d %10s", sku, q, money(v))
  end
  puts format("%-12s %5d %10s", "TOTAL", tq, money(tv))
end

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  cmd = f[0]
  unless %w[RECEIVE SHIP REPORT].include?(cmd)
    puts "line #{n}: error: unknown command #{cmd}"
    next
  end
  if f.size != (cmd == "REPORT" ? 1 : 4)
    puts "line #{n}: error: wrong field count"
    next
  end
  if cmd == "REPORT"
    report.call
    next
  end
  sku = f[1]
  if sku !~ /\A[A-Z0-9-]{1,12}\z/
    puts "line #{n}: error: bad sku"
    next
  end
  if f[2] !~ /\A\d+\z/ || !f[2].to_i.between?(1, 1_000_000)
    puts "line #{n}: error: bad quantity"
    next
  end
  qty = f[2].to_i
  price = cents(f[3])
  if price.nil?
    puts "line #{n}: error: bad price"
    next
  end
  if cmd == "RECEIVE"
    (lots[sku] ||= []) << [qty, price]
    next
  end
  unless lots.key?(sku)
    puts "line #{n}: error: unknown sku #{sku}"
    next
  end
  have = lots[sku].sum { |l| l[0] }
  if qty > have
    puts "line #{n}: error: insufficient stock for #{sku} (have #{have}, need #{qty})"
    next
  end
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
  rev = qty * price
  revenue += rev
  cogs += cost
  puts "line #{n}: shipped #{qty} #{sku}: revenue #{money(rev)}, cost #{money(cost)}"
end

puts "== final =="
report.call
puts "revenue: #{money(revenue)}"
puts "cost of goods sold: #{money(cogs)}"
puts "gross profit: #{money(revenue - cogs)}"
