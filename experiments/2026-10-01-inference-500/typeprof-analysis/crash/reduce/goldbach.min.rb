def prime_table(limit)
  flags = [false, false] + Array.new(limit - 1, true)
end
def partitions(n, flags)
  (2..(n / 2)).select { |p| flags[p] && flags[n - p] }.map { |p| [p, n - p] }
end
limit = 1000
flags = prime_table(limit)
counts = {}
(4..limit).step(2) { |n| counts[n] = partitions(n, flags).size }
counts.to_a.each_slice(125) do |block|
  hi_n, hi_c = block.max_by { |_, c| c }
end
