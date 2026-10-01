class Chain
  attr_accessor :key, :value, :next

  def initialize(key, value, nxt)
    @key = key
    @value = value
    @next = nxt
  end
end

class Table
  attr_reader :buckets, :size, :resizes
  attr_accessor :probes

  def self.hash_of(key)
    h = 5381
    key.each_byte { |b| h = (h * 33 + b) % 4294967296 }
    h
  end

  def initialize(n)
    @buckets = Array.new(n)
    @size = 0
    @resizes = 0
    @probes = 0
  end

  def [](key)
    node = @buckets[slot(key)]
    while node
      @probes += 1
      return node.value if node.key == key
      node = node.next
    end
    nil
  end

  def []=(key, value)
    i = slot(key)
    node = @buckets[i]
    while node
      if node.key == key
        node.value = value
        return value
      end
      node = node.next
    end
    @buckets[i] = Chain.new(key, value, @buckets[i])
    @size += 1
    grow if @size > @buckets.size * 2
    value
  end

  def delete(key)
    i = slot(key)
    prev = nil
    node = @buckets[i]
    while node
      if node.key == key
        prev ? prev.next = node.next : @buckets[i] = node.next
        @size -= 1
        return node.value
      end
      prev = node
      node = node.next
    end
    nil
  end

  def chain_lengths
    @buckets.map do |node|
      n = 0
      while node
        n += 1
        node = node.next
      end
      n
    end
  end

  def each_pair
    @buckets.each do |node|
      while node
        yield node.key, node.value
        node = node.next
      end
    end
  end

  private

  def slot(key) = Table.hash_of(key) % @buckets.size

  def grow
    old = @buckets
    fresh = Array.new(old.size * 2 + 1)
    old.each do |node|
      while node
        nxt = node.next
        j = Table.hash_of(node.key) % fresh.size
        node.next = fresh[j]
        fresh[j] = node
        node = nxt
      end
    end
    @buckets = fresh
    @resizes += 1
  end
end

text = "it was the best of times it was the worst of times it was the age of wisdom it was the age of foolishness it was the epoch of belief it was the epoch of incredulity it was the season of light it was the season of darkness"
counts = Table.new(3)
text.split(" ").each do |w|
  c = counts[w]
  counts[w] = c ? c + 1 : 1
end
lengths = counts.chain_lengths
puts "distinct=#{counts.size} buckets=#{lengths.size} resizes=#{counts.resizes}"
puts "longest chain=#{lengths.max} empty buckets=#{lengths.count(0)}"
pairs = []
counts.each_pair { |k, v| pairs << [k, v] }
top = pairs.sort_by { |k, v| [-v, k] }.take(5)
puts "top: #{top.map { |k, v| "#{k}=#{v}" }.join(", ")}"
counts.probes = 0
["was", "age", "wisdom", "zebra", ""].each do |w|
  puts "#{w.inspect} -> #{counts[w].inspect}"
end
puts "probes for 5 lookups: #{counts.probes}"
removed = %w[it of nope].map { |w| counts.delete(w) }
puts "deleted: #{removed.inspect} size now #{counts.size}"
total = 0
counts.each_pair { |_, v| total += v }
puts "remaining word total: #{total}"

ids = Table.new(2)
(1..40).each { |i| ids["user#{i}"] = i * i }
ids["user7"] = -1
puts "ids: size=#{ids.size} buckets=#{ids.buckets.size} resizes=#{ids.resizes} user7=#{ids["user7"]} user40=#{ids["user40"]} user41=#{ids["user41"].inspect}"
puts "hash(\"abc\")=#{Table.hash_of("abc")}"
