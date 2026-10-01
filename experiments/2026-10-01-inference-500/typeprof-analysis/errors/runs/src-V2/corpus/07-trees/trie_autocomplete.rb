class TrieNode
  attr_accessor :children, :terminal, :freq, :pass

  def initialize
    @children = {}
    @terminal = false
    @freq = 0
    @pass = 0
  end
end

class Trie
  attr_reader :root, :words

  def initialize
    @root = TrieNode.new
    @words = 0
  end

  def insert(word, freq)
    existing = find_node(word)
    if existing && existing.terminal
      existing.freq += freq
      return existing
    end
    node = root
    node.pass += 1
    word.each_char do |c|
      child = (node.children[c] ||= TrieNode.new)
      child.pass += 1
      node = child
    end
    @words += 1
    node.terminal = true
    node.freq = freq
    node
  end

  def find_node(prefix)
    node = root
    prefix.each_char do |c|
      node = node.children[c]
      return nil if node.nil?
    end
    node
  end

  def include?(word)
    node = find_node(word)
    !node.nil? && node.terminal
  end

  def count_prefix(prefix)
    node = find_node(prefix)
    node ? node.pass : 0
  end

  def complete(prefix, limit)
    node = find_node(prefix)
    return [] if node.nil?
    found = collect(node, prefix, [])
    found.sort_by { |w, f| [-f, w] }.take(limit).map(&:first)
  end

  def longest_common_prefix
    node = root
    prefix = +""
    while node.children.size == 1 && !node.terminal
      c, child = node.children.first
      prefix << c
      node = child
    end
    prefix
  end

  def delete(word)
    return false unless include?(word)
    node = root
    node.pass -= 1
    word.each_char do |c|
      child = node.children[c]
      child.pass -= 1
      if child.pass == 0
        node.children.delete(c)
        @words -= 1
        return true
      end
      node = child
    end
    node.terminal = false
    node.freq = 0
    @words -= 1
    true
  end

  private

  def collect(node, prefix, out)
    out << [prefix, node.freq] if node.terminal
    node.children.keys.sort.each { |c| collect(node.children[c], prefix + c, out) }
    out
  end
end

corpus = "the quick brown fox jumps over the lazy dog then the fox thinks the dog " \
         "is there to theorize about quick quiet quilts and the quiz"
trie = Trie.new
corpus.split(" ").each { |w| trie.insert(w, 1) }
trie.insert("theory", 3)
puts "distinct words: #{trie.words}"
["th", "qui", "do", "x", ""].each do |pre|
  puts "#{pre.inspect}: #{trie.count_prefix(pre)} words, top #{trie.complete(pre, 3).join("/")}"
end
puts "contains 'the': #{trie.include?("the")}, 'thé': #{trie.include?("thé")}, 'theor': #{trie.include?("theor")}"
%w[the theorize quilts zebra].each do |w|
  ok = trie.delete(w)
  puts "delete #{w}: #{ok} -> th* = #{trie.complete("th", 10).join(",")}"
end
puts "words now: #{trie.words}, q-prefix: #{trie.count_prefix("q")}"

tags = Trie.new
%w[interview internet interval internal interstate].each { |w| tags.insert(w, 1) }
puts "common prefix: #{tags.longest_common_prefix}"
tags.insert("inter", 1)
puts "common prefix after 'inter': #{tags.longest_common_prefix}"
tags.insert("intake", 1)
puts "common prefix after 'intake': #{tags.longest_common_prefix}"
