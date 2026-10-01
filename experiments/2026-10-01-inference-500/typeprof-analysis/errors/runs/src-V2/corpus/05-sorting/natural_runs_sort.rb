# A simplified Timsort for daily price series: find natural runs (reversing
# strictly descending ones), extend short runs with binary insertion sort,
# and merge runs from a stack while keeping the run lengths balanced.

class Run
  attr_reader :start, :length

  def initialize(start, length)
    @start = start
    @length = length
  end
end

class Stats
  attr_accessor :runs, :reversed, :merges, :compares

  def initialize(runs, reversed, merges, compares)
    @runs = runs
    @reversed = reversed
    @merges = merges
    @compares = compares
  end
end

def bump(stats, field)
  case field
  in :runs then stats.runs += 1
  in :reversed then stats.reversed += 1
  in :merges then stats.merges += 1
  in :compares then stats.compares += 1
  end
end

def reverse_range(a, lo, hi)
  while lo < hi
    a[lo], a[hi] = a[hi], a[lo]
    lo += 1
    hi -= 1
  end
end

def count_run(a, lo, stats)
  n = a.size
  return 1 if lo == n - 1
  hi = lo + 1
  bump(stats, :compares)
  if a[hi] < a[lo]
    hi += 1 while hi < n - 1 && a[hi + 1] < a[hi]
    reverse_range(a, lo, hi)
    bump(stats, :reversed)
  else
    hi += 1 while hi < n - 1 && a[hi + 1] >= a[hi]
  end
  hi - lo + 1
end

def binary_insertion(a, lo, hi, start)
  (start..hi).each do |i|
    x = a[i]
    left = lo
    right = i
    while left < right
      mid = (left + right) / 2
      if x < a[mid]
        right = mid
      else
        left = mid + 1
      end
    end
    j = i
    while j > left
      a[j] = a[j - 1]
      j -= 1
    end
    a[left] = x
  end
end

def merge_at(a, stack, i, stats)
  r1 = stack[i]
  r2 = stack[i + 1]
  lo = r1.start
  mid = lo + r1.length
  hi = mid + r2.length
  left = a[lo...mid]
  k = lo
  p = 0
  q = mid
  while p < left.size && q < hi
    bump(stats, :compares)
    if a[q] < left[p]
      a[k] = a[q]
      q += 1
    else
      a[k] = left[p]
      p += 1
    end
    k += 1
  end
  while p < left.size
    a[k] = left[p]
    p += 1
    k += 1
  end
  stack[i] = Run.new(lo, hi - lo)
  stack.delete_at(i + 1)
  bump(stats, :merges)
end

def collapse(a, stack, stats)
  while stack.size > 1
    n = stack.size - 1
    if n >= 2 && stack[n - 2].length <= stack[n - 1].length + stack[n].length
      i = stack[n - 2].length < stack[n].length ? n - 2 : n - 1
      merge_at(a, stack, i, stats)
    elsif stack[n - 1].length <= stack[n].length
      merge_at(a, stack, n - 1, stats)
    else
      break
    end
  end
end

def timsort(input, min_run)
  a = input.dup
  stats = Stats.new(0, 0, 0, 0)
  stack = []
  lo = 0
  n = a.size
  while lo < n
    len = count_run(a, lo, stats)
    if len < min_run
      forced = min_run.clamp(1, n - lo)
      binary_insertion(a, lo, lo + forced - 1, lo + len)
      len = forced
    end
    bump(stats, :runs)
    stack << Run.new(lo, len)
    collapse(a, stack, stats)
    lo += len
  end
  merge_at(a, stack, stack.size - 2, stats) while stack.size > 1
  [a, stats]
end

def describe(label, data, min_run)
  sorted, st = timsort(data, min_run)
  ok = sorted == data.sort
  puts format("%-10s n=%3d runs=%2d reversed=%d merges=%2d compares=%4d ok=%s", label, data.size,
              st.runs, st.reversed, st.merges, st.compares, ok)
  sorted
end

prices = [101.5, 102.0, 102.4, 103.1, 99.8, 98.2, 97.0, 96.5, 100.1, 100.1, 104.6, 105.0,
          103.3, 103.3, 101.0, 106.2, 107.8, 108.0, 95.4, 96.0]
sorted = describe("prices", prices, 4)
puts "  lowest #{sorted.first}, highest #{sorted.last}, median #{sorted[sorted.size / 2]}"

ascending = (1..64).to_a
describe("ascending", ascending, 8)
describe("descending", ascending.reverse, 8)
saw = (0...96).map { |i| i % 24 < 12 ? i % 24 : 24 - i % 24 }
describe("sawtooth", saw, 8)
noise = []
x = 5
120.times do
  x = (x * 75 + 74) % 65537
  noise << x % 500
end
describe("noise", noise, 16)
describe("noise/4", noise, 4)
describe("one", [42], 4)
