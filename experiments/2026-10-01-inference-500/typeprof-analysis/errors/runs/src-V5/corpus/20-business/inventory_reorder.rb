class Item
  attr_reader :sku, :name, :supplier, :unit_cost, :case_pack
  attr_accessor :on_hand

  def initialize(sku, name, supplier, unit_cost, case_pack, on_hand)
    @sku = sku
    @name = name
    @supplier = supplier
    @unit_cost = unit_cost
    @case_pack = case_pack
    @on_hand = on_hand
  end
end

class Supplier
  attr_reader :name, :lead_days, :min_order

  def initialize(name, lead_days, min_order)
    @name = name
    @lead_days = lead_days
    @min_order = min_order
  end
end

class StockError < StandardError
  attr_reader :sku, :short

  def initialize(message, sku, short)
    super(message)
    @sku = sku
    @short = short
  end
end

ORDER_COST = 40.0
HOLDING_RATE = 0.25
SERVICE_Z = 1.65

def apply(items, mv)
  kind, sku, qty = mv
  item = items[sku]
  raise StockError.new("unknown sku", sku, 0) if !item    
  case kind
  when :receive, :return
    item.on_hand += qty
  when :sell
    have = item.on_hand
    raise StockError.new("only #{have} left", sku, qty - have) if have < qty
    item.on_hand = have - qty
  when :count
    diff = qty - item.on_hand
    item.on_hand = qty
    puts "  count #{sku}: adjusted by #{diff}" if diff != 0
  end
end

def mean(xs) = xs.sum * 1.0 / xs.size

def stdev(xs)
  m = mean(xs)
  Math.sqrt(xs.map { |x| (x - m)**2 }.sum / (xs.size - 1))
end

def round_up(n, step) = n.ceildiv(step) * step

items = {}
[
  ["P-100", "Paper A4 box", "Northwind", 18.5, 5, 40],
  ["P-200", "Toner black", "Contoso", 62.0, 1, 6],
  ["P-300", "Stapler", "Northwind", 7.25, 10, 25],
  ["P-400", "Pens (12)", "Fabrikam", 4.8, 24, 150],
  ["P-500", "Desk lamp", "Contoso", 29.9, 2, 9]
].each do |sku, name, sup, cost, pack, qty|
  items[sku] = Item.new(sku, name, sup, cost, pack, qty)
end
suppliers = {
  "Northwind" => Supplier.new("Northwind", 3, 150.0),
  "Contoso" => Supplier.new("Contoso", 7, 300.0),
  "Fabrikam" => Supplier.new("Fabrikam", 5, 0.0)
}

# daily sales for the last two weeks
sales = {
  "P-100" => [3, 4, 2, 5, 3, 0, 1, 4, 3, 5, 2, 3, 0, 1],
  "P-200" => [0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0],
  "P-300" => [1, 0, 2, 1, 0, 0, 0, 1, 1, 0, 2, 0, 0, 0],
  "P-400" => [12, 8, 10, 15, 9, 0, 0, 11, 14, 10, 9, 13, 0, 0],
  "P-500" => [0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]
}

movements = [
  [:sell, "P-100", 12], [:sell, "P-200", 2], [:receive, "P-400", 48],
  [:sell, "P-400", 190], [:sell, "P-300", 3], [:return, "P-100", 1],
  [:sell, "P-999", 1], [:sell, "P-500", 10], [:count, "P-300", 20],
  [:sell, "P-200", 3], [:count, "P-500", 9], [:sell, "P-500", 4]
]

puts "Movements:"
movements.each do |mv|
  apply(items, mv)
rescue StockError => e
  puts "  #{e.sku}: #{e.message} (short #{e.short})"
end

puts
puts format("%-6s %-13s %4s %6s %6s %5s %5s", "sku", "name", "have", "daily", "safety", "ROP", "EOQ")
orders = {}
items.each do |sku, item|
  history = sales.fetch(sku)
  daily = mean(history)
  sup = suppliers.fetch(item.supplier)
  lead = sup.lead_days
  safety = (SERVICE_Z * stdev(history) * Math.sqrt(lead)).ceil
  rop = (daily * lead).ceil + safety
  annual = daily * 365
  holding = item.unit_cost * HOLDING_RATE
  eoq = Math.sqrt(2 * annual * ORDER_COST / holding).round
  have = item.on_hand
  puts format("%-6s %-13s %4d %6.2f %6d %5d %5d", sku, item.name, have, daily, safety, rop, eoq)
  next if have > rop
  qty = round_up([eoq, rop - have].max, item.case_pack)
  (orders[item.supplier] ||= []) << [item, qty]
end

puts
puts "Purchase orders:"
orders.each do |sup_name, lines|
  sup = suppliers.fetch(sup_name)
  total = lines.sum { |item, qty| item.unit_cost * qty }
  puts "  #{sup_name} (lead #{sup.lead_days} days)"
  lines.each do |item, qty|
    puts format("    %-13s %4d x %6.2f = %8.2f", item.name, qty, item.unit_cost, item.unit_cost * qty)
  end
  if total < sup.min_order
    puts format("    total %.2f is below the minimum %.2f: hold until next week", total, sup.min_order)
  else
    puts format("    total %.2f", total)
  end
end

value = items.sum { |_sku, item| item.unit_cost * item.on_hand }
puts
puts format("Stock value: %.2f", value)
slow = sales.select { |_sku, h| h.count(0) >= 10 }
puts "Slow movers: #{slow.keys.join(", ")}"
