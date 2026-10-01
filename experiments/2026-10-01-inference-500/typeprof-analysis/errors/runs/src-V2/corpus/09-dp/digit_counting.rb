# counts of numbers in 0..limit with a digit property, by a memoized digit DP
def digits_of(n) = n.to_s.chars.map(&:to_i)

# numbers in 0..limit whose digit sum equals target
def count_digit_sum(limit, target)
  sum_walk(digits_of(limit), 0, target, true, {})
end

def sum_walk(ds, pos, remaining, tight, memo)
  return 0 if remaining < 0
  return remaining == 0 ? 1 : 0 if pos == ds.size
  key = [pos, remaining, tight]
  return memo[key] if memo.key?(key)
  top = tight ? ds[pos] : 9
  memo[key] = (0..top).sum do |d|
    sum_walk(ds, pos + 1, remaining - d, tight && d == top, memo)
  end
end

# numbers in 1..limit with no two equal adjacent digits
def count_no_repeat(limit)
  repeat_walk(digits_of(limit), 0, -1, true, false, {})
end

# prev = -1 while still in leading zeros
def repeat_walk(ds, pos, prev, tight, started, memo)
  return started ? 1 : 0 if pos == ds.size
  key = [pos, prev, tight, started]
  return memo[key] if memo.key?(key)
  top = tight ? ds[pos] : 9
  total = 0
  (0..top).each do |d|
    now_started = started || d != 0
    next if now_started && started && d == prev
    total += repeat_walk(ds, pos + 1, now_started ? d : -1, tight && d == top, now_started, memo)
  end
  memo[key] = total
end

# numbers in 0..limit divisible by k whose digits are all even
def count_even_digits_div(limit, k)
  even_walk(digits_of(limit), 0, 0, k, true, {})
end

def even_walk(ds, pos, rem, k, tight, memo)
  return rem == 0 ? 1 : 0 if pos == ds.size
  key = [pos, rem, tight]
  return memo[key] if memo.key?(key)
  top = tight ? ds[pos] : 9
  memo[key] = [0, 2, 4, 6, 8].select { |d| d <= top }.sum do |d|
    even_walk(ds, pos + 1, (rem * 10 + d) % k, k, tight && d == top, memo)
  end
end

def brute(limit)
  (0..limit).count { |n| yield(n) }
end

def digit_sum(n) = digits_of(n).sum

def no_repeat?(n)
  digits_of(n).each_cons(2).none? { |a, b| a == b }
end

puts "digit sum checks against brute force:"
[[99, 9], [1000, 10], [1234, 20], [543, 7]].each do |limit, s|
  fast = count_digit_sum(limit, s)
  slow = brute(limit) { |n| digit_sum(n) == s }
  puts format("  0..%-5d sum %2d: %4d %s", limit, s, fast, fast == slow ? "ok" : "MISMATCH #{slow}")
end

puts "no equal neighbours:"
[100, 321, 1000].each do |limit|
  fast = count_no_repeat(limit)
  slow = brute(limit) { |n| n > 0 && no_repeat?(n) }
  puts format("  1..%-5d %5d %s", limit, fast, fast == slow ? "ok" : "MISMATCH #{slow}")
end

puts "large limits:"
[123_456_789, 10**15].each do |limit|
  puts "  #{limit}"
  puts "    digit sum 30:            #{count_digit_sum(limit, 30)}"
  puts "    no equal neighbours:     #{count_no_repeat(limit)}"
  puts "    even digits, div by 7:   #{count_even_digits_div(limit, 7)}"
end
