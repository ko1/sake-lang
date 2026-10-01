# Goldbach's conjecture checks: every even number has a prime-pair decomposition.
# Counts partitions (Goldbach's comet), finds the "hardest" evens, and checks the
# weak (ternary) conjecture for small odds.

def prime_table(limit)
  flags = [false, false] + Array.new(limit - 1, true)
  (2..Integer.sqrt(limit)).each do |i|
    next unless flags[i]
    (i * i).step(limit, i) { |j| flags[j] = false }
  end
  flags
end

def partitions(n, flags)
  (2..(n / 2)).select { |p| flags[p] && flags[n - p] }.map { |p| [p, n - p] }
end

def min_partition(n, flags, primes)
  p = primes.find { |q| flags[n - q] }
  p ? [p, n - p] : nil
end

limit = 1000
flags = prime_table(limit)
primes = (2..limit).select { |n| flags[n] }

puts "partitions of small evens:"
(4..40).step(6) do |n|
  ps = partitions(n, flags)
  puts "  #{n} = " + ps.map { |a, b| "#{a}+#{b}" }.join(" = ")
end

failures = (4..limit).step(2).select { |n| min_partition(n, flags, primes).nil? }
puts "evens <= #{limit} without a partition: #{failures.empty? ? "none" : failures}"

counts = {}
(4..limit).step(2) { |n| counts[n] = partitions(n, flags).size }

puts "Goldbach's comet (min / max count per block of 250):"
counts.to_a.each_slice(125) do |block|
  lo_n, lo_c = block.min_by { |e__| _, c = e__; c }
  hi_n, hi_c = block.max_by { |e__| _, c = e__; c }
  puts format("  %4d..%4d  min %2d at %4d   max %3d at %4d", block.first[0], block.last[0], lo_c, lo_n, hi_c, hi_n)
end

puts "evens with a record-large smallest prime in their partition:"
record = 0
(4..limit).step(2) do |n|
  pair = min_partition(n, flags, primes)
  next unless pair
  p, q = pair
  if p > record
    record = p
    puts "  #{n} = #{p} + #{q}"
  end
end

puts "multiples of 30 vs neighbours:"
[210, 420, 840, 1050].each do |n|
  puts "  " + [n - 2, n, n + 2].map { |m| "#{m}:#{counts[m]}" }.join("  ")
end

puts "weak Goldbach (odd n = p + q + r), fewest decompositions for 7..151:"
weak = {}
(7..151).step(2) do |n|
  c = 0
  small = primes.take_while { |p| p <= n }
  small.each do |p|
    small.each do |q|
      next if q < p || p + q > n
      r = n - p - q
      c += 1 if r >= q && flags[r]
    end
  end
  weak[n] = c
end
fewest = weak.to_a.sort_by { |e__| n, c = e__; [c, n] }.take(6)
puts "  " + fewest.map { |n, c| "#{n}(#{c})" }.join(" ")
