require_relative "ref/lru_cache"

c = LRUCache.new(3)
c[:a] = 1
c[:b] = 2
c[:c] = 3
p c.keys
p c[:a]
p c.keys
c[:d] = 4
p c.keys
p c.key?(:b)
p c[:b]
p c.to_a
c[:c] = 30
p c.to_a
p c.count
p c.stats

# getset computes and stores; fetch computes without storing
p c.getset(:e) { |k| k.length * 100 }
p c.getset(:e) { |k| -1 }
p c.keys
p c.fetch(:zz) { |k| "no #{k}" }
p c.key?(:zz)
p c.fetch(:c)
begin
  c.fetch(:zz)
rescue KeyError => e
  puts e.message
end
p c.stats
p c.hit_rate

# shrink, delete, clear
p(c.max_size = 2)
p c.max_size
p c.to_a
p c.delete(:c)
p c.delete(:nope)
c.each { |k, v| puts "#{k} => #{v}" }
c.clear
p c.empty?
p c.stats

# memoizing a recursive function
def fib(cache, n)
  return n if n < 2
  cache.getset(n) { |k| fib(cache, k - 1) + fib(cache, k - 2) }
end
memo = LRUCache.new(100)
p fib(memo, 80)
p memo.stats
p memo.count

# a capacity of 1
one = LRUCache.new(1)
one["x"] = 1
one["y"] = 2
p one.to_a
p one["x"]
p one.stats
p LRUCache.new(5).hit_rate

# errors
[0, -2].each do |n|
  begin
    LRUCache.new(n)
  rescue ArgumentError => e
    puts e.message
  end
end
begin
  LRUCache.new([1, "big"].fetch(1))
rescue NoMatchingPatternError
  puts "max_size must be an Integer"
end
begin
  one.max_size = 0
rescue ArgumentError => e
  puts e.message
end
