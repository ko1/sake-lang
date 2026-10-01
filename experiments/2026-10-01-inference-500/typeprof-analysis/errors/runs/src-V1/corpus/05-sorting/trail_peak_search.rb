# Hiking trail profiles: find the summit of a unimodal elevation profile by
# binary search on the slope, look up an altitude on either side of the summit,
# and pick the best ticket price by ternary search on a Float function.

class Trail
  attr_reader :name, :elevations

  def initialize(name, elevations)
    @name = name
    @elevations = elevations
  end
end

class NotUnimodal < StandardError
  attr_reader :trail

  def initialize(message, trail)
    super(message)
    @trail = trail
  end
end

def summit(a)
  lo = 0
  hi = a.size - 1
  steps = 0
  while lo < hi
    mid = (lo + hi) / 2
    steps += 1
    if a[mid] < a[mid + 1]
      lo = mid + 1
    else
      hi = mid
    end
  end
  [lo, steps]
end

def check_unimodal(trail)
  a = trail.elevations
  peak, _ = summit(a)
  up_ok = (1..peak).all? { |i| a[i - 1] < a[i] }
  down_ok = ((peak + 1)...a.size).all? { |i| a[i - 1] > a[i] }
  raise NotUnimodal.new("elevations go up and down more than once", trail.name) unless up_ok && down_ok
  peak
end

# Binary search on one monotone side of the profile.
def find_altitude(a, lo, hi, target, ascending)
  while lo <= hi
    mid = (lo + hi) / 2
    v = a[mid]
    return mid if v == target
    if (v < target) == ascending
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  nil
end

def markers(a, target)
  peak, _ = summit(a)
  up = find_altitude(a, 0, peak, target, true)
  down = find_altitude(a, peak + 1, a.size - 1, target, false)
  [up, down].compact
end

def revenue(price)
  visitors = 1200.0 * Math.exp(-price / 18.0)
  price * visitors - 2.0 * visitors
end

def ternary_max(lo, hi, eps)
  rounds = 0
  while hi - lo > eps
    m1 = lo + (hi - lo) / 3.0
    m2 = hi - (hi - lo) / 3.0
    if yield(m1) < yield(m2)
      lo = m1
    else
      hi = m2
    end
    rounds += 1
  end
  [(lo + hi) / 2.0, rounds]
end

trails = [
  Trail.new("Ridge Loop", [120, 180, 260, 410, 530, 610, 655, 640, 580, 470, 300, 150]),
  Trail.new("Lake Path", [300, 310, 325, 330, 320, 290]),
  Trail.new("Steep Climb", [50, 400, 900, 1350, 1700, 1960, 2105]),
  Trail.new("Old Quarry", [200, 260, 240, 300, 280, 210])
]

trails.each do |t|
  peak = check_unimodal(t)
  a = t.elevations
  _, steps = summit(a)
  gain = a[peak] - a.first
  loss = a[peak] - a.last
  puts format("%-11s summit %4dm at km %d (%d steps), +%d/-%d", t.name, a[peak], peak, steps, gain, loss)
  [300, 610, 9999].each do |alt|
    found = markers(a, alt)
    puts "  #{alt}m marker at km #{found.join(" and ")}" unless found.empty?
  end
rescue NotUnimodal => e
  puts "#{e.trail}: #{e.message}"
end

best = trails.max_by { |t| t.elevations.max }
puts "highest point overall: #{best.name}"

price, rounds = ternary_max(2.0, 80.0, 0.001) { |p| revenue(p) }
puts format("best ticket price %.2f after %d rounds, revenue %.1f", price, rounds, revenue(price))
[10.0, 20.0, 30.0].each { |pr| puts format("  at %.2f: %.1f", pr, revenue(pr)) }
