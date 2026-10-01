# In-place quicksort (median-of-three pivot, insertion sort for small ranges),
# generic over a key given by a block. Used on a product catalog.

class Product
  attr_reader :sku, :name, :price, :stock

  def initialize(sku, name, price, stock)
    @sku = sku
    @name = name
    @price = price
    @stock = stock
  end
end

class Stats
  attr_accessor :compares, :swaps, :max_depth

  def initialize(compares, swaps, max_depth)
    @compares = compares
    @swaps = swaps
    @max_depth = max_depth
  end
end

def swap(a, i, j, stats)
  a[i], a[j] = a[j], a[i]
  stats.swaps += 1
end

def less(a, i, j, stats)
  stats.compares += 1
  yield(a[i]) < yield(a[j])
end

def insertion(a, lo, hi, stats, &key)
  (lo + 1).upto(hi) do |i|
    j = i
    while j > lo && less(a, j, j - 1, stats, &key)
      swap(a, j, j - 1, stats)
      j -= 1
    end
  end
end

def median3(a, lo, hi, stats, &key)
  mid = (lo + hi) / 2
  swap(a, mid, lo, stats) if less(a, mid, lo, stats, &key)
  swap(a, hi, lo, stats) if less(a, hi, lo, stats, &key)
  swap(a, hi, mid, stats) if less(a, hi, mid, stats, &key)
  mid
end

def quicksort(a, lo, hi, depth, stats, &key)
  stats.max_depth = depth if depth > stats.max_depth
  if hi - lo < 6
    insertion(a, lo, hi, stats, &key)
    return a
  end
  mid = median3(a, lo, hi, stats, &key)
  swap(a, mid, hi - 1, stats)
  pivot = hi - 1
  i = lo
  j = hi - 1
  loop do
    i += 1
    i += 1 while less(a, i, pivot, stats, &key)
    j -= 1
    j -= 1 while j > lo && less(a, pivot, j, stats, &key)
    break if i >= j
    swap(a, i, j, stats)
  end
  swap(a, i, hi - 1, stats)
  quicksort(a, lo, i - 1, depth + 1, stats, &key)
  quicksort(a, i + 1, hi, depth + 1, stats, &key)
  a
end

def sort_by_key(items, &key)
  a = items.dup
  stats = Stats.new(0, 0, 0)
  quicksort(a, 0, a.size - 1, 1, stats, &key)
  [a, stats]
end

def sorted?(a)
  a.each_cons(2).all? { |x, y| yield(x) <= yield(y) }
end

def report(label, stats)
  puts format("%-10s compares=%d swaps=%d depth=%d", label,
              stats.compares, stats.swaps, stats.max_depth)
end

catalog = [
  Product.new("A100", "kettle", 34.5, 12), Product.new("A101", "toaster", 29.99, 3),
  Product.new("B200", "blender", 89.0, 7), Product.new("B201", "mixer", 149.5, 0),
  Product.new("C300", "mug", 6.25, 120), Product.new("C301", "teapot", 22.0, 15),
  Product.new("D400", "scale", 18.75, 40), Product.new("D401", "grinder", 54.0, 9),
  Product.new("E500", "whisk", 4.5, 65), Product.new("E501", "ladle", 7.8, 33),
  Product.new("F600", "wok", 41.0, 5), Product.new("F601", "pan", 38.0, 21),
  Product.new("G700", "knife", 64.9, 18), Product.new("G701", "board", 15.0, 26)
]

by_price, st = sort_by_key(catalog, &:price)
report("price", st)
by_price.each { |pr| puts format("  %-5s %-8s %7.2f", pr.sku, pr.name, pr.price) }

by_name, st = sort_by_key(catalog, &:name)
report("name", st)
puts "  " + by_name.map(&:name).join(", ")

by_stock, st = sort_by_key(catalog, &:stock)
report("stock", st)
puts "  out of stock first: #{by_stock[0].name}; most stocked: #{by_stock.last.name}"

nums = []
x = 7
200.times do
  x = (x * 1103 + 12345) % 1000
  nums << x
end
sorted_nums, st = sort_by_key(nums) { |n| n }
report("ints", st)
puts "  first=#{sorted_nums.take(6)} last=#{sorted_nums[-1]} ok=#{sorted?(sorted_nums) { |n| n }}"

already, st = sort_by_key(sorted_nums) { |n| n }
report("presorted", st)
desc, st = sort_by_key(sorted_nums) { |n| -n }
report("reversed", st)
puts "  top3=#{desc.take(3)} ok=#{sorted?(desc) { |n| -n }}"
