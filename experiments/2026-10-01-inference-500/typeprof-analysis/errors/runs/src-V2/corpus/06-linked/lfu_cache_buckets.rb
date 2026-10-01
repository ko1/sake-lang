class Item
  attr_accessor :key, :value, :bucket, :prev, :next

  def initialize(key, value, bucket, prev, nxt)
    @key = key
    @value = value
    @bucket = bucket
    @prev = prev
    @next = nxt
  end
end

class Bucket
  attr_accessor :freq, :head, :tail, :prev, :next

  def initialize(freq, head, tail, prev, nxt)
    @freq = freq
    @head = head
    @tail = tail
    @prev = prev
    @next = nxt
  end

  def empty? = @head.nil?

  def append(item)
    item.bucket = self
    item.prev = @tail
    item.next = nil
    if @tail
      @tail.next = item
    else
      @head = item
    end
    @tail = item
  end

  def remove(item)
    item.prev ? item.prev.next = item.next : @head = item.next
    item.next ? item.next.prev = item.prev : @tail = item.prev
  end

  def keys
    out = []
    it = @head
    while it
      out << it.key
      it = it.next
    end
    out
  end
end

class LFU
  attr_reader :log

  def initialize(capacity)
    @capacity = capacity
    @items = {}
    @lowest = nil
    @log = []
  end

  def get(key)
    item = @items[key]
    return nil unless item
    touch(item)
    item.value
  end

  def put(key, value)
    if (item = @items[key])
      item.value = value
      touch(item)
      return
    end
    if @items.size >= @capacity
      low = @lowest
      victim = low.head
      low.remove(victim)
      @items.delete(victim.key)
      @log << "evict #{victim.key} (freq #{low.freq})"
      drop_bucket(low) if low.empty?
    end
    first = @lowest
    if first.nil? || first.freq != 1
      first = Bucket.new(1, nil, nil, nil, first)
      first.next.prev = first if first.next
      @lowest = first
    end
    item = Item.new(key, value, first, nil, nil)
    first.append(item)
    @items[key] = item
  end

  def layout
    parts = []
    b = @lowest
    while b
      parts << "#{b.freq}:#{b.keys.join(",")}"
      b = b.next
    end
    parts.join(" | ")
  end

  private

  def drop_bucket(b)
    b.prev ? b.prev.next = b.next : @lowest = b.next
    b.next.prev = b.prev if b.next
  end

  def touch(item)
    b = item.bucket
    target = b.next
    if target.nil? || target.freq != b.freq + 1
      target = Bucket.new(b.freq + 1, nil, nil, b, target)
      target.next.prev = target if target.next
      b.next = target
    end
    b.remove(item)
    target.append(item)
    drop_bucket(b) if b.empty?
  end
end

cache = LFU.new(3)
script = [
  [:put, "x", 10], [:put, "y", 20], [:get, "x", 0], [:put, "z", 30], [:get, "x", 0],
  [:get, "y", 0], [:put, "w", 40], [:get, "z", 0], [:get, "w", 0], [:put, "v", 50],
  [:get, "w", 0], [:get, "w", 0], [:put, "y", 21], [:get, "y", 0], [:put, "u", 60], [:get, "x", 0]
]
script.each do |op, key, value|
  if op == :put
    cache.put(key, value)
    puts format("put %s=%-3d  %s", key, value, cache.layout)
  else
    got = cache.get(key)
    puts format("get %s -> %-4s %s", key, got ? got.to_s : "miss", cache.layout)
  end
end
puts "log:"
cache.log.each { |line| puts "  " + line }

words = "to be or not to be that is the question to ask or not".split(" ")
wc = LFU.new(4)
misses = 0
words.each do |w|
  if (n = wc.get(w))
    wc.put(w, n + 1)
  else
    misses += 1
    wc.put(w, 1)
  end
end
puts "word cache: #{wc.layout} misses=#{misses}"
puts "evictions: #{wc.log.size}"
