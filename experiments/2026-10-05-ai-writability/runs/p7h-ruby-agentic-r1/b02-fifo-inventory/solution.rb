def parse_money(str)
  # Parse money format: digits optionally followed by . and 1-2 digits
  if str.match?(/^\d+(\.\d{1,2})?$/)
    str.to_f
  else
    nil
  end
end

def format_money(value)
  format("%.2f", value)
end

def validate_sku(sku)
  sku.match?(/^[A-Z0-9\-]{1,12}$/)
end

def validate_qty(qty_str)
  if qty_str.match?(/^\d+$/)
    qty = qty_str.to_i
    qty >= 1 && qty <= 1_000_000 ? qty : nil
  else
    nil
  end
end

lines = STDIN.readlines
inventory = {}  # SKU -> [lots] where each lot is {cost, qty}
revenue_total = 0.0
cogs_total = 0.0

lines.each_with_index do |line, idx|
  line_num = idx + 1

  # Skip blank lines
  next if line.strip.empty?

  fields = line.split

  # Check for command
  if fields.empty?
    next
  end

  cmd = fields[0]

  # Check if valid command
  unless %w[RECEIVE SHIP REPORT].include?(cmd)
    puts "line #{line_num}: error: unknown command #{cmd}"
    next
  end

  # Check field count
  if cmd == "REPORT"
    if fields.length != 1
      puts "line #{line_num}: error: wrong field count"
      next
    end

    # Print current inventory report
    skus = inventory.keys.sort
    puts "SKU            QTY      VALUE"
    total_qty = 0
    total_value = 0.0

    skus.each do |sku|
      qty = inventory[sku].sum { |lot| lot[:qty] }
      value = inventory[sku].sum { |lot| lot[:qty] * lot[:cost] }
      puts format("%-12s %5d %10s", sku, qty, format_money(value))
      total_qty += qty
      total_value += value
    end

    puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))

  elsif cmd == "RECEIVE"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    sku, qty_str, cost_str = fields[1], fields[2], fields[3]

    # Validate SKU
    unless validate_sku(sku)
      puts "line #{line_num}: error: bad sku"
      next
    end

    # Validate QTY
    qty = validate_qty(qty_str)
    if qty.nil?
      puts "line #{line_num}: error: bad quantity"
      next
    end

    # Validate COST
    cost = parse_money(cost_str)
    if cost.nil? || cost < 0
      puts "line #{line_num}: error: bad price"
      next
    end

    # Add lot
    inventory[sku] ||= []
    inventory[sku] << {cost: cost, qty: qty}

  elsif cmd == "SHIP"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    sku, qty_str, price_str = fields[1], fields[2], fields[3]

    # Validate SKU
    unless validate_sku(sku)
      puts "line #{line_num}: error: bad sku"
      next
    end

    # Validate QTY
    qty = validate_qty(qty_str)
    if qty.nil?
      puts "line #{line_num}: error: bad quantity"
      next
    end

    # Validate PRICE
    price = parse_money(price_str)
    if price.nil? || price < 0
      puts "line #{line_num}: error: bad price"
      next
    end

    # Check if SKU exists
    unless inventory[sku]
      puts "line #{line_num}: error: unknown sku #{sku}"
      next
    end

    # Check if enough stock
    total_stock = inventory[sku].sum { |lot| lot[:qty] }
    if total_stock < qty
      puts "line #{line_num}: error: insufficient stock for #{sku} (have #{total_stock}, need #{qty})"
      next
    end

    # Ship (FIFO)
    remaining = qty
    cost_shipped = 0.0

    while remaining > 0 && inventory[sku].length > 0
      lot = inventory[sku][0]
      take = [lot[:qty], remaining].min
      cost_shipped += take * lot[:cost]
      lot[:qty] -= take
      remaining -= take

      if lot[:qty] == 0
        inventory[sku].shift
      end
    end

    revenue = qty * price
    puts "line #{line_num}: shipped #{qty} #{sku}: revenue #{format_money(revenue)}, cost #{format_money(cost_shipped)}"

    revenue_total += revenue
    cogs_total += cost_shipped
  end
end

# Final report
puts "== final =="
skus = inventory.keys.sort
puts "SKU            QTY      VALUE"
total_qty = 0
total_value = 0.0

skus.each do |sku|
  qty = inventory[sku].sum { |lot| lot[:qty] }
  value = inventory[sku].sum { |lot| lot[:qty] * lot[:cost] }
  puts format("%-12s %5d %10s", sku, qty, format_money(value))
  total_qty += qty
  total_value += value
end

puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))
puts "revenue: #{format_money(revenue_total)}"
puts "cost of goods sold: #{format_money(cogs_total)}"
puts "gross profit: #{format_money(revenue_total - cogs_total)}"
