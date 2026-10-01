class Entry
  attr_accessor :key, :value, :prev, :next

  def initialize(key, value, prev, nxt)
    @key = key
    @value = value
    @prev = prev
    @next = nxt
  end
end

class LRUCache
  attr_reader :capacity, :hits, :misses, :evicted

  def initialize(capacity)
    @capacity = capacity
    @index = {}
    @newest = nil
    @oldest = nil
    @hits = 0
    @misses = 0
    @evicted = []
  end

  def get(key)
    e = @index[key]
    if !e    
      @misses += 1
      return nil
    end
    @hits += 1
    unlink(e)
    link_front(e)
    e.value
  end

  def put(key, value)
    if (e = @index[key])
      e.value = value
      unlink(e)
      link_front(e)
      return self
    end
    if @index.size >= @capacity && (victim = @oldest)
      unlink(victim)
      @index.delete(victim.key)
      @evicted << victim.key
    end
    fresh = Entry.new(key, value, nil, nil)
    @index[key] = fresh
    link_front(fresh)
    self
  end

  def keys
    out = []
    e = @newest
    while e
      out << e.key
      e = e.next
    end
    out
  end

  def hit_rate
    total = @hits + @misses
    total == 0 ? 0.0 : @hits * 100.0 / total
  end

  private

  def unlink(e)
    if e.prev
      e.prev.next = e.next
    else
      @newest = e.next
    end
    if e.next
      e.next.prev = e.prev
    else
      @oldest = e.prev
    end
    e.prev = nil
    e.next = nil
  end

  def link_front(e)
    e.next = @newest
    e.prev = nil
    if @newest
      @newest.prev = e
    else
      @oldest = e
    end
    @newest = e
  end
end

def slow_square(n, calls)
  calls[0] += 1
  total = 0
  n.times { total += n }
  total
end

def cached_square(cache, n, calls)
  v = cache.get(n)
  return v if v
  v = slow_square(n, calls)
  cache.put(n, v)
  v
end

cache = LRUCache.new(3)
cache.put("a", 1)
cache.put("b", 2)
cache.put("c", 3)
puts "order: #{cache.keys.inspect}"
puts "get a: #{cache.get("a")}"
cache.put("d", 4)
puts "after put d: #{cache.keys.inspect}"
puts "get b: #{cache.get("b").inspect}"
cache.put("c", 30)
puts "after update c: #{cache.keys.inspect} c=#{cache.get("c")}"
cache.put("e", 5)
cache.put("f", 6)
puts "final: #{cache.keys.inspect} evicted=#{cache.evicted.inspect}"
puts format("hits=%d misses=%d rate=%.1f%%", cache.hits, cache.misses, cache.hit_rate)

[2, 4, 8].each do |size|
  memo = LRUCache.new(size)
  calls = [0]
  requests = [5, 7, 5, 9, 11, 5, 7, 13, 9, 5, 7, 11, 5, 15, 7, 5]
  results = requests.map { |n| cached_square(memo, n, calls) }
  puts format("size %d: calls=%2d hit rate %5.1f%% sum=%d evicted=%s", size, calls[0], memo.hit_rate, results.sum, memo.evicted.join(","))
end

pages = LRUCache.new(2)
[[:home, "<h1>Home</h1>"], [:about, "<p>About</p>"], [:home, "<h1>Home v2</h1>"], [:blog, "<ul></ul>"]].each do |route, html|
  pages.put(route, html)
end
%i[home about blog].each do |route|
  html = pages.get(route)
  puts "#{route}: #{html || "(evicted)"}"
end
