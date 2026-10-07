#!/usr/bin/env ruby

def validate_sku(sku)
  sku =~ /^[A-Z0-9\-]{1,12}$/
end

def validate_qty(qty_str)
  qty_str =~ /^\d+$/ && (1..1_000_000).include?(qty_str.to_i)
end

def validate_money(money_str)
  money_str =~ /^\d+(\.\d{1,2})?$/
end

def parse_money(money_str)
  (money_str.to_f * 100).round.to_i
end

def format_money(cents)
  dollars = cents / 100
  remainder = (cents % 100).abs
  if cents < 0
    "-#{dollars.abs}.#{remainder.to_s.rjust(2, '0')}"
  else
    "#{dollars}.#{remainder.to_s.rjust(2, '0')}"
  end
end

inventory = {}
all_skus = []
total_revenue = 0
total_cost = 0

STDIN.each_with_index do |line, idx|
  line_num = idx + 1
  line = line.strip

  next if line.empty?

  fields = line.split(/\s+/)
  command = fields[0]

  if command == "REPORT"
    if fields.length != 1
      puts "line #{line_num}: error: wrong field count"
      next
    end

    puts "SKU            QTY      VALUE"
    total_qty = 0
    total_value = 0
    all_skus.sort.each do |sku|
      qty = inventory[sku]&.sum { |_cost, q| q } || 0
      value = inventory[sku]&.sum { |cost, q| cost * q } || 0
      total_qty += qty
      total_value += value
      puts format("%-12s %5d %10s", sku, qty, format_money(value))
    end
    puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))

  elsif command == "RECEIVE"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    sku = fields[1]
    qty_str = fields[2]
    cost_str = fields[3]

    unless validate_sku(sku)
      puts "line #{line_num}: error: bad sku"
      next
    end

    unless validate_qty(qty_str)
      puts "line #{line_num}: error: bad quantity"
      next
    end

    unless validate_money(cost_str)
      puts "line #{line_num}: error: bad price"
      next
    end

    qty = qty_str.to_i
    cost = parse_money(cost_str)

    all_skus << sku unless all_skus.include?(sku)
    inventory[sku] ||= []
    inventory[sku] << [cost, qty]

  elsif command == "SHIP"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    sku = fields[1]
    qty_str = fields[2]
    price_str = fields[3]

    unless validate_sku(sku)
      puts "line #{line_num}: error: bad sku"
      next
    end

    unless validate_qty(qty_str)
      puts "line #{line_num}: error: bad quantity"
      next
    end

    unless validate_money(price_str)
      puts "line #{line_num}: error: bad price"
      next
    end

    qty = qty_str.to_i
    price = parse_money(price_str)

    unless inventory[sku]
      puts "line #{line_num}: error: unknown sku #{sku}"
      next
    end

    on_hand = inventory[sku].sum { |_, q| q }
    if on_hand < qty
      puts "line #{line_num}: error: insufficient stock for #{sku} (have #{on_hand}, need #{qty})"
      next
    end

    revenue = qty * price
    cost = 0
    remaining_qty = qty

    while remaining_qty > 0 && !inventory[sku].empty?
      lot_cost, lot_qty = inventory[sku][0]
      taken = [remaining_qty, lot_qty].min
      cost += lot_cost * taken
      remaining_qty -= taken
      inventory[sku][0][1] -= taken
      inventory[sku].shift if inventory[sku][0][1] == 0
    end

    total_revenue += revenue
    total_cost += cost

    puts "line #{line_num}: shipped #{qty} #{sku}: revenue #{format_money(revenue)}, cost #{format_money(cost)}"
  else
    puts "line #{line_num}: error: unknown command #{command}"
  end
end

puts "== final =="
puts "SKU            QTY      VALUE"
total_qty = 0
total_value = 0
all_skus.sort.each do |sku|
  qty = inventory[sku]&.sum { |_cost, q| q } || 0
  value = inventory[sku]&.sum { |cost, q| cost * q } || 0
  total_qty += qty
  total_value += value
  puts format("%-12s %5d %10s", sku, qty, format_money(value))
end
puts format("%-12s %5d %10s", "TOTAL", total_qty, format_money(total_value))
puts "revenue: #{format_money(total_revenue)}"
puts "cost of goods sold: #{format_money(total_cost)}"
puts "gross profit: #{format_money(total_revenue - total_cost)}"
