# Binary search on the answer: smallest truck capacity that ships parcels in D
# days, fairest split of book chapters among readers, and a loan's interest rate
# found by bisection on a Float.

class Plan
  attr_reader :capacity, :days, :loads

  def initialize(capacity, days, loads)
    @capacity = capacity
    @days = days
    @loads = loads
  end
end

def days_needed(weights, cap)
  days = 1
  load = 0
  weights.each do |w|
    if load + w > cap
      days += 1
      load = 0
    end
    load += w
  end
  days
end

def min_capacity(weights, days)
  raise ArgumentError, "days must be positive" if days <= 0
  lo = weights.max
  hi = weights.sum
  probes = 0
  while lo < hi
    mid = (lo + hi) / 2
    probes += 1
    if days_needed(weights, mid) <= days
      hi = mid
    else
      lo = mid + 1
    end
  end
  [lo, probes]
end

def loads_for(weights, cap)
  loads = [[]]
  weights.each do |w|
    if loads.last.sum + w > cap
      loads << [w]
    else
      loads.last << w
    end
  end
  loads
end

def split_chapters(pages, readers)
  lo = pages.max
  hi = pages.sum
  while lo < hi
    mid = (lo + hi) / 2
    if days_needed(pages, mid) <= readers
      hi = mid
    else
      lo = mid + 1
    end
  end
  lo
end

def payment(principal, monthly_rate, months)
  return principal / months if monthly_rate == 0.0
  f = (1.0 + monthly_rate)**months
  principal * monthly_rate * f / (f - 1.0)
end

def solve_rate(principal, pay, months)
  lo = 0.0
  hi = 1.0
  iterations = 0
  while hi - lo > 1.0e-10
    mid = (lo + hi) / 2.0
    iterations += 1
    if payment(principal, mid, months) < pay
      lo = mid
    else
      hi = mid
    end
  end
  [(lo + hi) / 2.0, iterations]
end

parcels = [12, 7, 30, 5, 18, 22, 9, 14, 3, 26, 11, 8, 16, 20, 4]
puts "parcels: #{parcels} (total #{parcels.sum})"
plans = []
[1, 3, 5, 8, 15].each do |d|
  cap, probes = min_capacity(parcels, d)
  plans << Plan.new(cap, d, loads_for(parcels, cap))
  puts format("%2d days -> capacity %3d (%d probes, uses %d days)", d, cap, probes, days_needed(parcels, cap))
end
tightest = plans.min_by do |pl|
  used = pl.loads.sum(&:sum)
  pl.capacity * pl.loads.size - used
end
puts "least slack: #{tightest.days} days, loads #{tightest.loads.map(&:sum)}"
begin
  min_capacity(parcels, 0)
rescue ArgumentError => e
  puts "error: #{e.message}"
end

chapters = { "Intro" => 18, "Setup" => 42, "Basics" => 35, "Types" => 60, "Blocks" => 27,
             "Errors" => 33, "Modules" => 51, "Testing" => 24, "Appendix" => 12 }
[2, 3, 4].each do |readers|
  limit = split_chapters(chapters.values, readers)
  groups = []
  current = []
  sum = 0
  chapters.each do |name, pg|
    if sum + pg > limit
      groups << current
      current = []
      sum = 0
    end
    current << name
    sum += pg
  end
  groups << current
  puts "#{readers} readers, max #{limit} pages each:"
  groups.each_with_index do |g, i|
    puts "  reader #{i + 1}: #{g.join(", ")} (#{g.sum { |nm| chapters[nm] }})"
  end
end

[[10000.0, 299.71, 36], [250000.0, 1342.05, 300], [1200.0, 100.0, 12]].each do |principal, pay, months|
  rate, iters = solve_rate(principal, pay, months)
  puts format("loan %.2f, %d x %.2f -> %.3f%% per year (%d iterations)", principal, months, pay, rate * 1200.0, iters)
end
