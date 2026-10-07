#!/usr/bin/env ruby

# Parse money value (digits with optional .1-2 decimals)
def parse_money(str)
  return nil unless str =~ /^\d+(\.\d{1,2})?$/
  str.to_f
end

# Format money with two decimals
def format_money(value)
  format("%.2f", value)
end

# Validate SKU
def valid_sku?(sku)
  sku =~ /^[A-Z0-9\-]{1,12}$/
end

# Validate quantity
def valid_qty?(qty_str)
  qty_str =~ /^\d+$/ && (1..1_000_000).include?(qty_str.to_i)
end

# Store: sku => [[qty, cost], [qty, cost], ...]
lots = {}
ever_received = Set.new

# Totals
total_revenue = 0.0
total_cost = 0.0

ARGF.each_with_index do |line, idx|
  line_no = idx + 1
  line = line.chomp

  # Skip blank lines
  next if line.strip.empty?

  fields = line.split(/\s+/)

  # Check command
  command = fields[0]
  unless %w[RECEIVE SHIP REPORT].include?(command)
    puts "line #{line_no}: error: unknown command #{command}"
    next
  end

  if command == "REPORT"
    if fields.length != 1
      puts "line #{line_no}: error: wrong field count"
      next
    end

    # Print report
    skus = ever_received.sort
    puts format("%-12s %5s %10s", "SKU", "QTY", "VALUE")
    total_qty = 0
    total_value = 0.0

    skus.each do |sku|
      qty = 0
      value = 0.0
      if lots[sku]
        qty = lots[sku].sum { |q, _| q }
        value = lots[sku].sum { |q, c| q * c }
      end
      total_qty += qty
      total_value += value
      puts format("%-12s %5d %10s", sku, qty, format_money(value))
    end

    puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))

  elsif command == "RECEIVE"
    if fields.length != 4
      puts "line #{line_no}: error: wrong field count"
      next
    end

    sku = fields[1]
    qty_str = fields[2]
    cost_str = fields[3]

    # Validate
    unless valid_sku?(sku)
      puts "line #{line_no}: error: bad sku"
      next
    end

    unless valid_qty?(qty_str)
      puts "line #{line_no}: error: bad quantity"
      next
    end

    cost = parse_money(cost_str)
    if cost.nil?
      puts "line #{line_no}: error: bad price"
      next
    end

    qty = qty_str.to_i
    lots[sku] ||= []
    lots[sku] << [qty, cost]
    ever_received.add(sku)

  elsif command == "SHIP"
    if fields.length != 4
      puts "line #{line_no}: error: wrong field count"
      next
    end

    sku = fields[1]
    qty_str = fields[2]
    price_str = fields[3]

    # Validate
    unless valid_sku?(sku)
      puts "line #{line_no}: error: bad sku"
      next
    end

    unless valid_qty?(qty_str)
      puts "line #{line_no}: error: bad quantity"
      next
    end

    price = parse_money(price_str)
    if price.nil?
      puts "line #{line_no}: error: bad price"
      next
    end

    # Check if SKU exists
    unless lots[sku]
      puts "line #{line_no}: error: unknown sku #{sku}"
      next
    end

    qty = qty_str.to_i

    # Check sufficient stock
    stock = lots[sku].sum { |q, _| q }
    if qty > stock
      puts "line #{line_no}: error: insufficient stock for #{sku} (have #{stock}, need #{qty})"
      next
    end

    # Ship using FIFO
    shipped_cost = 0.0
    remaining = qty

    while remaining > 0 && lots[sku].length > 0
      q, c = lots[sku][0]
      if q <= remaining
        # Take entire lot
        shipped_cost += q * c
        remaining -= q
        lots[sku].shift
      else
        # Take part of lot
        shipped_cost += remaining * c
        lots[sku][0] = [q - remaining, c]
        remaining = 0
      end
    end

    revenue = qty * price
    puts "line #{line_no}: shipped #{qty} #{sku}: revenue #{format_money(revenue)}, cost #{format_money(shipped_cost)}"

    total_revenue += revenue
    total_cost += shipped_cost
  end
end

puts "== final =="

# Print final report
skus = ever_received.sort
puts format("%-12s %5s %10s", "SKU", "QTY", "VALUE")
total_qty = 0
total_value = 0.0

skus.each do |sku|
  qty = 0
  value = 0.0
  if lots[sku]
    qty = lots[sku].sum { |q, _| q }
    value = lots[sku].sum { |q, c| q * c }
  end
  total_qty += qty
  total_value += value
  puts format("%-12s %5d %10s", sku, qty, format_money(value))
end

puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))

puts "revenue: #{format_money(total_revenue)}"
puts "cost of goods sold: #{format_money(total_cost)}"
puts "gross profit: #{format_money(total_revenue - total_cost)}"
