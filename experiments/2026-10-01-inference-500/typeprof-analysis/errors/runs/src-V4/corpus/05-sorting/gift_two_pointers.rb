# Gift shopping with a sorted price list: the pair that best uses a budget
# (two pointers), all pairs summing to an exact amount, the three-item bundle
# closest to a target, and pairs whose prices differ by a fixed step.

def price(c) = format("$%d.%02d", c / 100, c % 100)

class Item
  attr_reader :name, :cents

  def initialize(name, cents)
    @name = name
    @cents = cents
  end

  def to_s = "#{name} #{price(cents)}"
end

def best_pair(items, budget)
  i = 0
  j = items.size - 1
  best = nil
  best_sum = 0
  while i < j
    s = items[i].cents + items[j].cents
    if s > budget
      j -= 1
    else
      if s > best_sum
        best_sum = s
        best = [items[i], items[j]]
      end
      i += 1
    end
  end
  best
end

def exact_pairs(items, total)
  out = []
  i = 0
  j = items.size - 1
  while i < j
    s = items[i].cents + items[j].cents
    if s == total
      out << "#{items[i].name}+#{items[j].name}"
      i += 1
      j -= 1
    elsif s < total
      i += 1
    else
      j -= 1
    end
  end
  out
end

def closest_triple(items, target)
  n = items.size
  best = nil
  best_diff = nil
  (0..n - 3).each do |a|
    lo = a + 1
    hi = n - 1
    while lo < hi
      s = items[a].cents + items[lo].cents + items[hi].cents
      d = (s - target).abs
      if !best_diff     || d < best_diff
        best_diff = d
        best = [items[a], items[lo], items[hi]]
      end
      return [best, 0] if s == target
      if s < target
        lo += 1
      else
        hi -= 1
      end
    end
  end
  [best, best_diff]
end

def pairs_with_gap(items, gap)
  out = []
  j = 0
  items.each_with_index do |x, i|
    j = i + 1 if j <= i
    j += 1 while j < items.size && items[j].cents - x.cents < gap
    out << [x.name, items[j].name] if j < items.size && items[j].cents - x.cents == gap
  end
  out
end

catalog = {
  "candle" => 1250, "socks" => 899, "mug" => 1450, "book" => 2399, "scarf" => 3100,
  "puzzle" => 1999, "tea set" => 4250, "plant" => 1650, "notebook" => 750, "headphones" => 5999,
  "chocolate" => 650, "poster" => 1100
}
items = catalog.map { |n, c| Item.new(n, c) }.sort_by(&:cents)
puts "sorted: #{items.map(&:name).join(", ")}"

[2000, 5000, 1000, 1200].each do |budget|
  pair = best_pair(items, budget)
  if pair
    a, b = pair
    puts "budget #{price(budget)}: #{a} + #{b} = #{price(a.cents + b.cents)}"
  else
    puts "budget #{price(budget)}: nothing fits"
  end
end

puts "exactly $27.50: #{exact_pairs(items, 2750)}"
puts "exactly $99.99: #{exact_pairs(items, 9999)}"

[5000, 10000].each do |target|
  trio, diff = closest_triple(items, target)
  puts "bundle near #{price(target)}: #{trio.map(&:name).join(", ")} = #{price(trio.sum(&:cents))} (off by #{price(diff)})"
end

pairs_with_gap(items, 200).each { |cheap, dear| puts "#{dear} costs $2.00 more than #{cheap}" }
under = items.take_while { |it| it.cents < 1500 }
puts "#{under.size} gifts under $15: #{under.join("; ")}"
