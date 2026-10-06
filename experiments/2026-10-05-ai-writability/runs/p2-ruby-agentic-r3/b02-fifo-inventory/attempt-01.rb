def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i
end

lots = {} # sku => [[qty, cost_cents], ...]
rev = 0
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

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
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
  if qs !~ /\A\d+\z/ || !(1..1_000_000).cover?(qs.to_i)
    puts "line #{no}: error: bad quantity"
    next
  end
  price = cents(ps)
  if price.nil?
    puts "line #{no}: error: bad price"
    next
  end
  qty = qs.to_i
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
      l = lots[sku][0]
      t = [l[0], need].min
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
