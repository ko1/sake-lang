class SkipNode
  attr_accessor :key, :value, :forward

  def initialize(key, value, forward)
    @key = key
    @value = value
    @forward = forward
  end
end

class SkipList
  attr_reader :level, :size
  attr_accessor :steps

  def initialize(max_level)
    @head = SkipNode.new(nil, nil, Array.new(max_level))
    @max_level = max_level
    @level = 1
    @seed = 12345
    @size = 0
    @steps = 0
  end

  def find(key)
    cand = predecessors(key)[0].forward[0]
    cand && cand.key == key ? cand.value : nil
  end

  def insert(key, value)
    update = predecessors(key)
    cand = update[0].forward[0]
    if cand && cand.key == key
      cand.value = value
      return false
    end
    lvl = random_level
    @level = lvl if lvl > @level
    node = SkipNode.new(key, value, Array.new(lvl))
    lvl.times do |i|
      node.forward[i] = update[i].forward[i]
      update[i].forward[i] = node
    end
    @size += 1
    true
  end

  def delete(key)
    update = predecessors(key)
    target = update[0].forward[0]
    return nil unless target && target.key == key
    target.forward.each_with_index { |nxt, i| update[i].forward[i] = nxt }
    @level -= 1 while @level > 1 && !@head.forward[@level - 1]    
    @size -= 1
    target.value
  end

  def range(lo, hi)
    out = []
    x = predecessors(lo)[0].forward[0]
    while x && x.key <= hi
      out << [x.key, x.value]
      x = x.forward[0]
    end
    out
  end

  def level_counts
    (0...@level).map do |i|
      n = 0
      x = @head.forward[i]
      while x
        n += 1
        x = x.forward[i]
      end
      n
    end
  end

  private

  def random_level
    lvl = 1
    loop do
      @seed = (@seed * 1103515245 + 12345) % 2147483648
      break unless (@seed >> 16) % 4 == 0 && lvl < @max_level
      lvl += 1
    end
    lvl
  end

  def predecessors(key)
    update = Array.new(@max_level, @head)
    x = @head
    (@level - 1).downto(0) do |i|
      while (nxt = x.forward[i]) && nxt.key < key
        x = nxt
        @steps += 1
      end
      update[i] = x
    end
    update
  end
end

prices = SkipList.new(6)
(1..60).each do |i|
  key = (i * 37) % 101
  prices.insert(key, "item#{key}")
end
puts "size=#{prices.size} level=#{prices.level} per-level=#{prices.level_counts.inspect}"
prices.steps = 0
[37, 50, 74, 100, 0].each do |k|
  puts "find #{k}: #{prices.find(k).inspect}"
end
puts "steps for 5 lookups: #{prices.steps}"
puts "update 37: #{prices.insert(37, "special")} -> #{prices.find(37)}"
puts "range 30..45: #{prices.range(30, 45).map { |k, v| "#{k}=#{v}" }.join(" ")}"
removed = [37, 38, 39, 40].map { |k| prices.delete(k) }
puts "delete 37..40: #{removed.inspect}"
puts "range 30..45: #{prices.range(30, 45).map { |k, _| k.to_s }.join(",")}"
puts "size=#{prices.size} per-level=#{prices.level_counts.inspect}"

names = SkipList.new(4)
"pear fig apple kiwi banana cherry date grape".split(" ").each { |w| names.insert(w, w.size) }
puts names.range("b", "g").map { |k, v| "#{k}(#{v})" }.join(" ")
"fig kiwi zzz".split(" ").each { |w| names.delete(w) }
puts names.range("a", "z").map { |k, _| k }.join(" ")
