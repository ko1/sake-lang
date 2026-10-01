class MenuItem
  attr_reader :code, :name, :price, :station
  attr_accessor :stock

  def initialize(code, name, price, station, stock)
    @code = code
    @name = name
    @price = price
    @station = station
    @stock = stock
  end
end

class OrderLine
  attr_reader :table, :seat, :item, :mods, :at
  attr_accessor :status

  def initialize(table, seat, item, mods, at, status)
    @table = table
    @seat = seat
    @item = item
    @mods = mods
    @at = at
    @status = status
  end

  def price = item.price + mods.sum { |m| modifier_price(m) }
end

class Table
  attr_reader :number, :lines
  attr_accessor :open

  def initialize(number, lines, open)
    @number = number
    @lines = lines
    @open = open
  end
end

class SoldOut < StandardError
  attr_reader :code

  def initialize(message, code)
    super(message)
    @code = code
  end
end

def modifier_price(mod)
  case mod
  when "extra cheese" then 150
  when "bacon" then 200
  when "large" then 100
  else 0
  end
end

def money(c) = format("%d.%02d", c / 100, c % 100)

class Restaurant
  attr_reader :menu, :tables, :queue

  def initialize(menu)
    @menu = menu
    @tables = {}
    @queue = []
  end

  def table(n)
    @tables[n] ||= Table.new(n, [], true)
  end

  def order(n, seat, code, mods, at)
    item = @menu.fetch(code)
    raise SoldOut.new("#{item.name} is sold out", code) if item.stock == 0
    item.stock -= 1
    line = OrderLine.new(n, seat, item, mods, at, :queued)
    table(n).lines << line
    @queue << line
    line
  end

  # the kitchen cooks grill first, then fryer, then cold; older orders first
  def next_for(station)
    waiting = @queue.select { |l| l.status == :queued && l.item.station == station }
    first = waiting.min_by(&:at)
    first.status = :served if first
    first
  end
end

def bill(t, split)
  lines = t.lines
  subtotal = lines.sum(&:price)
  tax = (subtotal * 0.0875).round
  tip = (subtotal * 0.18).round
  total = subtotal + tax + tip
  puts "Table #{t.number}: subtotal #{money(subtotal)} tax #{money(tax)} tip #{money(tip)} total #{money(total)}"
  case split
  when :even
    seats = lines.map(&:seat).uniq.size
    share, extra = total.divmod(seats)
    seats.times { |i| puts "  guest #{i + 1} pays #{money(share + (i < extra ? 1 : 0))}" }
  when :by_seat
    by_seat = lines.group_by(&:seat)
    by_seat.keys.sort.each do |seat|
      own = by_seat.fetch(seat).sum(&:price)
      part = (own * total * 1.0 / subtotal).round
      items = by_seat.fetch(seat).map { |l| l.item.name }
      puts "  seat #{seat} pays #{money(part)} (#{items.join(", ")})"
    end
  end
  t.open = false
  total
end

menu = {}
[
  ["B1", "Burger", 1450, :grill, 10], ["B2", "Veggie burger", 1350, :grill, 1],
  ["F1", "Fries", 500, :fryer, 20], ["F2", "Onion rings", 650, :fryer, 2],
  ["S1", "Caesar salad", 1100, :cold, 5], ["D1", "Lemonade", 400, :cold, 30]
].each do |code, name, price, station, stock|
  menu[code] = MenuItem.new(code, name, price, station, stock)
end
r = Restaurant.new(menu)

orders = [
  [4, 1, "B1", ["bacon", "extra cheese"], 1], [4, 2, "B2", [], 2],
  [4, 2, "F2", ["large"], 3], [7, 1, "S1", [], 4], [7, 1, "D1", ["large"], 5],
  [4, 3, "B2", [], 6], [7, 2, "B1", [], 7], [7, 3, "F2", [], 8],
  [9, 1, "F2", [], 9], [9, 1, "F1", [], 10], [4, 3, "B1", ["no onion"], 11],
  [9, 2, "D1", [], 12]
]
orders.each do |n, seat, code, mods, at|
  r.order(n, seat, code, mods, at)
rescue SoldOut => e
  puts "t#{n} s#{seat}: #{e.message} (#{e.code})"
end

puts
puts "Kitchen:"
[:grill, :fryer, :cold].each do |station|
  served = 0
  while (l = r.next_for(station))
    extra = l.mods.empty? ? "" : " [#{l.mods.join(", ")}]"
    puts format("  %-5s t%d s%d %s%s", station, l.table, l.seat, l.item.name, extra)
    served += 1
  end
  puts "  #{station}: #{served} plates"
end

puts
takings = 0
[[4, :by_seat], [7, :even], [9, :even]].each do |n, split|
  takings += bill(r.table(n), split)
end
puts
puts "Takings: #{money(takings)}"
low = menu.values.select { |m| m.stock < 3 }
puts "Low stock: #{low.map { |m| "#{m.name}=#{m.stock}" }.join(", ")}"
puts "Open tables: #{r.tables.values.count(&:open)}"
