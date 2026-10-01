# Goldbach's conjecture checks: every even number has a prime-pair decomposition.
# Counts partitions (Goldbach's comet), finds the "hardest" evens, and checks the
# weak (ternary) conjecture for small odds.

def prime_table(limit)
  flags = [false, false] + Array.new(limit - 1, true)
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

failures = (4..limit).step(2).select { |n| min_partition(n, flags, primes).nil? }
puts "evens <= #{limit} without a partition: #{failures.empty? ? "none" : failures}"

counts = {}
(4..limit).step(2) { |n| counts[n] = partitions(n, flags).size }

puts "Goldbach's comet (min / max count per block of 250):"
counts.to_a.each_slice(125) do |block|
  lo_n, lo_c = block.min_by { |_, c| c }
  hi_n, hi_c = block.max_by { |_, c| c }
end

puts "evens with a record-large smallest prime in their partition:"
record = 0

puts "multiples of 30 vs neighbours:"
[210, 420, 840, 1050].each do |n|
  puts "  " + [n - 2, n, n + 2].map { |m| "#{m}:#{counts[m]}" }.join("  ")
end

puts "weak Goldbach (odd n = p + q + r), fewest decompositions for 7..151:"
weak = {}
fewest = weak.to_a.sort_by { |n, c| [c, n] }.take(6)
puts "  " + fewest.map { |n, c| "#{n}(#{c})" }.join(" ")
