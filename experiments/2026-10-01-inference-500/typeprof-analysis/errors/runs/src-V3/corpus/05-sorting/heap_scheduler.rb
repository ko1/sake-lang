# A binary min-heap used three ways: a job scheduler ordered by (priority, arrival),
# heapsort of request latencies, and the k slowest requests with a bounded heap.

class Job
  include Comparable
  attr_reader :priority, :seq, :name

  def initialize(priority, seq, name)
    @priority = priority
    @seq = seq
    @name = name
  end

  def <=>(other)
    c = priority <=> other.priority
    c == 0 ? seq <=> other.seq : c
  end

  def to_s = "#{name}(p#{priority})"
end

class Heap
  attr_reader :items

  def initialize
    @items = []
  end

  def size = items.size
  def peek = items.first

  def push(x)
    a = items
    a << x
    i = a.size - 1
    while i > 0
      parent = (i - 1) / 2
      break if a[parent] <= a[i]
      a[parent], a[i] = a[i], a[parent]
      i = parent
    end
    self
  end

  def pop
    a = items
    return nil if a.empty?
    top = a[0]
    last = a.pop
    unless a.empty?
      a[0] = last
      Heap.sift_down(a, 0, a.size)
    end
    top
  end

  def self.sift_down(a, i, n)
    loop do
      l = 2 * i + 1
      r = l + 1
      m = i
      m = l if l < n && a[l] < a[m]
      m = r if r < n && a[r] < a[m]
      break if m == i
      a[m], a[i] = a[i], a[m]
      i = m
    end
  end
end

# Heapsort in descending order, in place, using a min-heap over the whole array.
def heapsort_desc(input)
  a = input.dup
  n = a.size
  (n / 2 - 1).downto(0) { |i| Heap.sift_down(a, i, n) }
  (n - 1).downto(1) do |last|
    a[0], a[last] = a[last], a[0]
    Heap.sift_down(a, 0, last)
  end
  a
end

def top_k(values, k)
  h = Heap.new
  values.each do |v|
    if h.size < k
      h.push(v)
    elsif v > h.peek
      h.pop
      h.push(v)
    end
  end
  result = []
  result.unshift(h.pop) while h.size > 0
  result
end

# --- scheduler ---
queue = Heap.new
arrivals = [[3, "backup"], [1, "page-oncall"], [2, "rebuild-index"], [1, "restart-web"],
            [5, "rotate-logs"], [2, "email-digest"], [3, "compact-db"]]
arrivals.each_with_index do |(prio, name), seq|
  queue.push(Job.new(prio, seq, name))
end
seq = arrivals.size
puts "next up: #{queue.peek}"
order = Array.new(4) { queue.pop }
puts "ran: #{order.join(", ")}"
queue.push(Job.new(0, seq, "hotfix"))
remaining = []
while (j = queue.pop)
  remaining << j.to_s
end
puts "then: #{remaining.join(", ")}"
p queue.pop

# --- latencies ---
latencies = []
v = 41
60.times do
  v = (v * 37 + 11) % 997
  latencies << v
end
desc = heapsort_desc(latencies)
puts "heapsort desc head: #{desc.take(8)}"
puts "matches builtin: #{desc == latencies.sort.reverse}"
puts "top 5 slowest: #{top_k(latencies, 5)}"
p95 = desc[desc.size / 20]
puts "p95 latency: #{p95}ms"
puts "words: #{top_k(%w[pear fig apple kiwi plum date], 3)}"
