def format_money(val)
  format("%.2f", val)
end

skus = {}
all_skus_received = Set.new
revenue = 0.0
cogs = 0.0

$stdin.each_line.with_index(1) do |line, line_num|
  line = line.chomp
  next if line.strip.empty?

  fields = line.split(/\s+/)
  next if fields.empty?

  command = fields[0]

  unless ['RECEIVE', 'SHIP', 'REPORT'].include?(command)
    puts "line #{line_num}: error: unknown command #{command}"
    next
  end

  if (command == 'REPORT' && fields.length != 1) || (command != 'REPORT' && fields.length != 4)
    puts "line #{line_num}: error: wrong field count"
    next
  end

  if command == 'RECEIVE'
    sku, qty, cost = fields[1], fields[2], fields[3]

    unless sku =~ /^[A-Z0-9-]{1,12}$/
      puts "line #{line_num}: error: bad sku"
      next
    end

    unless qty =~ /^\d+$/ && qty.to_i.between?(1, 1000000)
      puts "line #{line_num}: error: bad quantity"
      next
    end

    unless cost =~ /^\d+(\.\d{1,2})?$/
      puts "line #{line_num}: error: bad price"
      next
    end

    qty_int = qty.to_i
    cost_float = cost.to_f

    skus[sku] ||= {lots: [], qty_total: 0}
    skus[sku][:lots] << [qty_int, cost_float]
    skus[sku][:qty_total] += qty_int
    all_skus_received.add(sku)

  elsif command == 'SHIP'
    sku, qty, price = fields[1], fields[2], fields[3]

    unless sku =~ /^[A-Z0-9-]{1,12}$/
      puts "line #{line_num}: error: bad sku"
      next
    end

    unless qty =~ /^\d+$/ && qty.to_i.between?(1, 1000000)
      puts "line #{line_num}: error: bad quantity"
      next
    end

    unless price =~ /^\d+(\.\d{1,2})?$/
      puts "line #{line_num}: error: bad price"
      next
    end

    qty_int = qty.to_i
    price_float = price.to_f

    unless all_skus_received.include?(sku)
      puts "line #{line_num}: error: unknown sku #{sku}"
      next
    end

    have = skus[sku] ? skus[sku][:qty_total] : 0
    if qty_int > have
      puts "line #{line_num}: error: insufficient stock for #{sku} (have #{have}, need #{qty_int})"
      next
    end

    ship_cost = 0.0
    remaining = qty_int

    while remaining > 0 && skus[sku][:lots].length > 0
      lot_qty, lot_cost = skus[sku][:lots][0]
      take = [remaining, lot_qty].min
      ship_cost += take * lot_cost
      remaining -= take
      skus[sku][:qty_total] -= take

      if take == lot_qty
        skus[sku][:lots].shift
      else
        skus[sku][:lots][0] = [lot_qty - take, lot_cost]
      end
    end

    ship_revenue = qty_int * price_float
    revenue += ship_revenue
    cogs += ship_cost

    puts "line #{line_num}: shipped #{qty_int} #{sku}: revenue #{format_money(ship_revenue)}, cost #{format_money(ship_cost)}"

  elsif command == 'REPORT'
    puts "SKU            QTY      VALUE"
    total_qty = 0
    total_value = 0.0

    all_skus_received.sort.each do |sku|
      qty = skus[sku] ? skus[sku][:qty_total] : 0
      value = 0.0

      if skus[sku]
        skus[sku][:lots].each do |lot_qty, lot_cost|
          value += lot_qty * lot_cost
        end
      end

      total_qty += qty
      total_value += value

      puts format("%-12s %5d %10s", sku, qty, format_money(value))
    end

    puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))
  end
end

puts "== final =="
puts "SKU            QTY      VALUE"
total_qty = 0
total_value = 0.0

all_skus_received.sort.each do |sku|
  qty = skus[sku] ? skus[sku][:qty_total] : 0
  value = 0.0

  if skus[sku]
    skus[sku][:lots].each do |lot_qty, lot_cost|
      value += lot_qty * lot_cost
    end
  end

  total_qty += qty
  total_value += value

  puts format("%-12s %5d %10s", sku, qty, format_money(value))
end

puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))
puts "revenue: #{format_money(revenue)}"
puts "cost of goods sold: #{format_money(cogs)}"
puts "gross profit: #{format_money(revenue - cogs)}"
