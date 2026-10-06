def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i
end

def money(c)
  sign = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", sign, c / 100, c % 100)
end

lots = {}   # sku => [[qty, cost_cents], ...]
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

$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.delete("\r").split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  unless %w[RECEIVE SHIP REPORT].include?(cmd)
    puts "line #{no}: error: unknown command #{cmd}"
    next
  end
  if cmd == "REPORT"
    if f.size != 1
      puts "line #{no}: error: wrong field count"
    else
      report.call
    end
    next
  end
  if f.size != 4
    puts "line #{no}: error: wrong field count"
    next
  end
  _, sku, qs, ps = f
  if sku !~ /\A[A-Z0-9-]{1,12}\z/
    puts "line #{no}: error: bad sku"
    next
  end
  qty = qs =~ /\A\d+\z/ ? qs.to_i : 0
  unless qs =~ /\A\d+\z/ && qty.between?(1, 1_000_000)
    puts "line #{no}: error: bad quantity"
    next
  end
  price = cents(ps)
  if price.nil?
    puts "line #{no}: error: bad price"
    next
  end
  if cmd == "RECEIVE"
    (lots[sku] ||= []) << [qty, price]
  else
    unless lots.key?(sku)
      puts "line #{no}: error: unknown sku #{sku}"
      next
    end
    have = lots[sku].sum { |l| l[0] }
    if qty > have
      puts "line #{no}: error: insufficient stock for #{sku} (have #{have}, need #{qty})"
      next
    end
    need = qty
    cost = 0
    while need > 0
      lot = lots[sku][0]
      take = [need, lot[0]].min
      cost += take * lot[1]
      lot[0] -= take
      need -= take
      lots[sku].shift if lot[0] == 0
    end
    rev = qty * price
    revenue += rev
    cogs += cost
    puts "line #{no}: shipped #{qty} #{sku}: revenue #{money(rev)}, cost #{money(cost)}"
  end
end

puts "== final =="
report.call
puts "revenue: #{money(revenue)}"
puts "cost of goods sold: #{money(cogs)}"
puts "gross profit: #{money(revenue - cogs)}"
