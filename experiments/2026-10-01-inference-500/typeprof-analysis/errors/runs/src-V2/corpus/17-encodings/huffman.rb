# Huffman compression: build the tree from symbol frequencies, derive the code table,
# encode a text to a bit string, pack it into bytes, and decode it back.

class HNode
  include Comparable
  attr_reader :weight, :order, :symbol, :left, :right

  def initialize(weight, order, symbol, left, right)
    @weight = weight
    @order = order
    @symbol = symbol
    @left = left
    @right = right
  end

  def <=>(other)
    c = weight <=> other.weight
    c == 0 ? order <=> other.order : c
  end

  def leaf? = !symbol.nil?
end

def insert_sorted(queue, node)
  i = queue.find_index { |q| node < q }
  if i
    queue.insert(i, node)
  else
    queue.push(node)
  end
end

def build_tree(text)
  freq = text.chars.tally
  queue = []
  order = 0
  freq.to_a.sort_by { |sym, n| [n, sym] }.each do |sym, n|
    insert_sorted(queue, HNode.new(n, order, sym, nil, nil))
    order += 1
  end
  while queue.size > 1
    a = queue.shift
    b = queue.shift
    insert_sorted(queue, HNode.new(a.weight + b.weight, order, nil, a, b))
    order += 1
  end
  queue.first
end

def assign_codes(node, prefix, table)
  return table if node.nil?
  if node.leaf?
    table[node.symbol] = prefix.empty? ? "0" : prefix
  else
    assign_codes(node.left, prefix + "0", table)
    assign_codes(node.right, prefix + "1", table)
  end
  table
end

def decode_bits(root, bits)
  out = +""
  node = root
  bits.each_char do |b|
    node = b == "0" ? node.left : node.right
    if node.leaf?
      out << node.symbol
      node = root
    end
  end
  out
end

def pack(bits)
  bits.chars.each_slice(8).map do |chunk|
    chunk.join.ljust(8, "0").chars.reduce(0) { |v, c| v * 2 + (c == "1" ? 1 : 0) }
  end
end

def show_char(c) = c == " " ? "' '" : c

texts = ["abracadabra", "mississippi river", "this is an example of a huffman tree"]
texts.each do |text|
  root = build_tree(text)
  next if root.nil?
  codes = assign_codes(root, "", {})
  bits = text.chars.map { |c| codes[c] }.join
  packed = pack(bits)
  back = decode_bits(root, bits)
  puts "text: #{text}"
  codes.to_a.sort_by { |sym, code| [code.size, sym] }.each do |sym, code|
    puts format("  %-4s %-8s", show_char(sym), code)
  end
  avg = bits.size.fdiv(text.size)
  puts format("  bits=%d bytes=%d (raw %d) avg=%.3f bits/char", bits.size, packed.size, text.size, avg)
  puts "  packed: #{packed.map { |b| format("%02X", b) }.join}"
  puts "  roundtrip: #{back == text}"
end

single = build_tree("aaaa")
puts "single-symbol code: #{assign_codes(single, "", {})["a"]}" if single
