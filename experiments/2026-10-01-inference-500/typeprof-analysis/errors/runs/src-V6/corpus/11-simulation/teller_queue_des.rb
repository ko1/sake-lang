class Event
  include Comparable
  attr_reader :time, :seq, :kind, :customer, :teller

  def initialize(time, seq, kind, customer, teller)
    @time = time
    @seq = seq
    @kind = kind
    @customer = customer
    @teller = teller
  end

  def <=>(other)
    c = @time <=> other.time
    c == 0 ? @seq <=> other.seq : c
  end
end

class Customer
  attr_reader :id, :arrived, :service
  attr_accessor :started, :teller

  def initialize(id, arrived, service)
    @id = id
    @arrived = arrived
    @service = service
    @started = nil
    @teller = nil
  end
end

class Rng
  def initialize(state)
    @state = state
  end

  def next_int(n)
    @state = (@state * 1103515245 + 12345) % 2147483648
    (@state / 65536) % n
  end
end

class Heap
  def initialize
    @items = []
  end

  def push(x)
    @items.push(x)
    i = @items.size - 1
    while i > 0
      parent = (i - 1) / 2
      break if @items[parent] <= @items[i]
      swap(i, parent)
      i = parent
    end
  end

  def pop
    return nil if @items.empty?
    top = @items[0]
    last = @items.pop
    return top if @items.empty?
    @items[0] = last
    i = 0
    n = @items.size
    loop do
      l = 2 * i + 1
      r = l + 1
      m = i
      m = l if l < n && @items[l] < @items[m]
      m = r if r < n && @items[r] < @items[m]
      break if m == i
      swap(i, m)
      i = m
    end
    top
  end

  def swap(i, j)
    @items[i], @items[j] = @items[j], @items[i]
  end

  def size = @items.size
end

def simulate(tellers, rng, n_customers, close_time)
  events = Heap.new
  seq = 0
  free = (1..tellers).to_a
  line = []
  served = []
  busy_time = Hash.new(0)
  max_line = 0
  turned = 0
  t = 0
  n_customers.times do |i|
    t += 1 + rng.next_int(6)
    c = Customer.new(i + 1, t, 3 + rng.next_int(10))
    seq += 1
    events.push(Event.new(t, seq, :arrive, c, 0))
  end
  now = 0
  while (ev = events.pop) && ev
    now = ev.time
    c = ev.customer
    case ev.kind
    when :arrive
      if now > close_time
        c.teller = 0
        turned += 1
      else
        line << c
      end
    when :depart
      free << ev.teller
      served << c
    end
    while !free.empty? && !line.empty?
      teller = free.min
      free.delete(teller)
      nxt = line.shift
      nxt.started = now
      nxt.teller = teller
      busy_time[teller] += nxt.service
      seq += 1
      events.push(Event.new(now + nxt.service, seq, :depart, nxt, teller))
    end
    max_line = line.size if line.size > max_line
  end
  { served: served, end_time: now, busy: busy_time, max_line: max_line, turned: turned }
end

def report(tellers, seed)
  result = simulate(tellers, Rng.new(seed), 40, 125)
  result => { served:, end_time:, busy:, max_line:, turned: }
  waits = served.map { |c| c.started - c.arrived }
  avg = waits.sum / waits.size.to_f
  longest = served.max_by { |c| c.started - c.arrived }
  puts "tellers=#{tellers} seed=#{seed}: served #{served.size}, turned away #{turned}, closed at #{end_time}, max line #{max_line}"
  puts format("  avg wait %.2f, max wait %d (customer %d)", avg, waits.max, longest.id)
  util = busy.keys.sort.map do |k|
    format("T%d %.0f%%", k, 100.0 * busy[k] / end_time)
  end
  puts "  utilization: #{util.join(", ")}"
  buckets = waits.group_by { |w| w < 5 ? "0-4" : (w < 15 ? "5-14" : "15+") }
  ["0-4", "5-14", "15+"].each do |b|
    n = buckets.fetch(b, []).size
    puts "  #{b.ljust(5)}#{"#" * n} #{n}"
  end
  avg
end

averages = {}
[1, 2, 3].each do |tellers|
  averages[tellers] = report(tellers, 2024)
end
k, v = averages.min_by { |_k, avg| avg }
puts format("best: %d tellers (avg wait %.2f)", k, v)
