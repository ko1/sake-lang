class MLeaf
  attr_reader :hash, :index, :data

  def initialize(hash, index, data)
    @hash = hash
    @index = index
    @data = data
  end

  def lo = index
  def hi = index
end

class MNode
  attr_reader :hash, :left, :right, :lo, :hi

  def initialize(hash, left, right, lo, hi)
    @hash = hash
    @left = left
    @right = right
    @lo = lo
    @hi = hi
  end
end

def fnv1a(s)
  s.bytes.reduce(2166136261) { |h, b| ((h ^ b) * 16777619) & 0xffffffff }
end

def hex(h) = format("%08x", h)

def combine(a, b) = fnv1a("#{hex(a)}|#{hex(b)}")

def build(blocks)
  raise ArgumentError, "no blocks" if blocks.empty?
  level = blocks.each_with_index.map { |data, i| MLeaf.new(fnv1a(data), i, data) }
  while level.size > 1
    level = level.each_slice(2).map do |a, b|
      b.nil? ? a : MNode.new(combine(a.hash, b.hash), a, b, a.lo, b.hi)
    end
  end
  level[0]
end

def height(n) = n.is_a?(MNode) ? 1 + [height(n.left), height(n.right)].max : 0

# sibling hashes from the leaf up to the root
def proof(root, index)
  raise IndexError, "block #{index} out of range" if index < root.lo || index > root.hi
  steps = []
  node = root
  while node.is_a?(MNode)
    if index <= node.left.hi
      steps << [:right, node.right.hash]
      node = node.left
    else
      steps << [:left, node.left.hash]
      node = node.right
    end
  end
  steps.reverse
end

def verify(data, steps, root_hash)
  h = steps.reduce(fnv1a(data)) { |acc, (side, sib)| side == :right ? combine(acc, sib) : combine(sib, acc) }
  h == root_hash
end

def diff(a, b, out, stats)
  stats[:compared] += 1
  return out if a.hash == b.hash
  if a.is_a?(MNode) && b.is_a?(MNode)
    diff(a.left, b.left, out, stats)
    diff(a.right, b.right, out, stats)
  else
    out.concat((a.lo..a.hi).to_a)
  end
  out
end

def blocks_of(text, size) = text.chars.each_slice(size).map(&:join)

original = "Merkle trees let two replicas find differing blocks by comparing a few hashes " \
           "instead of shipping whole files. Each parent hashes its children, so the root " \
           "summarizes everything below it."
blocks = blocks_of(original, 16)
tree = build(blocks)
puts "blocks: #{blocks.size}, height: #{height(tree)}, root: #{hex(tree.hash)}"
puts "hash('') = #{hex(fnv1a(""))}, hash('a') = #{hex(fnv1a("a"))}"

[0, 5, blocks.size - 1].each do |i|
  pr = proof(tree, i)
  good = verify(blocks[i], pr, tree.hash)
  forged = verify("#{blocks[i]}!", pr, tree.hash)
  sides = pr.map { |side, _h| side == :left ? "L" : "R" }.join
  puts "proof for block #{i}: #{pr.size} hashes (#{sides}), valid #{good}, forged #{forged}"
end
begin
  proof(tree, 99)
rescue IndexError => e
  puts "proof error: #{e.message}"
end

edits = [%w[shipping SHIPPING], %w[summarizes summarises]]
replica = edits.reduce(original) { |text, (from, to)| text.sub(from, to) }
other = build(blocks_of(replica, 16))
stats = { compared: 0 }
changed = diff(tree, other, [], stats)
puts "replica root: #{hex(other.hash)}, differing blocks: #{changed.join(",")} (#{stats[:compared]} hash comparisons)"
other_blocks = blocks_of(replica, 16)
changed.each { |i| puts "  block #{i}: #{blocks[i].inspect} -> #{other_blocks[i].inspect}" }
same = { compared: 0 }
puts "identical copy differs in: #{diff(tree, build(blocks_of(original, 16)), [], same).size} blocks (#{same[:compared]} comparison)"
