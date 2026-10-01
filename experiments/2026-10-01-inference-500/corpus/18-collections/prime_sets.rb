# Prime numbers with Ranges and Sets: a sieve, twin primes, gaps, Goldbach pairs, and residues.

def sieve(limit)
  composite = Set[]
  (2..Integer.sqrt(limit)).each do |i|
    next if composite.include?(i)
    ((i * i)..limit).step(i) { |j| composite.add(j) }
  end
  (2..limit).reject { |n| composite.include?(n) }
end

def goldbach(n, prime_set, primes)
  pairs = []
  primes.each do |p|
    break if p > n / 2
    pairs << [p, n - p] if prime_set.include?(n - p)
  end
  pairs
end

limit = 400
primes = sieve(limit)
prime_set = primes.to_set
puts "primes up to #{limit}: #{primes.size}"
puts "first ten: #{primes.take(10).join(" ")}"
puts "largest: #{primes.last}"

twins = primes.select { |p| prime_set.include?(p + 2) }
puts "twin pairs: #{twins.size}"
puts "  #{twins.take(6).map { |p| "(#{p},#{p + 2})" }.join(" ")}"

gaps = Hash.new(0)
widest = nil
primes.each_cons(2) do |a, b|
  gaps[b - a] += 1
  widest = [a, b] if widest.nil? || b - a > widest[1] - widest[0]
end
puts "gap histogram:"
gaps.keys.sort.each { |g| puts format("  %2d %s", g, "*" * ((gaps[g] + 1) / 2)) }
puts "widest gap: #{widest[0]}..#{widest[1]}"

puts "goldbach:"
(40..60).step(4) do |n|
  pairs = goldbach(n, prime_set, primes)
  puts "  #{n} = #{pairs.map { |a, b| "#{a}+#{b}" }.join(" = ")}"
end

puts "residues mod 6 (p > 3):"
res = primes.select { |p| p > 3 }.map { |p| p % 6 }.tally
res.keys.sort.each { |r| puts "  #{r}: #{res[r]}" }

decades = primes.group_by { |p| p / 100 }
puts "per hundred:"
decades.each do |d, ps|
  span = (d * 100)...(d * 100 + 100)
  puts format("  %3d-%3d: %2d  min=%d max=%d", span.begin, span.end - 1, ps.size, ps.min, ps.max)
end

odds = (3..99).select(&:odd?).to_set
odd_primes = prime_set.select { |p| p < 100 && p > 2 }.to_set
puts "odd composites below 100: #{(odds - odd_primes).size}"
puts "odd primes subset of odds? #{odd_primes.subset?(odds)}"
squares = (1..20).map { |k| k * k }.to_set
near_square = primes.select { |p| squares.include?(p - 1) }
puts "primes one above a square: #{near_square.join(" ")}"
first_big = primes.find { |p| p > 350 }
none = primes.find { |p| p > limit }
puts "first above 350: #{first_big}, above limit: #{none.nil? ? "none" : none}"
puts "digit sums: #{primes.select { |p| prime_set.include?(p.digits.sum) && p > 100 }.take(8).join(" ")}"
