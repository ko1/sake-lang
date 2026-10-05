class Lane
  attr_reader :name, :kind, :secs_per_item, :overhead, :queue, :busy_until, :served
  attr_accessor :open

  def initialize(name, kind, secs_per_item, overhead)
    @name = name
    @kind = kind
    @secs_per_item = secs_per_item
    @overhead = overhead
    @queue = []
    @busy_until = 0
    @served = 0
    @open = true
  end

  def accepts?(items) = @open && (@kind != :express || items <= 10)

  def service_time(items) = @overhead + items * @secs_per_item

  def expected_wait(now)
    pending = @queue.sum { |c| service_time(c[:items]) }
    rest = @busy_until > now ? @busy_until - now : 0
    rest + pending
  end

  def tick(now, waits)
    return if @busy_until > now
    c = @queue.shift
    return if c.nil?
    @busy_until = now + service_time(c[:items])
    @served += 1
    waits[c[:id]] = [@name, now - c[:arrive], @busy_until]
  end

  def idle?(now) = @busy_until <= now && @queue.empty?
end

SPECS = [[0, 23], [15, 4], [20, 8], [32, 41], [40, 2], [41, 12], [55, 6], [60, 30],
  [62, 3], [70, 9], [71, 15], [85, 1], [90, 27], [92, 5], [100, 7], [104, 11],
  [110, 2], [118, 19], [125, 4], [131, 8], [140, 35], [142, 3], [150, 6], [151, 10]].freeze

def build_customers
  SPECS.each_with_index.map { |(at, items), i| { id: i + 1, arrive: at, items: items } }
end

def simulate(lanes, close_lane, close_at, balk_limit)
  arrivals = build_customers
  waits = {}
  balked = []
  now = 0
  last_arrival = arrivals.map { |c| c[:arrive] }.max
  while now < 2000
    lane = close_lane && lanes.find { |l| l.name == close_lane }
    lane.open = false if lane && now == close_at
    arrivals.each do |c|
      next unless c[:arrive] == now
      options = lanes.select { |l| l.accepts?(c[:items]) }
      best = options.min_by { |l| l.expected_wait(now) }
      if best.nil? || best.expected_wait(now) > balk_limit
        balked << c[:id]
      else
        best.queue << c
      end
    end
    lanes.each { |l| l.tick(now, waits) }
    break if now > last_arrival && lanes.all? { |l| l.idle?(now) }
    now += 1
  end
  { waits: waits, balked: balked, finished: now }
end

def make_lanes
  [
    Lane.new("L1", :regular, 3, 30),
    Lane.new("L2", :regular, 4, 25),
    Lane.new("EX", :express, 3, 20),
    Lane.new("SC", :self, 6, 15)
  ]
end

def report(title, close_lane, balk_limit)
  lanes = make_lanes
  result = simulate(lanes, close_lane, 90, balk_limit)
  result => { waits:, balked:, finished: }
  puts "== #{title}"
  waits.each do |id, (lane, wait, done)|
    puts format("  #%-2d %-2s waited %3ds done at %4d", id, lane, wait, done) if wait >= 150
  end
  per_lane = waits.values.group_by(&:first)
  lanes.each do |l|
    rows = per_lane[l.name] || []
    avg = rows.empty? ? 0.0 : rows.sum { |_lane, wait, _done| wait } / rows.size.to_f
    puts format("  %-2s %-7s served %2d avg wait %6.1fs", l.name, l.kind, l.served, avg)
  end
  all = waits.values.map { |_lane, wait, _done| wait }
  puts format("  served %d, balked %d %s, all done at %ds, worst wait %ds",
    waits.size, balked.size, balked.inspect, finished, all.max || 0)
  all.sum
end

base = report("all lanes open", nil, 400)
closed = report("L2 closes at 90s", "L2", 400)
strict = report("impatient shoppers", nil, 120)
puts format("total wait: %d / %d / %d", base, closed, strict)
