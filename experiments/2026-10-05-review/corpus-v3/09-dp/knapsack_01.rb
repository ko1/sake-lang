class Item
  attr_reader :name, :weight, :value

  def initialize(name, weight, value)
    @name = name
    @weight = weight
    @value = value
  end

  def to_s = "#{@name} (w=#{@weight}, v=#{@value})"
end

def build_table(items, capacity)
  n = items.size
  table = (0..n).map { (0..capacity).map { 0 } }
  1.upto(n) do |i|
    item = items[i - 1]
    w = item.weight
    v = item.value
    0.upto(capacity) do |c|
      best = table[i - 1][c]
      if w <= c
        with_item = table[i - 1][c - w] + v
        best = with_item if with_item > best
      end
      table[i][c] = best
    end
  end
  table
end

def chosen_items(items, table, capacity)
  picked = []
  c = capacity
  i = items.size
  while i > 0
    if table[i][c] != table[i - 1][c]
      item = items[i - 1]
      picked.unshift(item)
      c -= item.weight
    end
    i -= 1
  end
  picked
end

def solve(label, items, capacity)
  table = build_table(items, capacity)
  best = table[items.size][capacity]
  picked = chosen_items(items, table, capacity)
  used = picked.map(&:weight).sum
  puts "== #{label} (capacity #{capacity}) =="
  puts "best value: #{best}"
  puts "weight used: #{used}/#{capacity}"
  picked.each { |it| puts "  #{it}" }
  skipped = items.reject { |it| picked.include?(it) }
  puts "skipped: #{skipped.map(&:name).join(", ")}"
  best
end

camping = [
  Item.new("tent", 11, 40),
  Item.new("stove", 4, 15),
  Item.new("water", 6, 30),
  Item.new("food", 5, 25),
  Item.new("camera", 2, 12),
  Item.new("book", 1, 3),
  Item.new("rope", 3, 9),
  Item.new("lantern", 2, 8)
]

results = []
[10, 20, 30].each do |cap|
  results << [cap, solve("camping", camping, cap)]
end

parts = [
  Item.new("cpu", 3, 120),
  Item.new("gpu", 7, 300),
  Item.new("ram", 2, 60),
  Item.new("ssd", 2, 70),
  Item.new("fan", 1, 10)
]
results << [12, solve("parts", parts, 12)]

puts "== summary =="
results.each do |cap, value|
  ratio = (value / cap.to_f).round(2)
  puts format("%3d -> %4d (%.2f per unit)", cap, value, ratio)
end
