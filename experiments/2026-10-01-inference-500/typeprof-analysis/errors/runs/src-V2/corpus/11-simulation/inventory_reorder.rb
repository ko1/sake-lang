class Item
  attr_reader :sku, :name, :reorder_point, :reorder_qty, :lead_days, :unit_cost
  attr_accessor :on_hand

  def initialize(sku, name, on_hand, reorder_point, reorder_qty, lead_days, unit_cost)
    @sku = sku
    @name = name
    @on_hand = on_hand
    @reorder_point = reorder_point
    @reorder_qty = reorder_qty
    @lead_days = lead_days
    @unit_cost = unit_cost
  end
end

class PurchaseOrder
  attr_reader :sku, :qty, :arrives, :cost

  def initialize(sku, qty, arrives, cost)
    @sku = sku
    @qty = qty
    @arrives = arrives
    @cost = cost
  end
end

class Backorder
  attr_reader :customer, :sku, :day
  attr_accessor :qty

  def initialize(customer, sku, qty, day)
    @customer = customer
    @sku = sku
    @qty = qty
    @day = day
  end
end

class Warehouse
  attr_reader :items, :pending, :backorders, :log
  attr_accessor :spent, :revenue, :lost

  def initialize(items)
    @items = items
    @pending = []
    @backorders = []
    @log = []
    @spent = 0
    @revenue = 0
    @lost = 0
  end

  def item(sku) = @items.find { |i| i.sku == sku }

  def on_order(sku)
    @pending.select { |po| po.sku == sku }.sum(&:qty)
  end

  def receive(day)
    arrived = @pending.select { |po| po.arrives <= day }
    arrived.each do |po|
      itm = item(po.sku)
      itm.on_hand += po.qty
      @log << "day #{day}: received #{po.qty} #{itm.name}"
    end
    @pending.delete_if { |po| po.arrives <= day }
    fill_backorders(day)
  end

  def fill_backorders(day)
    @backorders.each do |bo|
      itm = item(bo.sku)
      want = bo.qty
      have = itm.on_hand
      next if have == 0
      give = [want, have].min
      itm.on_hand = have - give
      bo.qty = want - give
      @revenue += give * price(itm.unit_cost)
      @log << "day #{day}: backorder #{bo.customer} +#{give} #{itm.name}"
    end
    @backorders.delete_if { |bo| bo.qty == 0 }
  end

  def sell(day, customer, sku, qty)
    itm = item(sku)
    if itm.nil?
      @log << "day #{day}: #{customer} asked for unknown #{sku}"
      return
    end
    have = itm.on_hand
    sold = [qty, have].min
    itm.on_hand = have - sold
    @revenue += sold * price(itm.unit_cost)
    short = qty - sold
    if short > 0
      if short <= 10
        @backorders << Backorder.new(customer, sku, short, day)
      else
        @lost += short
        @log << "day #{day}: lost sale #{short} #{itm.name} to #{customer}"
      end
    end
  end

  def review(day)
    @items.each do |itm|
      position = itm.on_hand + on_order(itm.sku)
      @backorders.each { |bo| position -= bo.qty if bo.sku == itm.sku }
      if position <= itm.reorder_point
        qty = itm.reorder_qty
        cost = qty * itm.unit_cost
        @pending << PurchaseOrder.new(itm.sku, qty, day + itm.lead_days, cost)
        @spent += cost
        @log << "day #{day}: ordered #{qty} #{itm.name} (pos #{position})"
      end
    end
  end
end

def price(cost) = cost * 3 / 2

items = [
  Item.new("W1", "widget", 40, 15, 50, 3, 200),
  Item.new("G7", "gadget", 12, 8, 20, 5, 1250),
  Item.new("S3", "sprocket", 100, 30, 80, 2, 35)
]
wh = Warehouse.new(items)

demand = {
  1 => [["acme", "W1", 12], ["bolt", "S3", 30]],
  2 => [["acme", "G7", 5], ["core", "W1", 20]],
  3 => [["dyna", "S3", 45], ["bolt", "X9", 1]],
  4 => [["core", "G7", 9], ["acme", "W1", 15]],
  6 => [["dyna", "W1", 25], ["bolt", "S3", 40]],
  7 => [["acme", "G7", 30]],
  8 => [["core", "S3", 10], ["dyna", "W1", 4]],
  10 => [["bolt", "G7", 3], ["acme", "W1", 18]]
}

stock_history = {}
(1..12).each do |day|
  wh.receive(day)
  orders = demand[day]
  orders&.each { |customer, sku, qty| wh.sell(day, customer, sku, qty) }
  wh.review(day)
  stock_history[day] = items.map(&:on_hand)
end

wh.log.each { |line| puts line }
puts "--- stock by day"
stock_history.each do |day, levels|
  bar = levels.map { |n| n.to_s.rjust(4) }.join
  puts "#{day.to_s.rjust(3)}:#{bar}"
end
puts "--- summary"
puts "spent:   #{wh.spent}"
puts "revenue: #{wh.revenue}"
puts "lost units: #{wh.lost}"
puts "open backorders: #{wh.backorders.size}"
wh.backorders.each do |bo|
  puts "  #{bo.customer} #{bo.sku} x#{bo.qty} since day #{bo.day}"
end
puts "pending POs: #{wh.pending.size}"
low = items.min_by(&:on_hand)
puts "lowest stock: #{low.name}" if low
