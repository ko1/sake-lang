class QNode
  attr_accessor :value, :next

  def initialize(value, nxt)
    @value = value
    @next = nxt
  end
end

class Customer
  attr_accessor :id, :arrive, :work, :started

  def initialize(id, arrive, work, started)
    @id = id
    @arrive = arrive
    @work = work
    @started = started
  end
end

class Teller
  attr_accessor :name, :speed, :line, :busy_with, :busy_until, :served, :idle

  def initialize(name, speed, line, busy_with, busy_until, served, idle)
    @name = name
    @speed = speed
    @line = line
    @busy_with = busy_with
    @busy_until = busy_until
    @served = served
    @idle = idle
  end
end

module Walkable
  def size
    n = 0
    each { n += 1 }
    n
  end

  def to_list
    out = []
    each { |x| out << x }
    out
  end
end

class WaitQueue
  include Walkable

  def initialize
    @head = nil
    @tail = nil
  end

  def enqueue(v)
    node = QNode.new(v, nil)
    @tail ? @tail.next = node : @head = node
    @tail = node
  end

  def dequeue
    h = @head
    return nil unless h
    @head = h.next
    @tail = nil if !@head    
    h.value
  end

  def each
    n = @head
    while n
      yield n.value
      n = n.next
    end
  end
end

module Stats
  module_function

  def mean(xs) = xs.empty? ? 0.0 : xs.sum / xs.size.to_f

  def percentile(xs, pct)
    return 0 if xs.empty?
    sorted = xs.sort
    sorted[((sorted.size * pct + 99) / 100 - 1).clamp(0, sorted.size - 1)]
  end
end

def arrivals
  t = 0
  (1..24).map do |i|
    t += (i * 7) % 5 + 1
    Customer.new(i, t, (i * 13) % 9 + 2, nil)
  end
end

def simulate(teller_specs)
  tellers = teller_specs.map { |name, speed| Teller.new(name, speed, WaitQueue.new, nil, 0, 0, 0) }
  pending = arrivals
  waits = []
  max_line = 0
  clock = 0
  done = 0
  total = pending.size
  while done < total
    tellers.each do |t|
      if t.busy_with && t.busy_until <= clock
        t.busy_with = nil
        t.served += 1
        done += 1
      end
    end
    while (first = pending.first) && first.arrive == clock
      pending.shift
      best = tellers.min_by { |t| t.line.size * 100 + (t.busy_with ? 50 : 0) + t.speed }
      best.line.enqueue(first)
    end
    tellers.each do |t|
      if !t.busy_with    
        if (c = t.line.dequeue) && c
          c.started = clock
          waits << clock - c.arrive
          t.busy_with = c
          t.busy_until = clock + (c.work * t.speed + 1) / 2
        else
          t.idle += 1
        end
      end
      max_line = t.line.size.clamp(max_line, 1000)
    end
    clock += 1
  end
  { tellers: tellers, waits: waits, clock: clock, max_line: max_line }
end

[[["Ana", 2]], [["Ana", 2], ["Raj", 3]], [["Ana", 2], ["Raj", 3], ["Kim", 1]]].each do |specs|
  result = simulate(specs)
  result => { tellers:, waits:, clock:, max_line: }
  puts "#{tellers.size} teller(s): finished at t=#{clock}, longest line #{max_line}"
  puts format("  wait mean %.2f  p50 %d  p90 %d  max %d", Stats.mean(waits), Stats.percentile(waits, 50), Stats.percentile(waits, 90), waits.max)
  tellers.each do |t|
    left = t.line.to_list
    puts format("  %-4s speed %d served %2d idle %3d left %d", t.name, t.speed, t.served, t.idle, left.size)
  end
end
