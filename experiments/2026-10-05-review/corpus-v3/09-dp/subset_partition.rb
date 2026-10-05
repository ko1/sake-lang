require "set"

# reachable[s]: some subset of the items so far sums to s; via[s] = item that first reached s
def subset_sums(items)
  total = items.sum
  reachable = Array.new(total + 1, false)
  via = Array.new(total + 1)
  reachable[0] = true
  items.each_with_index do |w, idx|
    total.downto(w) do |s|
      if !reachable[s] && reachable[s - w]
        reachable[s] = true
        via[s] = idx
      end
    end
  end
  [reachable, via]
end

def pick(items, via, target)
  used = []
  s = target
  while s > 0
    idx = via[s]
    used.unshift(idx)
    s -= items[idx]
  end
  used
end

def balance(label, items)
  total = items.sum
  reachable, via = subset_sums(items)
  target = total / 2
  target -= 1 until reachable[target]
  side_a = pick(items, via, target)
  side_b = (0...items.size).reject { |i| side_a.include?(i) }
  a_vals = side_a.map { |i| items[i] }
  b_vals = side_b.map { |i| items[i] }
  diff = total - 2 * target
  verdict = diff == 0 ? "perfect split" : "difference #{diff}"
  puts "#{label}: total #{total}, #{verdict}"
  puts "  A #{a_vals.sum}: #{a_vals.join(" + ")}"
  puts "  B #{b_vals.sum}: #{b_vals.join(" + ")}"
end

def count_subsets(items, target)
  ways = Hash.new(0)
  ways[0] = 1
  items.each do |w|
    ways.to_a.each do |s, c|
      ways[s + w] += c if s + w <= target
    end
  end
  ways[target]
end

def reachable_sums(items)
  sums = Set[0]
  items.each do |w|
    sums.map { |s| s + w }.each { |s| sums << s }
  end
  sums
end

jobs = {
  "render farm" => [15, 5, 20, 10, 35, 15, 10],
  "moving boxes" => [3, 1, 4, 2, 2, 1],
  "odd total" => [8, 6, 5, 3, 1],
  "lopsided" => [50, 3, 4, 5],
  "single" => [7]
}
jobs.each { |label, items| balance(label, items) }

items = [2, 3, 5, 6, 8, 10]
puts "subsets of #{items} summing to:"
[10, 13, 17, 34, 1].each do |t|
  puts format("  %2d -> %d", t, count_subsets(items, t))
end

sums = reachable_sums([3, 7, 12])
sorted = sums.sort
missing = (0..sorted.max).reject { |s| sums.include?(s) }
puts "sums from 3, 7, 12: #{sorted.join(" ")}"
puts "unreachable below #{sorted.max}: #{missing.size} values, largest #{missing.max}"
