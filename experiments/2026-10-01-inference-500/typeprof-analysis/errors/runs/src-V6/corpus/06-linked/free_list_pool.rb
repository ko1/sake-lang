class PoolExhausted < StandardError
  attr_reader :capacity

  def initialize(message, capacity)
    super(message)
    @capacity = capacity
  end
end

class BadHandle < StandardError
  attr_reader :handle

  def initialize(message, handle)
    super(message)
    @handle = handle
  end
end

class Pool
  attr_reader :in_use, :peak

  def initialize(capacity)
    @names = Array.new(capacity, "")
    @links = Array.new(capacity) { |i| i + 1 < capacity ? i + 1 : -1 }
    @prevs = Array.new(capacity, -1)
    @live = Array.new(capacity, false)
    @free_head = 0
    @used_head = -1
    @in_use = 0
    @peak = 0
  end

  def capacity = @names.size

  def acquire(name)
    slot = @free_head
    raise PoolExhausted.new("pool exhausted acquiring #{name}", capacity) if slot == -1
    @free_head = @links[slot]
    @names[slot] = name
    @live[slot] = true
    @links[slot] = @used_head
    @prevs[slot] = -1
    @prevs[@used_head] = slot if @used_head != -1
    @used_head = slot
    @in_use += 1
    @peak = @in_use if @in_use > @peak
    slot
  end

  def release(slot)
    raise BadHandle.new("bad handle #{slot}", slot) if slot < 0 || slot >= capacity || !@live[slot]
    nxt = @links[slot]
    prv = @prevs[slot]
    if prv == -1
      @used_head = nxt
    else
      @links[prv] = nxt
    end
    @prevs[nxt] = prv if nxt != -1
    @live[slot] = false
    @names[slot] = ""
    @links[slot] = @free_head
    @free_head = slot
    @in_use -= 1
    self
  end

  def each_used
    i = @used_head
    while i != -1
      yield i, @names[i]
      i = @links[i]
    end
  end

  def free_slots
    out = []
    i = @free_head
    while i != -1
      out << i
      i = @links[i]
    end
    out
  end

  def describe
    used = []
    each_used { |i, n| used << "#{i}:#{n}" }
    "used[#{used.join(" ")}] free#{free_slots.inspect}"
  end
end

pool = Pool.new(5)
handles = {}
script = "+db1 +db2 +cache +db3 -db2 +web -cache +db4 +db5 +db6 -db1 -db1 +db7 -web -nobody".split(" ")
script.each do |cmd|
  name = cmd[1..]
  begin
    if cmd.start_with?("+")
      slot = pool.acquire(name)
      handles[name] = slot
      puts format("%-7s -> slot %d   %s", cmd, slot, pool.describe)
    else
      slot = handles.fetch(name, -1)
      pool.release(slot)
      handles.delete(name)
      puts format("%-7s <- slot %d   %s", cmd, slot, pool.describe)
    end
  rescue PoolExhausted => e
    puts format("%-7s !! %s (capacity %d)", cmd, e.message, e.capacity)
  rescue BadHandle => e
    puts format("%-7s !! %s", cmd, e.message)
  end
end
puts "in use #{pool.in_use}, peak #{pool.peak}, capacity #{pool.capacity}"
by_prefix = Hash.new(0)
pool.each_used { |_, n| by_prefix[n.delete("0123456789")] += 1 }
p by_prefix
handles.keys.sort.each { |k| pool.release(handles[k]) }
puts "after releasing all: #{pool.describe}"
