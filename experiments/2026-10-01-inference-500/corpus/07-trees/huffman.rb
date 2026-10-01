class Leaf
  attr_reader :char, :weight, :order

  def initialize(char, weight, order)
    @char = char
    @weight = weight
    @order = order
  end
end

class Internal
  attr_reader :left, :right, :weight, :order

  def initialize(left, right, weight, order)
    @left = left
    @right = right
    @weight = weight
    @order = order
  end
end

def before?(a, b)
  a.weight < b.weight || (a.weight == b.weight && a.order < b.order)
end

# sorted insert keeps the queue ordered by (weight, order)
def enqueue(queue, node)
  i = queue.find_index { |q| before?(node, q) }
  if i.nil?
    queue << node
  else
    queue.insert(i, node)
  end
end

def build_tree(text)
  freq = text.chars.tally
  queue = []
  chars = freq.keys.sort
  chars.each_with_index { |c, i| enqueue(queue, Leaf.new(c, freq[c], i)) }
  next_order = chars.size
  while queue.size > 1
    a = queue.shift
    b = queue.shift
    enqueue(queue, Internal.new(a, b, a.weight + b.weight, next_order))
    next_order += 1
  end
  queue.first
end

def assign_codes(node, prefix, table)
  case node
  when Leaf
    table[node.char] = prefix == "" ? "0" : prefix
  when Internal
    assign_codes(node.left, prefix + "0", table)
    assign_codes(node.right, prefix + "1", table)
  end
  table
end

def encode(text, table) = text.chars.map { |c| table[c] }.join

def decode(bits, root)
  return root.char * bits.size if root.is_a?(Leaf)
  out = +""
  node = root
  bits.each_char do |b|
    node = b == "0" ? node.left : node.right
    if node.is_a?(Leaf)
      out << node.char
      node = root
    end
  end
  out
end

def depth(node)
  case node
  when Leaf then 0
  when Internal then 1 + [depth(node.left), depth(node.right)].max
  end
end

def show_char(c) = c == " " ? "' '" : c

def report(text)
  root = build_tree(text)
  table = assign_codes(root, "", {})
  bits = encode(text, table)
  back = decode(bits, root)
  raw = text.size * 8
  puts "text: #{text.inspect}"
  puts "  symbols #{table.size}, tree depth #{depth(root)}, total weight #{root.weight}"
  rows = table.sort_by { |c, code| [code.size, c] }
  rows.take(6).each { |c, code| puts format("    %-4s %-10s x%d", show_char(c), code, text.count(c)) }
  puts "    ... #{rows.size - 6} more" if rows.size > 6
  puts format("  bits %d vs %d raw (%.1f%%), avg %.3f bits/char", bits.size, raw, 100.0 * bits.size / raw, bits.size / text.size.to_f)
  puts "  first 40 bits: #{bits[0...40]}" if bits.size > 40
  puts "  round trip: #{back == text ? "ok" : "MISMATCH"}"
end

report("abracadabra")
report("aaaaaaa")
report("she sells sea shells by the sea shore")
report("the quick brown fox jumps over the lazy dog")
