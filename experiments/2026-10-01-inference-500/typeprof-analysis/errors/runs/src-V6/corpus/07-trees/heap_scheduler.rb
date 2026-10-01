class Job
  include Comparable
  attr_reader :name, :priority, :seq, :arrival, :duration

  def initialize(name, priority, seq, arrival, duration)
    @name = name
    @priority = priority
    @seq = seq
    @arrival = arrival
    @duration = duration
  end

  def <=>(other)
    c = priority <=> other.priority
    c == 0 ? seq <=> other.seq : c
  end

  def to_s
    "#{name}(p#{priority})"
  end
end

class MinHeap
  attr_reader :items

  def initialize
    @items = []
  end

  def size = items.size
  def empty? = items.empty?
  def peek = items.first

  def push(x)
    items << x
    sift_up(items.size - 1)
    self
  end

  def pop
    return nil if items.empty?
    top = items[0]
    last = items.pop
    unless items.empty?
      items[0] = last
      sift_down(0)
    end
    top
  end

  private

  def sift_up(i)
    while i > 0
      parent = (i - 1) / 2
      break unless items[i] < items[parent]
      swap(i, parent)
      i = parent
    end
  end

  def sift_down(i)
    n = items.size
    loop do
      l = 2 * i + 1
      r = l + 1
      smallest = i
      smallest = l if l < n && items[l] < items[smallest]
      smallest = r if r < n && items[r] < items[smallest]
      break if smallest == i
      swap(i, smallest)
      i = smallest
    end
  end

  def swap(i, j)
    items[i], items[j] = items[j], items[i]
  end
end

def parse_jobs(text)
  jobs = []
  text.each_line do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    name, pri, arr, dur = line.split(",")
    jobs << Job.new(name.strip, pri.to_i, jobs.size, arr.to_i, dur.to_i)
  end
  jobs
end

data = <<~CSV
  # name, priority, arrival, duration
  backup, 5, 0, 4
  email, 2, 1, 2
  compile, 3, 1, 5
  # urgent ones
  alert, 1, 3, 1
  report, 4, 4, 3
  index, 3, 6, 2
  cleanup, 9, 6, 1
  deploy, 1, 9, 3
CSV

jobs = parse_jobs(data)
pending = jobs.sort_by(&:arrival)
heap = MinHeap.new
clock = 0
waits = {}
log = []
while pending.any? || !heap.empty?
  heap.push(pending.shift) while pending.any? && pending.first.arrival <= clock
  if heap.empty?
    clock = pending.first.arrival
    next
  end
  job = heap.pop
  waits[job.name] = clock - job.arrival
  log << format("t=%2d run %-12s for %d (queue %d)", clock, job.to_s, job.duration, heap.size)
  clock += job.duration
end
log.each { |l| puts l }
puts "finished at t=#{clock}"
worst = waits.max_by { |_n, w| w }
puts "longest wait: #{worst[0]} (#{worst[1]})"
avg = waits.values.sum / waits.size.to_f
puts format("average wait: %.2f", avg)

nums = MinHeap.new
[42, 7, 19, 3, 88, 7, 51, 0, 23].each { |x| nums.push(x) }
puts "min peek: #{nums.peek}"
sorted = []
while (x = nums.pop) && x
  sorted << x
end
puts "sorted: #{sorted.join(" ")}"
p nums.pop
