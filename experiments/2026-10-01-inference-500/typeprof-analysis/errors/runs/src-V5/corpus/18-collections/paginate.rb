# Paginating a filtered, sorted catalog: Array slices by Range, page windows, cursors, and out-of-range pages.

class Product
  attr_reader :sku, :name, :category, :price, :stock

  def initialize(sku, name, category, price, stock)
    @sku = sku
    @name = name
    @category = category
    @price = price
    @stock = stock
  end
end

def catalog
  rows = [
    "A1 kettle kitchen 25.0 4", "A2 toaster kitchen 30.0 0", "A3 blender kitchen 55.5 2",
    "B1 lamp living 18.0 10", "B2 rug living 120.0 1", "B3 cushion living 9.5 25",
    "C1 drill garage 80.0 3", "C2 ladder garage 65.0 0", "C3 toolbox garage 22.0 7",
    "D1 pan kitchen 19.9 12", "D2 knife kitchen 14.0 30", "D3 whisk kitchen 4.5 40",
    "E1 shelf living 45.0 5", "E2 clock living 27.0 8"
  ]
  rows.map do |r|
    sku, name, cat, price, stock = r.split(" ")
    Product.new(sku, name, cat.to_sym, price.to_f, stock.to_i)
  end
end

def page_count(total, per) = total.ceildiv(per)

def page(items, number, per)
  return nil if number < 1
  from = (number - 1) * per
  slice = items[from...(from + per)]
  return nil if !slice     || slice.empty?
  {number: number, items: slice, first: from + 1, last: from + slice.size, total: items.size}
end

def window(current, pages, width)
  half = width / 2
  lo = (current - half).clamp(1, (pages - width + 1).clamp(1, pages))
  hi = (lo + width - 1).clamp(1, pages)
  (lo..hi).to_a
end

def nav(current, pages)
  parts = window(current, pages, 3).map { |n| n == current ? "[#{n}]" : n.to_s }
  parts.unshift("<") if current > 1
  parts.push(">") if current < pages
  parts.join(" ")
end

def show(pg, pages)
  if !pg    
    puts "  (no such page)"
    return
  end
  puts "  page #{pg[:number]}/#{pages}: items #{pg[:first]}-#{pg[:last]} of #{pg[:total]}   #{nav(pg[:number], pages)}"
  pg[:items].each { |p| puts format("    %-3s %-9s %7.2f", p.sku, p.name, p.price) }
end

products = catalog
in_stock = products.select { |p| p.stock > 0 }.sort_by(&:price)
per = 4
pages = page_count(in_stock.size, per)
puts "in stock: #{in_stock.size} of #{products.size}, #{pages} pages of #{per}"
[1, 3, 0, 9].each do |n|
  puts "request page #{n}:"
  show(page(in_stock, n, per), pages)
end

puts "== Cursor-based (after sku) =="
by_sku = products.sort_by(&:sku)
cursor = nil
batch = 0
loop do
  start = !cursor     ? 0 : by_sku.find_index { |p| p.sku == cursor } + 1
  chunk = by_sku.drop(start).take(5)
  break if chunk.empty?
  batch += 1
  puts "  batch #{batch}: #{chunk.map(&:sku).join(" ")}"
  cursor = chunk.last.sku
end

puts "== Per category, 2 per page =="
groups = in_stock.group_by(&:category)
groups.keys.sort.each do |cat|
  slices = groups[cat].each_slice(2).map { |s| s.map(&:name).join("+") }
  puts "  #{cat}: #{slices.join(" | ")}"
end
middle = in_stock[3..5]
puts "items 4..6: #{middle.map(&:name).join(", ")}"
p in_stock[50..52]
last_page = page(in_stock, pages, per)
puts "last page holds #{last_page[:items].size}; cheapest overall #{in_stock.first.name}, priciest #{in_stock.last.name}"
