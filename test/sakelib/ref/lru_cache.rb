# Reference implementation for test/sakelib/lru_cache.rb: a least-recently-used cache in plain Ruby,
# after the lru_redux gem (LruRedux::Cache), plus hit/miss/eviction counters. A Hash keeps the order:
# the first key is the least recently used one.

class LRUCache
  attr_reader :max_size

  def initialize(max_size)
    max_size => Integer
    raise ArgumentError, "max_size must be positive" unless max_size > 0
    @max_size = max_size
    @data = {}
    @hits = @misses = @evictions = 0
  end

  def max_size=(n)
    n => Integer
    raise ArgumentError, "max_size must be positive" unless n > 0
    @max_size = n
    evict
    n
  end

  def [](key)
    if @data.key?(key)
      @hits += 1
      @data[key] = @data.delete(key)
    else
      @misses += 1
      nil
    end
  end

  def []=(key, value)
    @data.delete(key)
    @data[key] = value
    evict
    value
  end

  # The cached value, or the block's value, stored.
  def getset(key)
    if @data.key?(key)
      @hits += 1
      @data[key] = @data.delete(key)
    else
      @misses += 1
      self[key] = yield(key)
    end
  end

  # The cached value, or the block's value (not stored); KeyError without a block.
  def fetch(key)
    if @data.key?(key)
      @hits += 1
      @data[key] = @data.delete(key)
    else
      @misses += 1
      raise KeyError, "key not found: #{key.inspect}" unless block_given?
      yield(key)
    end
  end

  def key?(key) = @data.key?(key)
  def delete(key) = @data.delete(key)
  def count = @data.size
  def empty? = @data.empty?

  # [key, value] pairs, the most recently used first.
  def to_a = @data.to_a.reverse
  def keys = to_a.map(&:first)

  def each
    to_a.each { |k, v| yield k, v }
    self
  end

  def clear
    @data.clear
    self
  end

  def stats = { hits: @hits, misses: @misses, evictions: @evictions, size: @data.size }
  def hit_rate = @hits + @misses == 0 ? 0.0 : @hits.fdiv(@hits + @misses)

  private

  def evict
    while @data.size > @max_size
      @data.shift
      @evictions += 1
    end
  end
end
