# Reference implementation for test/sakelib/trie.rb: a prefix tree (trie) of String keys with
# values, in plain Ruby. Keys are visited in lexicographic order of their characters.

class Trie
  Node = Struct.new(:children, :value, :terminal)

  attr_reader :size

  def initialize
    @root = Node.new({}, nil, false)
    @size = 0
  end

  def empty? = @size == 0

  # Adds or replaces word; returns value.
  def insert(word, value = true)
    word => String
    node = word.each_char.reduce(@root) { |n, c| n.children[c] ||= Node.new({}, nil, false) }
    @size += 1 unless node.terminal
    node.terminal = true
    node.value = value
  end
  alias []= insert

  def [](word)
    node = find(word)
    node && node.terminal ? node.value : nil
  end

  def include?(word) = !!find(word)&.terminal
  def starts_with?(prefix) = !find(prefix).nil?

  # The keys starting with prefix, in order.
  def prefix_search(prefix)
    node = find(prefix)
    out = []
    collect(node, prefix, out) if node
    out.map(&:first)
  end

  # The longest key that is a prefix of s, or nil.
  def longest_prefix(s)
    node = @root
    best = node.terminal ? "" : nil
    s.each_char.with_index do |c, i|
      node = node.children[c]
      break unless node
      best = s[0, i + 1] if node.terminal
    end
    best
  end

  # Removes word; returns its value, or nil when it was not there. Empty branches are pruned.
  def delete(word)
    path = [@root]
    word.each_char do |c|
      nxt = path.last.children[c]
      return nil unless nxt
      path << nxt
    end
    node = path.last
    return nil unless node.terminal
    value = node.value
    node.terminal = false
    node.value = nil
    @size -= 1
    word.chars.reverse.each_with_index do |c, k|
      child = path[path.size - 1 - k]
      break if child.terminal || !child.children.empty?
      path[path.size - 2 - k].children.delete(c)
    end
    value
  end

  def each
    out = []
    collect(@root, "", out)
    out.each { |k, v| yield k, v }
    self
  end

  def keys = to_a.map(&:first)
  def to_a
    out = []
    collect(@root, "", out)
    out
  end

  def node_count = count_nodes(@root)

  private

  def find(word)
    word.each_char.reduce(@root) do |n, c|
      n = n.children[c]
      return nil unless n
      n
    end
  end

  def collect(node, prefix, out)
    out << [prefix, node.value] if node.terminal
    node.children.keys.sort.each { |c| collect(node.children[c], prefix + c, out) }
  end

  def count_nodes(node) = 1 + node.children.values.sum { |n| count_nodes(n) }
end
