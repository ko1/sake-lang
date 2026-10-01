# A binary min-heap over anything that supports <, used for Integers, Strings and Tasks.
class Heap
  attr_reader :items

  def initialize(items)
    @items = items
  end

  def self.empty = Heap.new([])
  def size = @items.size
  def empty? = @items.empty?
  def peek = @items.first

  def push(x)
    @items.push(x)
    i = @items.size - 1
    while i > 0
      parent = (i - 1) / 2
      break unless @items[i] < @items[parent]
      swap(i, parent)
      i = parent
    end
    self
  end

  def pop
    return nil if @items.empty?
    top = @items[0]
    last = @items.pop
    unless @items.empty?
      @items[0] = last
      i = 0
      n = @items.size
      while true
        l = 2 * i + 1
        r = l + 1
        smallest = i
        smallest = l if l < n && @items[l] < @items[smallest]
        smallest = r if r < n && @items[r] < @items[smallest]
        break if smallest == i
        swap(i, smallest)
        i = smallest
      end
    end
    top
  end

  def swap(i, j)
    @items[i], @items[j] = @items[j], @items[i]
  end

  def drain
    out = []
    out << pop until empty?
    out
  end
end

class Task
  include Comparable
  attr_reader :id, :title, :priority, :deadline
  attr_accessor :done_at

  def initialize(id, title, priority, deadline, done_at)
    @id = id
    @title = title
    @priority = priority
    @deadline = deadline
    @done_at = done_at
  end

  def <=>(b)
    c = @priority <=> b.priority
    c = @deadline <=> b.deadline if c == 0
    c = @id <=> b.id if c == 0
    c
  end
  def to_s = format("#%d %-18s p%d due %2d", @id, @title, @priority, @deadline)
end

def k_smallest(xs, k)
  h = Heap.empty
  xs.each { |x| h.push(x) }
  (1..k).map { h.pop }
end

nums = [42, 7, 19, 3, 88, 3, 51, 26, 14, 70, 1, 65]
puts "nums sorted by heap: #{nums.reduce(Heap.empty) { |h, x| h.push(x) }.drain.join(" ")}"
puts "3 smallest: #{k_smallest(nums, 3).join(", ")}"
words = "pear fig apple kiwi banana cherry date".split(" ")
wh = Heap.empty
words.each { |w| wh.push(w) }
puts "first word: #{wh.peek}, size #{wh.size}"
puts "words: #{wh.drain.join(" ")}"
puts "pop from empty: #{!wh.pop     ? "nil" : "value"}"

tasks = [
  Task.new(1, "write report", 2, 9, nil),
  Task.new(2, "fix prod bug", 0, 3, nil),
  Task.new(3, "review PR", 1, 5, nil),
  Task.new(4, "lunch", 3, 12, nil),
  Task.new(5, "deploy hotfix", 0, 4, nil),
  Task.new(6, "update docs", 2, 9, nil),
  Task.new(7, "plan sprint", 1, 8, nil)
]
arrivals = { 0 => [1, 3, 4], 1 => [2], 3 => [5, 6], 6 => [7] }
durations = { 1 => 3, 2 => 2, 3 => 1, 4 => 1, 5 => 1, 6 => 2, 7 => 2 }

puts "== scheduling =="
queue = Heap.empty
clock = 0
finished = []
while finished.size < tasks.size
  (arrivals[clock] || []).each do |id|
    t = tasks.find { |x| x.id == id }
    queue.push(t) if t
  end
  current = queue.pop
  if !current    
    puts format("t=%2d idle", clock)
    clock += 1
    next
  end
  spent = durations[current.id]
  # newly arriving tasks during the run must wait; arrivals are processed tick by tick
  ((clock + 1)...(clock + spent)).each do |tick|
    (arrivals[tick] || []).each do |id|
      t = tasks.find { |x| x.id == id }
      queue.push(t) if t
    end
  end
  clock += spent
  current.done_at = clock
  late = clock > current.deadline ? " LATE" : ""
  puts format("t=%2d done %s%s", clock, current, late)
  finished << current
end

late_tasks = finished.select { |t| t.done_at > t.deadline }
puts "late: #{late_tasks.size} of #{finished.size}"
worst = late_tasks.max_by { |t| t.done_at - t.deadline }
puts "worst: #{worst.title} by #{worst.done_at - worst.deadline}" if worst
puts "sorted tasks:"
tasks.sort.each { |t| puts "  #{t}" }
puts "most urgent: #{tasks.min}"
puts "tie broken by id: #{Task.new(9, "a", 2, 9, nil) < Task.new(1, "b", 2, 9, nil)}"
