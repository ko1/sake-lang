def source
  "I do not like green eggs and ham. I do not like them Sam I am. " +
  "I would not like them here or there. I would not like them anywhere. " +
  "I do so like green eggs and ham. Thank you, thank you, Sam I am. " +
  "Would you like them in a house? Would you like them with a mouse? " +
  "I do not like them in a house. I do not like them with a mouse."
end

class Chain
  attr_accessor :order, :table, :starts

  def initialize(order, table, starts)
    @order = order
    @table = table
    @starts = starts
  end

  def self.build(words, order)
    chain = Chain.new(order, {}, [])
    words.each_with_index do |w, i|
      next if i + order >= words.size
      key = words.drop(i).take(order).join(" ")
      if i == 0 || words[i - 1].match?(/[.?]$/)
        chain.starts << key unless chain.starts.include?(key)
      end
      nxt = words[i + order]
      followers = chain.table[key] ||= Hash.new(0)
      followers[nxt] += 1
    end
    chain
  end

  def weighted(key)
    followers = @table[key]
    return [] unless followers
    followers.to_a.sort_by { |e__0| w, _ = e__0; w }
  end

  def pick(options, r)
    total = options.sum { |e__1| _, n = e__1; n }
    target = r % total
    options.each do |w, n|
      return w if target < n
      target -= n
    end
    nil
  end

  def generate(start, max_words, seed)
    out = start.split(" ")
    state = seed
    while out.size < max_words
      key = out.drop(out.size - @order).join(" ")
      options = weighted(key)
      break if options.empty?
      state = (state * 1103515245 + 12345) % 2147483648
      w = pick(options, state / 65536)
      break unless w
      out << w
      break if w.match?(/[.?]$/)
    end
    out.join(" ")
  end

  def branching
    stats = Hash.new(0)
    @table.each { |_, followers| stats[followers.size] += 1 }
    stats
  end
end

words = source.split(" ")
puts "words: #{words.size}"

[1, 2].each do |order|
  chain = Chain.build(words, order)
  table = chain.table
  puts "== order #{order}: #{table.size} states, #{chain.starts.size} starts =="
  stats = chain.branching
  stats.keys.sort.each { |b| puts "  #{stats[b]} states with #{b} follower(s)" }
  busiest = table.max_by { |e__2| _, f = e__2; f.size }
  if busiest
    key, _ = busiest
    desc = chain.weighted(key).map { |e__3| w, n = e__3; "#{w}:#{n}" }
    puts "  busiest '#{key}' -> #{desc.join(" ")}"
  end
  [7, 42, 2026].each do |seed|
    start = chain.starts[seed % chain.starts.size]
    puts "  [#{seed}] #{chain.generate(start, 14, seed)}"
  end
end

chain = Chain.build(words, 2)
lengths = {}
chain.starts.each do |st|
  lengths[st] = chain.generate(st, 30, 1).split(" ").size
end
lengths.each { |st, n| puts format("  %-12s %2d words", st, n) }
avg = lengths.values.sum * 1.0 / lengths.size
puts format("average sentence length: %.2f", avg)
