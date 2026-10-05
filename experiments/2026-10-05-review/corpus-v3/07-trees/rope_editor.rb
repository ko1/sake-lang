class RLeaf
  attr_reader :text

  def initialize(text)
    @text = text
  end
end

class RNode
  attr_reader :left, :right, :weight, :length

  def initialize(left, right, weight, length)
    @left = left
    @right = right
    @weight = weight
    @length = length
  end
end

CHUNK = 8

def len(r)
  case r
  when RLeaf then r.text.size
  when RNode then r.length
  when nil then 0
  end
end

def concat(a, b)
  return b if a.nil? || len(a) == 0
  return a if b.nil? || len(b) == 0
  RNode.new(a, b, len(a), len(a) + len(b))
end

def from_string(s)
  return RLeaf.new(s) if s.size <= CHUNK
  mid = s.size / 2
  concat(from_string(s[0...mid]), from_string(s[mid..]))
end

def char_at(r, i)
  raise IndexError, "index #{i} outside rope of length #{len(r)}" if i < 0 || i >= len(r)
  while r.is_a?(RNode)
    if i < r.weight
      r = r.left
    else
      i -= r.weight
      r = r.right
    end
  end
  r.text[i]
end

# returns [first i characters, the rest]
def split(r, i)
  case r
  when nil then [nil, nil]
  when RLeaf
    t = r.text
    return [r, nil] if i >= t.size
    return [nil, r] if i <= 0
    [RLeaf.new(t[0...i]), RLeaf.new(t[i..])]
  when RNode
    if i < r.weight
      a, b = split(r.left, i)
      [a, concat(b, r.right)]
    else
      a, b = split(r.right, i - r.weight)
      [concat(r.left, a), b]
    end
  end
end

def insert(r, i, s)
  a, b = split(r, i)
  concat(concat(a, from_string(s)), b)
end

def delete(r, from, count)
  a, rest = split(r, from)
  _gone, b = split(rest, count)
  concat(a, b)
end

def each_leaf(r, &block)
  case r
  when RLeaf then yield r.text
  when RNode
    each_leaf(r.left, &block)
    each_leaf(r.right, &block)
  end
end

def to_text(r)
  parts = []
  each_leaf(r) { |t| parts << t }
  parts.join
end

def depth(r) = r.is_a?(RNode) ? 1 + [depth(r.left), depth(r.right)].max : 0

def leaf_count(r)
  n = 0
  each_leaf(r) { |_t| n += 1 }
  n
end

def rebalance(r) = from_string(to_text(r))

def index_of(r, needle) = to_text(r).index(needle)

doc = from_string("The quick brown fox jumps over the lazy dog.")
puts "start: #{to_text(doc).inspect} len #{len(doc)} depth #{depth(doc)} leaves #{leaf_count(doc)}"

edits = [
  [:insert, 10, "and very red "], [:delete, 4, 6], [:insert, 0, ">> "], [:replace, "lazy", "sleepy"],
  [:insert, 999, "!"], [:delete, 3, 1000], [:replace, "cat", "tiger"]
]
edits.each do |kind, a, b|
  case kind
  when :insert
    raise IndexError, "insert position #{a} beyond end #{len(doc)}" if a > len(doc)
    doc = insert(doc, a, b)
  when :delete
    doc = delete(doc, a, b)
  else
    at = index_of(doc, a)
    raise IndexError, "#{a.inspect} not found" if at.nil?
    doc = insert(delete(doc, at, a.size), at, b)
  end
  puts "#{kind} #{a.inspect} #{b.inspect}: #{to_text(doc).inspect} (depth #{depth(doc)})"
rescue IndexError => e
  puts "#{kind} failed: #{e.message}"
end

doc = from_string(">> The very red fox jumps over the sleepy dog.")
6.times { |i| doc = insert(doc, len(doc) - 1, " #{i}") }
puts "after appends: depth #{depth(doc)}, leaves #{leaf_count(doc)}, len #{len(doc)}"
doc = rebalance(doc)
puts "rebalanced:    depth #{depth(doc)}, leaves #{leaf_count(doc)}, len #{len(doc)}"
puts "text: #{to_text(doc)}"
puts "chars: #{[0, 3, 7, len(doc) - 1].map { |i| "#{i}=#{char_at(doc, i)}" }.join(" ")}"
begin
  char_at(doc, len(doc))
rescue IndexError => e
  puts "error: #{e.message}"
end
