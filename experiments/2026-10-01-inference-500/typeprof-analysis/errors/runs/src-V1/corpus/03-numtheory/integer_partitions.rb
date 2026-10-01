# Integer partitions: enumeration with a generator (yield), counting by dynamic
# programming, Euler's distinct/odd parts theorem, and the pentagonal recurrence.

def each_partition(n, max_part, prefix, &block)
  if n == 0
    yield prefix
    return
  end
  [n, max_part].min.downto(1) do |part|
    each_partition(n - part, part, prefix + [part], &block)
  end
end

def count_table(limit, parts)
  ways = [1] + [0] * limit
  parts.each do |part|
    (part..limit).each { |s| ways[s] += ways[s - part] }
  end
  ways
end

def distinct_count(limit)
  ways = [1] + [0] * limit
  (1..limit).each do |part|
    limit.downto(part) { |s| ways[s] += ways[s - part] }
  end
  ways
end

def pentagonal_p(limit)
  p = [1]
  (1..limit).each do |n|
    total = 0
    k = 1
    loop do
      g1 = k * (3 * k - 1) / 2
      break if g1 > n
      sign = k.odd? ? 1 : -1
      total += sign * p[n - g1]
      g2 = k * (3 * k + 1) / 2
      total += sign * p[n - g2] if g2 <= n
      k += 1
    end
    p << total
  end
  p
end

puts "partitions of 7:"
all7 = []
each_partition(7, 7, []) { |parts| all7 << parts }
all7.each_slice(5) do |row|
  puts "  " + row.map { |ps| ps.join("+") }.join("   ")
end
puts "  total #{all7.size}"

by_len = all7.group_by(&:size)
puts "  by number of parts: " + by_len.keys.sort.map { |k| "#{k}:#{by_len[k].size}" }.join(" ")

limit = 60
pn = count_table(limit, (1..limit).to_a)
pent = pentagonal_p(limit)
puts "p(n) for n = 0..20: #{pn.take(21).join(" ")}"
puts "p(#{limit}) = #{pn[limit]}, pentagonal recurrence agrees: #{pn == pent}"

distinct = distinct_count(limit)
odd = count_table(limit, (1..limit).select(&:odd?))
puts "distinct parts = odd parts up to #{limit}: #{distinct == odd}"
puts "q(n) for n = 0..20: #{distinct.take(21).join(" ")}"

coins = [1, 5, 10, 25, 50]
change = count_table(100, coins)
puts "ways to make change: 25c=#{change[25]} 50c=#{change[50]} 100c=#{change[100]}"

puts "Ramanujan congruences:"
[[5, 4], [7, 5], [11, 6]].each do |m, r|
  idx = (0..limit).select { |n| n % m == r }
  holds = idx.all? { |n| (pn[n] % m).zero? }
  puts "  p(#{m}k+#{r}) = 0 mod #{m} for #{idx.size} values: #{holds}"
end

growth = [10, 20, 30, 40, 50, 60].map do |n|
  approx = Math.exp(Math::PI * Math.sqrt(2.0 * n / 3)) / (4 * n * Math.sqrt(3))
  format("%d:%.3f", n, pn[n] / approx)
end
puts "p(n) / Hardy-Ramanujan estimate: #{growth.join(" ")}"
