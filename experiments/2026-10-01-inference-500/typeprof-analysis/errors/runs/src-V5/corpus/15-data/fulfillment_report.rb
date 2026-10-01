require "set"

class Product
  attr_reader :sku, :name, :category, :price, :weight_g

  def initialize(sku, name, category, price, weight_g)
    @sku = sku
    @name = name
    @category = category
    @price = price
    @weight_g = weight_g
  end
end

class Order
  attr_reader :id, :customer, :placed, :promised, :lines

  def initialize(id, customer, placed, promised, lines)
    @id = id
    @customer = customer
    @placed = placed
    @promised = promised
    @lines = lines
  end
end

class OrderLine
  attr_reader :sku, :qty

  def initialize(sku, qty)
    @sku = sku
    @qty = qty
  end
end

class Shipment
  attr_reader :order_id, :sku, :qty, :shipped, :carrier

  def initialize(order_id, sku, qty, shipped, carrier)
    @order_id = order_id
    @sku = sku
    @qty = qty
    @shipped = shipped
    @carrier = carrier
  end
end

def products
  [
    Product.new("TEA-01", "Sencha 100g", :tea, 1290, 120),
    Product.new("TEA-02", "Genmaicha 200g", :tea, 990, 220),
    Product.new("TEA-03", "Matcha 30g", :tea, 2450, 45),
    Product.new("POT-01", "Kyusu teapot", :ware, 5800, 650),
    Product.new("CUP-01", "Yunomi cup", :ware, 1600, 210),
    Product.new("ACC-01", "Bamboo whisk", :accessory, 1850, 40)
  ]
end

def orders
  [
    Order.new(501, "Hana", 2, 5, [OrderLine.new("TEA-01", 2), OrderLine.new("CUP-01", 2)]),
    Order.new(502, "Ivo", 2, 4, [OrderLine.new("POT-01", 1), OrderLine.new("TEA-03", 1), OrderLine.new("ACC-01", 1)]),
    Order.new(503, "Jun", 3, 6, [OrderLine.new("TEA-02", 5)]),
    Order.new(504, "Kai", 4, 7, [OrderLine.new("TEA-09", 1), OrderLine.new("CUP-01", 4)]),
    Order.new(505, "Lea", 5, 8, [OrderLine.new("TEA-03", 3), OrderLine.new("ACC-01", 1)]),
    Order.new(506, "Mo", 6, 9, [OrderLine.new("POT-01", 2)])
  ]
end

def shipments
  [
    Shipment.new(501, "TEA-01", 2, 3, "post"), Shipment.new(501, "CUP-01", 2, 4, "post"),
    Shipment.new(502, "POT-01", 1, 6, "courier"), Shipment.new(502, "TEA-03", 1, 3, "post"),
    Shipment.new(503, "TEA-02", 3, 5, "post"), Shipment.new(504, "CUP-01", 4, 6, "courier"),
    Shipment.new(505, "TEA-03", 3, 6, "post"), Shipment.new(505, "ACC-01", 1, 6, "post"),
    Shipment.new(507, "TEA-01", 1, 7, "post")
  ]
end

def yen(n) = "¥" + n.to_s.reverse.scan(/\d{1,3}/).join(",").reverse

def fulfillment(order, shipped_qty)
  wanted = order.lines.sum(&:qty)
  sent = order.lines.sum { |l| shipped_qty[[order.id, l.sku]] }
  if sent == 0 then :pending
  elsif sent < wanted then :partial
  else :complete
  end
end

catalog = products.to_h { |p| [p.sku, p] }
all_orders = orders
order_ids = all_orders.map(&:id).to_set

shipped_qty = Hash.new(0)
last_ship = {}
stray = []
all_shipments = shipments
all_shipments.each do |s|
  unless order_ids.include?(s.order_id)
    stray << s
    next
  end
  shipped_qty[[s.order_id, s.sku]] += s.qty
  prev = last_ship[s.order_id]
  last_ship[s.order_id] = s.shipped if !prev     || s.shipped > prev
end

puts "Orders"
revenue_by_cat = Hash.new(0)
problems = []
all_orders.each do |o|
  total = 0
  weight = 0
  o.lines.each do |l|
    begin
      p = catalog.fetch(l.sku)
    rescue KeyError
      problems << "order #{o.id}: unknown sku #{l.sku}"
      next
    end
    amount = p.price * l.qty
    total += amount
    weight += p.weight_g * l.qty
    revenue_by_cat[p.category] += amount
  end
  status = fulfillment(o, shipped_qty)
  done = last_ship[o.id]
  timing = case status
           in :complete then done && done > o.promised ? "late by #{done - o.promised}d" : "on time"
           in :partial then "waiting"
           in :pending then "not shipped"
           end
  puts format("  #%d %-5s %10s %5.2fkg  %-8s %s", o.id, o.customer, yen(total), weight / 1000.0, status, timing)
end

puts
puts "Open lines"
all_orders.each do |o|
  o.lines.each do |l|
    sent = shipped_qty[[o.id, l.sku]]
    missing = l.qty - sent
    next if missing <= 0
    p = catalog[l.sku]
    name = p ? p.name : "?"
    puts format("  #%d %-7s %-15s %d of %d outstanding", o.id, l.sku, name, missing, l.qty)
  end
end

puts
puts "Revenue by category"
cat_total = revenue_by_cat.values.sum
revenue_by_cat.sort_by { |c, v| -v }.each do |c, v|
  puts format("  %-10s %10s %5.1f%%", c, yen(v), v * 100.0 / cat_total)
end

puts
puts "Carriers"
by_carrier = all_shipments.reject { |s| stray.include?(s) }.group_by(&:carrier)
by_carrier.each do |carrier, list|
  days = list.map do |s|
    o = all_orders.find { |ord| ord.id == s.order_id }
    o ? s.shipped - o.placed : 0
  end
  puts format("  %-8s %d parcels, avg %.1f days after order", carrier, list.size, days.sum * 1.0 / days.size)
end

puts
puts "Problems"
problems.each { |pr| puts "  #{pr}" }
stray.each { |s| puts "  shipment for unknown order #{s.order_id} (#{s.sku})" }
never = products.reject { |p| all_orders.any? { |o| o.lines.any? { |l| l.sku == p.sku } } }
never.each { |p| puts "  #{p.sku} was never ordered" }
