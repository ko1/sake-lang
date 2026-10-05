# Digit-based curiosities: digit sums, digital roots, Armstrong and Harshad
# numbers, palindromes, reverse-and-add (Lychrel candidates), Kaprekar's routine.

def digit_sum(n) = n.digits.sum

def digital_root(n)
  n = digit_sum(n) while n >= 10
  n
end

def reverse_num(n)
  n.digits.reduce(0) { |acc, d| acc * 10 + d }
end

def palindrome?(n) = n == reverse_num(n)

def armstrong?(n)
  ds = n.digits
  k = ds.size
  ds.sum { |d| d**k } == n
end

def harshad?(n) = (n % digit_sum(n)).zero?

# returns [steps, palindrome] or nil when no palindrome within the limit
def reverse_and_add(n, limit)
  limit.times do |i|
    n += reverse_num(n)
    return [i + 1, n] if palindrome?(n)
  end
  nil
end

def kaprekar_steps(n)
  seen = []
  while n != 6174 && n != 0
    ds = n.digits
    ds << 0 while ds.size < 4
    asc = ds.sort
    big = asc.reverse.reduce(0) { |acc, d| acc * 10 + d }
    small = asc.reduce(0) { |acc, d| acc * 10 + d }
    seen << "#{big}-#{small.to_s.rjust(4, "0")}"
    n = big - small
  end
  [n, seen]
end

puts "digital roots:"
[16, 942, 132189, 493193, 999999999].each do |n|
  puts "  #{n.to_s.rjust(10)}  sum=#{digit_sum(n)}  root=#{digital_root(n)}"
end

arm = (1..9999).select { |n| armstrong?(n) }
puts "Armstrong numbers < 10000: #{arm.join(" ")}"

harshad = (1..60).select { |n| harshad?(n) }
puts "Harshad numbers <= 60: #{harshad.size}"
puts "  #{harshad.join(",")}"

run = 0
best_run = 0
best_start = 0
(1..2000).each do |n|
  if harshad?(n)
    run += 1
    if run > best_run
      best_run = run
      best_start = n - run + 1
    end
  else
    run = 0
  end
end
puts "longest run of consecutive Harshad numbers <= 2000: #{best_run} from #{best_start}"

pal_squares = (1..300).select { |n| palindrome?(n * n) && n > 3 }
puts "n with palindromic n^2: #{pal_squares.map { |n| "#{n}^2=#{n * n}" }.join(" ")}"

puts "reverse-and-add:"
[56, 87, 89, 196, 295].each do |n|
  if (r = reverse_and_add(n, 30))
    steps, pal = r
    puts "  #{n}: #{steps} steps -> #{pal}"
  else
    puts "  #{n}: no palindrome in 30 steps (Lychrel candidate)"
  end
end

puts "Kaprekar routine:"
[3524, 2111, 9831, 1000, 7777].each do |n|
  final, trail = kaprekar_steps(n)
  label = final.zero? ? "degenerate" : "#{trail.size} steps"
  puts "  #{n}: #{label}"
  puts "    #{trail.join(" / ")}" if trail.size <= 3
end

hist = Hash.new(0)
(1000..1999).each do |n|
  final, trail = kaprekar_steps(n)
  hist[trail.size] += 1 if final == 6174
end
hist.keys.sort.each { |k| puts "  #{k} steps: #{hist[k]}" }
