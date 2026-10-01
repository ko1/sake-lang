class Event
  include Comparable
  attr_reader :time, :order, :kind, :customer, :teller

  def initialize(time, order, kind, customer, teller)
    @time = time
    @order = order
    @kind = kind
    @customer = customer
    @teller = teller
  end

  def <=>(other)
    c = @time <=> other.time
    c == 0 ? @order <=> other.order : c
  end
end

class Customer
  attr_accessor :id, :arrived, :service, :started

  def initialize(id, arrived, service, started)
    @id = id
    @arrived = arrived
    @service = service
    @started = started
  end
end

class Teller
  attr_accessor :name, :state, :busy_time, :served

  def initialize(name, state, busy_time, served)
    @name = name
    @state = state
    @busy_time = busy_time
    @served = served
  end
end

class Heap
  attr_reader :items

  def initialize
    @items = []
  end

  def push(x)
    @items << x
    i = @items.size - 1
    while i > 0
      parent = (i - 1) / 2
      break if @items[parent] <= @items[i]
      @items[parent], @items[i] = @items[i], @items[parent]
      i = parent
    end
  end

  def pop
    top = @items.first
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
      @items[m], @items[i] = @items[i], @items[m]
      i = m
    end
    top
  end

  def empty? = @items.empty?
end

class Lcg
  def initialize(seed)
    @seed = seed
  end

  def next_int(n)
    @seed = (@seed * 1103515245 + 12345) % 2147483648
    @seed / 65536 % n
  end
end

def simulate(teller_count, customers)
  heap = Heap.new
  order = 0
  customers.each do |c|
    order += 1
    heap.push(Event.new(c.arrived, order, :arrive, c, nil))
  end
  tellers = (1..teller_count).map { |i| Teller.new("T#{i}", :idle, 0, 0) }
  line = []
  max_line = 0
  waits = []
  clock = 0
  until heap.empty?
    ev = heap.pop
    clock = ev.time
    case ev.kind
    in :arrive then line << ev.customer
    in :depart
      t = ev.teller
      t.state = :idle
      t.served += 1
    end
    max_line = line.size if line.size > max_line
    tellers.each do |t|
      next if t.state == :busy || line.empty?
      c = line.shift
      c.started = clock
      waits << clock - c.arrived
      t.state = :busy
      t.busy_time += c.service
      order += 1
      heap.push(Event.new(clock + c.service, order, :depart, c, t))
    end
  end
  { tellers: tellers, waits: waits, max_line: max_line, end_time: clock }
end

def make_customers(n, seed)
  g = Lcg.new(seed)
  t = 0
  (1..n).map do |i|
    t += g.next_int(6)
    Customer.new(i, t, 3 + g.next_int(8), nil)
  end
end

customers_spec = [[30, 7], [30, 2026]]
customers_spec.each do |n, seed|
  [1, 2, 3].each do |k|
    cs = make_customers(n, seed)
    r = simulate(k, cs)
    r => { tellers:, waits:, max_line:, end_time: }
    avg = waits.sum / waits.size.to_f
    late = waits.count { it > 10 }
    puts format("seed=%-4d tellers=%d end=%3d avg_wait=%6.2f max_wait=%3d max_line=%2d waited>10: %d",
      seed, k, end_time, avg, waits.max, max_line, late)
    tellers.each do |t|
      util = 100.0 * t.busy_time / end_time
      puts format("    %s served %2d busy %3d (%.1f%%)", t.name, t.served, t.busy_time, util)
    end
  end
end
