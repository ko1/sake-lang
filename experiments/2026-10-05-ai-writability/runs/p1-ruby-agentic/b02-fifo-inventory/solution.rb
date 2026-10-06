def cents(s)
  i, f = s.split(".")
  i.to_i * 100 + (f || "").ljust(2, "0").to_i
end

def money(c)
  (c < 0 ? "-" : "") + format("%d.%02d", c.abs / 100, c.abs % 100)
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
  f = raw.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  err = lambda { |m| puts "line #{no}: error: #{m}" }
  cmd = f[0]
  unless %w[RECEIVE SHIP REPORT].include?(cmd)
    err.("unknown command #{cmd}")
    next
  end
  if f.size != (cmd == "REPORT" ? 1 : 4)
    err.("wrong field count")
    next
  end
  if cmd == "REPORT"
    report.()
    next
  end
  sku, qs, ps = f[1], f[2], f[3]
  if sku !~ /\A[A-Z0-9-]{1,12}\z/
    err.("bad sku")
  elsif qs !~ /\A\d+\z/ || !(1..1_000_000).cover?(qs.to_i)
    err.("bad quantity")
  elsif ps !~ /\A\d+(\.\d{1,2})?\z/
    err.("bad price")
  elsif cmd == "RECEIVE"
    (lots[sku] ||= []) << [qs.to_i, cents(ps)]
  elsif !lots.key?(sku)
    err.("unknown sku #{sku}")
  else
    q = qs.to_i
    have = lots[sku].sum { |l| l[0] }
    if q > have
      err.("insufficient stock for #{sku} (have #{have}, need #{q})")
    else
      need = q
      cost = 0
      while need > 0
        l = lots[sku][0]
        t = [need, l[0]].min
        cost += t * l[1]
        l[0] -= t
        need -= t
        lots[sku].shift if l[0] == 0
      end
      rev = q * cents(ps)
      revenue += rev
      cogs += cost
      puts "line #{no}: shipped #{q} #{sku}: revenue #{money(rev)}, cost #{money(cost)}"
    end
  end
end
puts "== final =="
report.()
puts "revenue: #{money(revenue)}"
puts "cost of goods sold: #{money(cogs)}"
puts "gross profit: #{money(revenue - cogs)}"
