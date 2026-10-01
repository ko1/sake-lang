class Item
  attr_reader :sku, :name, :qty, :price, :bin

  def initialize(sku, name, qty, price, bin)
    @sku = sku
    @name = name
    @qty = qty
    @price = price
    @bin = bin
  end

  def ==(other)
    other.is_a?(Item) && sku == other.sku && name == other.name && qty == other.qty &&
      price == other.price && bin == other.bin
  end
end

class Change
  attr_reader :sku, :field, :before, :after

  def initialize(sku, field, before, after)
    @sku = sku
    @field = field
    @before = before
    @after = after
  end
end

def parse_snapshot(text)
  items = {}
  text.each_line do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    cols = line.split("|").map(&:strip)
    sku = cols.fetch(0)
    items[sku] = Item.new(sku, cols.fetch(1), cols.fetch(2).to_i, cols.fetch(3).to_f, cols.fetch(4))
  end
  items
end

def before_text
  <<~TXT
    # sku   | name             | qty | price  | bin
    A-100   | Hex bolt M6      | 500 | 0.12   | R1-04
    A-101   | Hex bolt M8      | 320 | 0.18   | R1-05
    B-200   | Washer 6mm       | 1000| 0.03   | R1-06
    C-310   | Hinge, brass     | 45  | 3.75   | R4-01
    D-420   | Cabinet handle   | 60  | 5.20   | R4-02
    E-505   | Drawer slide 45cm| 18  | 12.90  | R5-11
  TXT
end

def after_text
  <<~TXT
    # sku   | name             | qty | price  | bin
    A-100   | Hex bolt M6      | 430 | 0.12   | R1-04
    A-101   | Hex bolt M8      | 320 | 0.21   | R1-05
    C-310   | Hinge, brass     | 45  | 3.75   | R2-09
    D-420   | Cabinet handle   | 12  | 5.45   | R4-02
    E-505   | Drawer slide 45cm| 18  | 12.90  | R5-11
    F-600   | Shelf pin 5mm    | 800 | 0.05   | R1-07
    F-601   | Shelf pin 3mm    | 250 | 0.04   | R1-08
  TXT
end

def field_changes(a, b)
  changes = []
  changes << Change.new(a.sku, "name", a.name, b.name) if a.name != b.name
  changes << Change.new(a.sku, "qty", a.qty, b.qty) if a.qty != b.qty
  changes << Change.new(a.sku, "price", a.price, b.price) if a.price != b.price
  changes << Change.new(a.sku, "bin", a.bin, b.bin) if a.bin != b.bin
  changes
end

def show(v)
  case v
  in Float then format("%.2f", v)
  in Integer then v.to_s
  in String then v
  end
end

def stock_value(items) = items.sum { |sku, it| it.qty * it.price }

old_items = parse_snapshot(before_text)
new_items = parse_snapshot(after_text)

added = new_items.keys.reject { |k| old_items.key?(k) }
removed = old_items.keys.reject { |k| new_items.key?(k) }
common = old_items.keys.select { |k| new_items.key?(k) }
unchanged = common.select { |sku| old_items.fetch(sku) == new_items.fetch(sku) }
changes = common.flat_map { |sku| field_changes(old_items.fetch(sku), new_items.fetch(sku)) }

puts "Snapshot diff: #{old_items.size} -> #{new_items.size} items"
puts "  added #{added.size}, removed #{removed.size}, changed #{common.size - unchanged.size}, unchanged #{unchanged.size}"
puts

added.sort.each do |sku|
  it = new_items.fetch(sku)
  puts format("+ %-6s %-18s qty %4d @ %6.2f in %s", sku, it.name, it.qty, it.price, it.bin)
end
removed.sort.each do |sku|
  it = old_items.fetch(sku)
  puts format("- %-6s %-18s qty %4d (value %.2f written off)", sku, it.name, it.qty, it.qty * it.price)
end
changes.group_by(&:sku).each do |sku, list|
  desc = list.map { |c| "#{c.field} #{show(c.before)} -> #{show(c.after)}" }
  puts format("~ %-6s %s", sku, desc.join("; "))
end
puts

qty_moves = changes.select { |c| c.field == "qty" }
qty_moves.each do |c|
  pct = (c.after - c.before) * 100.0 / c.before
  flag = pct <= -50 ? "  LOW STOCK" : ""
  puts format("qty %-6s %5d -> %5d (%+.1f%%)%s", c.sku, c.before, c.after, pct, flag)
end
price_moves = changes.select { |c| c.field == "price" }
avg = price_moves.empty? ? 0.0 : price_moves.sum { |c| (c.after - c.before) / c.before } / price_moves.size * 100
puts format("average price change across %d items: %+.1f%%", price_moves.size, avg)
v0 = stock_value(old_items)
v1 = stock_value(new_items)
puts format("stock value %.2f -> %.2f (%+.2f)", v0, v1, v1 - v0)
