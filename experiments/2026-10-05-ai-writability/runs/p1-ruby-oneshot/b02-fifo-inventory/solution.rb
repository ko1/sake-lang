def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(str)
  return nil unless str.match?(/\A\d+(\.\d{1,2})?\z/)
  i, fr = str.split(".", 2)
  i.to_i * 100 + (fr || "").ljust(2, "0").to_i
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

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.match?(/\A *\z/)
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
  err =
    if !sku.match?(/\A[A-Z0-9-]{1,12}\z/) then "bad sku"
    elsif !f[2].match?(/\A\d+\z/) || !(1..1_000_000).cover?(f[2].to_i) then "bad quantity"
    elsif cents(f[3]).nil? then "bad price"
    end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  qty = f[2].to_i
  price = cents(f[3])
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
      take = [need, l[0]].min
      cost += take * l[1]
      l[0] -= take
      need -= take
      lots[sku].shift if l[0] == 0
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
