def money(c)
  s = format("%d.%02d", c.abs / 100, c.abs % 100)
  c < 0 ? "-" + s : s
end

def cents(s)
  a, b = s.split(".")
  a.to_i * 100 + (b ? (b.size == 1 ? b.to_i * 10 : b.to_i) : 0)
end

lots = {}
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
  if f.size != (cmd == "REPORT" ? 1 : 4)
    puts "line #{no}: error: wrong field count"
    next
  end
  if cmd == "REPORT"
    report.call
    next
  end
  sku, qty, price = f[1], f[2], f[3]
  err =
    if sku !~ /\A[A-Z0-9-]{1,12}\z/ then "bad sku"
    elsif qty !~ /\A\d+\z/ || !(1..1_000_000).cover?(qty.to_i) then "bad quantity"
    elsif price !~ /\A\d+(\.\d{1,2})?\z/ then "bad price"
    end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  q = qty.to_i
  p = cents(price)
  if cmd == "RECEIVE"
    (lots[sku] ||= []) << [q, p]
    next
  end
  unless lots.key?(sku)
    puts "line #{no}: error: unknown sku #{sku}"
    next
  end
  have = lots[sku].sum { |l| l[0] }
  if q > have
    puts "line #{no}: error: insufficient stock for #{sku} (have #{have}, need #{q})"
    next
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
  r = q * p
  rev += r
  cogs += cost
  puts "line #{no}: shipped #{q} #{sku}: revenue #{money(r)}, cost #{money(cost)}"
end
puts "== final =="
report.call
puts "revenue: #{money(rev)}"
puts "cost of goods sold: #{money(cogs)}"
puts "gross profit: #{money(rev - cogs)}"
