# Emergency-room triage board: in-place three-way (Dutch national flag)
# partition of patients by urgency colour, a stable partition for comparison,
# and a three-way quicksort for arrival times with many duplicates.

class Patient
  attr_reader :name, :colour, :arrived

  def initialize(name, colour, arrived)
    @name = name
    @colour = colour
    @arrived = arrived
  end
end

def urgency(colour)
  case colour
  in :red then 0
  in :yellow then 1
  in :green then 2
  end
end

def swap(a, i, j)
  a[i], a[j] = a[j], a[i]
end

# Dutch national flag: one pass, in place, not stable.
def flag_partition!(a)
  low = 0
  mid = 0
  high = a.size - 1
  swaps = 0
  while mid <= high
    case urgency(a[mid].colour)
    in 0
      swap(a, low, mid)
      low += 1
      mid += 1
      swaps += 1
    in 1
      mid += 1
    in 2
      swap(a, mid, high)
      high -= 1
      swaps += 1
    end
  end
  [low, high + 1, swaps]
end

def stable_partition(a)
  groups = [[], [], []]
  a.each { |pt| groups[urgency(pt.colour)] << pt }
  groups.flatten
end

def quicksort3!(a, lo, hi)
  return a if lo >= hi
  pivot = a[lo + (hi - lo) / 2]
  lt = lo
  gt = hi
  i = lo
  while i <= gt
    if a[i] < pivot
      swap(a, lt, i)
      lt += 1
      i += 1
    elsif a[i] > pivot
      swap(a, i, gt)
      gt -= 1
    else
      i += 1
    end
  end
  quicksort3!(a, lo, lt - 1)
  quicksort3!(a, gt + 1, hi)
  a
end

def names(list) = list.map(&:name).join(" ")

waiting = [
  Patient.new("Ann", :green, 905), Patient.new("Ben", :red, 911), Patient.new("Cal", :yellow, 912),
  Patient.new("Dee", :green, 914), Patient.new("Eve", :yellow, 920), Patient.new("Fay", :red, 921),
  Patient.new("Gil", :green, 925), Patient.new("Hal", :yellow, 930), Patient.new("Ivy", :red, 931),
  Patient.new("Jon", :green, 940)
]

board = waiting.dup
red_end, green_start, swaps = flag_partition!(board)
puts "in place (#{swaps} swaps): #{names(board)}"
puts "  red: #{names(board[0...red_end])} | yellow: #{names(board[red_end...green_start])} | green: #{names(board[green_start..])}"

stable = stable_partition(waiting)
puts "stable:              #{names(stable)}"
fair = [:red, :yellow, :green].all? do |c|
  times = stable.select { |pt| pt.colour == c }.map(&:arrived)
  times == times.sort
end
puts "stable keeps arrival order within colour: #{fair}"
unfair = [:red, :yellow, :green].select do |c|
  times = board.select { |pt| pt.colour == c }.map(&:arrived)
  times != times.sort
end
puts "in-place order broken for: #{unfair}"

counts = waiting.map(&:colour).tally
puts "counts: #{counts}"
next_up = stable.first
puts "next: #{next_up.name} (#{next_up.colour}, since #{next_up.arrived})" if next_up

# minute-of-arrival buckets for the whole day: lots of duplicates
arrivals = []
m = 3
60.times do
  m = (m * 31 + 7) % 23
  arrivals << 900 + m % 8 * 15
end
sorted = quicksort3!(arrivals.dup, 0, arrivals.size - 1)
puts "3-way quicksort ok: #{sorted == arrivals.sort}"
sorted.chunk_while { |a, b| a == b }.each { |run| puts "  #{run[0]}: #{"*" * run.size}" }
