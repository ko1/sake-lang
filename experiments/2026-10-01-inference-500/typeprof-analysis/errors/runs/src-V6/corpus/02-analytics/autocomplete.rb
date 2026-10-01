class Node
  attr_accessor :children, :count, :word

  def initialize(children, count, word)
    @children = children
    @count = count
    @word = word
  end

  def self.empty = Node.new({}, 0, nil)

  def insert(phrase)
    node = self
    phrase.each_char do |c|
      node = (node.children[c] ||= Node.empty)
    end
    node.word = phrase
    node.count += 1
  end

  def find(prefix)
    node = self
    prefix.each_char do |c|
      node = node.children[c]
      return nil unless node
    end
    node
  end

  def collect(out)
    out << [@word, @count] if @word
    @children.keys.sort.each { |c| @children[c].collect(out) }
    out
  end

  def size
    total = 1
    @children.each_value { |child| total += child.size }
    total
  end
end

def query_log
  "weather today|weather tomorrow|weather today|web design|webcam|weather radar|" +
  "wedding dress|weather today|web design|wedding venues|webcam|weather tomorrow|" +
  "west elm|western union|weather today|web hosting|weekend getaway|western union|" +
  "wedding dress|web design|weather radar|weight loss|weight loss|weight watchers"
end

def suggest(root, prefix, limit)
  node = root.find(prefix)
  return [] unless node
  all = node.collect([])
  all.sort_by { |w, c| [-c, w] }.take(limit)
end

def prefix_table(counts, max_len)
  table = {}
  counts.each do |phrase, _|
    len = [phrase.size, max_len].min
    1.upto(len) do |n|
      (table[phrase[0...n]] ||= []) << phrase
    end
  end
  table
end

phrases = query_log.split("|")
counts = phrases.tally
root = Node.empty
phrases.each { |ph| root.insert(ph) }
puts "queries: #{phrases.size}, distinct: #{counts.size}, trie nodes: #{root.size}"

["w", "wea", "web", "wed", "west", "weigh", "x"].each do |prefix|
  hits = suggest(root, prefix, 3)
  if hits.empty?
    puts format("%-6s -> (no suggestions)", prefix)
  else
    puts format("%-6s -> %s", prefix, hits.map { |w, c| "#{w} (#{c})" }.join(", "))
  end
end

table = prefix_table(counts, 4)
puts "prefix table: #{table.size} keys"
widest = table.max_by { |k, v| v.size * 10 - k.size }
if widest
  k, v = widest
  puts "widest prefix: '#{k}' covers #{v.size} phrases"
end
mismatch = 0
table.each do |prefix, list|
  node = root.find(prefix)
  from_trie = node ? node.collect([]).size : 0
  mismatch += 1 if from_trie != list.size
end
puts "trie and prefix table agree on #{table.size - mismatch} of #{table.size} prefixes"
