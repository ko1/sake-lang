# Compare two inventory snapshots (SKU => quantity, price) and produce a change report.

class ParseError < StandardError
  attr_reader :line_no

  def initialize(message, line_no)
    super(message)
    @line_no = line_no
  end
end

class Item
  attr_reader :sku, :qty, :price

  def initialize(sku, qty, price)
    @sku = sku
    @qty = qty
    @price = price
  end

  def value = qty * price
end

def parse_snapshot(text)
  items = {}
  text.lines.each_with_index do |line, i|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    m = line.match(/\A([A-Z]{2}-\d{3})\s+(\d+)\s+(\d+\.\d\d)\z/)
    raise ParseError.new("bad line: #{line}", i + 1) unless m
    sku = m[1]
    raise ParseError.new("duplicate #{sku}", i + 1) if items.key?(sku)
    items[sku] = Item.new(sku, m[2].to_i, m[3].to_f)
  end
  items
end

def money(x) = format("%.2f", x)

def report(old, new)
  old_keys = old.keys.to_set
  new_keys = new.keys.to_set
  added = (new_keys - old_keys).sort
  removed = (old_keys - new_keys).sort
  common = (old_keys & new_keys).sort

  puts "added (#{added.size}):"
  added.each { |k| puts "  + #{k} qty=#{new[k].qty} @ #{money(new[k].price)}" }
  puts "removed (#{removed.size}):"
  removed.each { |k| puts "  - #{k} qty=#{old[k].qty}" }

  changed = common.filter_map do |k|
    a = old[k]
    b = new[k]
    dq = b.qty - a.qty
    dp = b.price - a.price
    next nil if dq == 0 && dp.abs < 0.005
    [k, dq, dp]
  end
  puts "changed (#{changed.size}):"
  changed.each do |k, dq, dp|
    parts = []
    parts << format("qty %+d", dq) if dq != 0
    parts << format("price %+.2f", dp) if dp.abs >= 0.005
    puts "  ~ #{k} #{parts.join(", ")}"
  end
  puts "unchanged: #{common.size - changed.size}"

  total_old = old.values.sum(&:value)
  total_new = new.values.sum(&:value)
  puts "stock value: #{money(total_old)} -> #{money(total_new)} (#{format("%+.2f", total_new - total_old)})"

  by_prefix = new.values.group_by { |it| it.sku[0..1] }.transform_values { |items| items.sum(&:qty) }
  puts "units by category: #{by_prefix.sort_by { |e__1| c, n = e__1; c }.map { |e__0| c, n = e__0; "#{c}=#{n}" }.join(" ")}"
  low = new.select { |k, it| it.qty < 5 }.keys.sort
  puts "low stock: #{low.empty? ? "-" : low.join(", ")}"
end

monday = <<~INV
  # sku     qty  price
  HW-001    40   2.50
  HW-002    12   7.25
  EL-100     3  19.99
  EL-101    25   4.10
  PA-500   100   0.15
INV

tuesday = <<~INV
  HW-001    32   2.50
  HW-002    12   7.75
  EL-101    25   4.10
  EL-102     8  12.00
  PA-500    96   0.15
  PA-501     2   0.90
INV

broken = <<~INV
  HW-001    32   2.50
  HW-01X    12   7.75
INV

dupes = <<~INV
  HW-001    1   2.50
  HW-001    2   2.50
INV

old = parse_snapshot(monday)
new = parse_snapshot(tuesday)
report(old, new)

[broken, dupes].each do |text|
  parse_snapshot(text)
  puts "parsed ok"
rescue ParseError => e
  puts "line #{e.line_no}: #{e.message}"
end

missing = new.fetch("ZZ-999", nil)
p missing
p new.dig("EL-102") != nil
