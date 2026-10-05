# Compare judges' rankings of the same contestants by counting inversions
# (Kendall tau distance) with a merge sort.

def merge_count(left, right)
  merged = []
  i = 0
  j = 0
  inv = 0
  while i < left.size && j < right.size
    if left[i] <= right[j]
      merged << left[i]
      i += 1
    else
      merged << right[j]
      inv += left.size - i
      j += 1
    end
  end
  merged.concat(left.drop(i))
  merged.concat(right.drop(j))
  [merged, inv]
end

def sort_count(a)
  return [a.dup, 0] if a.size <= 1
  mid = a.size / 2
  left, li = sort_count(a.take(mid))
  right, ri = sort_count(a.drop(mid))
  merged, mi = merge_count(left, right)
  [merged, li + ri + mi]
end

def brute_inversions(a)
  n = 0
  a.each_with_index do |x, i|
    (i + 1).upto(a.size - 1) { |j| n += 1 if x > a[j] }
  end
  n
end

# Turn judge B's order into positions in judge A's order.
def relative_order(a, b)
  pos = {}
  a.each_with_index { |name, i| pos[name] = i }
  b.map { |name| pos.fetch(name) }
end

def kendall_tau(a, b)
  n = a.size
  _, inv = sort_count(relative_order(a, b))
  pairs = n * (n - 1) / 2
  [inv, 1.0 - 2.0 * inv / pairs]
end

judges = {
  "ito" => %w[kai mio ren sora yui aoi haru nana],
  "kato" => %w[mio kai ren yui sora aoi nana haru],
  "mori" => %w[nana haru aoi yui sora ren mio kai],
  "sato" => %w[kai ren mio sora aoi yui haru nana]
}

names = judges.keys
names.each_with_index do |a, i|
  names.drop(i + 1).each do |b|
    inv, tau = kendall_tau(judges[a], judges[b])
    puts format("%-5s vs %-5s inversions=%2d tau=%+.3f", a, b, inv, tau)
  end
end

nums = [8, 4, 2, 1, 7, 3, 9, 5, 6, 0, 11, 10]
sorted, inv = sort_count(nums)
puts "sorted: #{sorted.join(" ")}"
puts "inversions: #{inv} (brute force #{brute_inversions(nums)})"

begin
  relative_order(judges["ito"], ["kai", "zed"])
rescue KeyError => e
  puts "unknown contestant in list: #{["kai", "zed"].join(",")}"
end

consensus = Hash.new(0)
judges.each_value do |order|
  order.each_with_index { |name, i| consensus[name] += i }
end
board = consensus.sort_by { |name, total| [total, name] }
board.each_with_index { |(name, total), i| puts format("%d. %-5s %2d", i + 1, name, total) }
