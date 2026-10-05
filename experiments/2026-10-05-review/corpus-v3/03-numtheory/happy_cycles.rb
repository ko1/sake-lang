# Iterating "sum of the k-th powers of the digits": happy numbers (k = 2),
# the cycles every start falls into for k = 2..5, and the fixed points.

def digit_power_sum(n, k)
  s = 0
  while n > 0
    n, d = n.divmod(10)
    s += d**k
  end
  s
end

# walk until a value repeats; return the cycle rotated to start at its smallest member
def cycle_from(n, k)
  seen = {}
  order = []
  until seen.key?(n)
    seen[n] = order.size
    order << n
    n = digit_power_sum(n, k)
  end
  cyc = order.drop(seen[n])
  cyc.rotate(cyc.index(cyc.min))
end

def happy?(n, memo)
  path = []
  while memo[n].nil? && n != 1
    if path.include?(n)
      path.each { |m| memo[m] = false }
      return false
    end
    path << n
    n = digit_power_sum(n, 2)
  end
  result = n == 1 || memo[n] == true
  path.each { |m| memo[m] = result }
  result
end

memo = {}
happy = (1..100).select { |n| happy?(n, memo) }
puts "happy numbers <= 100 (#{happy.size}): #{happy.join(" ")}"
count1000 = (1..1000).count { |n| happy?(n, memo) }
puts "happy numbers <= 1000: #{count1000}"

consecutive = (1..1000).select { |n| happy?(n, memo) && happy?(n + 1, memo) }
puts "consecutive happy pairs <= 1000: #{consecutive.join(" ")}"

trail = [7]
trail << digit_power_sum(trail.last, 2) while trail.last != 1
puts "trail of 7: #{trail.join(" -> ")}"

(2..5).each do |k|
  bound = k <= 3 ? 300 : 80
  cycles = Hash.new(0)
  (1..bound).each { |n| cycles[cycle_from(n, k)] += 1 }
  puts "k=#{k}: #{cycles.size} cycles for starts 1..#{bound}"
  cycles.sort_by { |members, c| [-c, members.first] }.each do |members, c|
    label = members.size == 1 ? "fixed point" : "cycle of #{members.size}"
    shown = members.size > 6 ? members.take(6).join(" ") + " ..." : members.join(" ")
    puts format("  %-14s %5d starts: %s", label, c, shown)
  end
end
