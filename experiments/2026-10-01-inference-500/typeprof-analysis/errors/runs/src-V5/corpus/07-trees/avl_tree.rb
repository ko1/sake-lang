class AvlNode
  attr_accessor :key, :height, :left, :right

  def initialize(key)
    @key = key
    @height = 1
    @left = nil
    @right = nil
  end
end

class Stats
  attr_accessor :rotations

  def initialize(rotations)
    @rotations = rotations
  end
end

def h(n) = !n     ? 0 : n.height

def fix_height(n)
  n.height = [h(n.left), h(n.right)].max + 1
end

def balance(n) = h(n.left) - h(n.right)

def rotate_right(n, st)
  st.rotations += 1
  l = n.left
  n.left = l.right
  l.right = n
  fix_height(n)
  fix_height(l)
  l
end

def rotate_left(n, st)
  st.rotations += 1
  r = n.right
  n.right = r.left
  r.left = n
  fix_height(n)
  fix_height(r)
  r
end

def rebalance(n, st)
  fix_height(n)
  b = balance(n)
  if b > 1
    n.left = rotate_left(n.left, st) if balance(n.left) < 0
    return rotate_right(n, st)
  end
  if b < -1
    n.right = rotate_right(n.right, st) if balance(n.right) > 0
    return rotate_left(n, st)
  end
  n
end

def insert(n, key, st)
  return AvlNode.new(key) if !n    
  if key < n.key
    n.left = insert(n.left, key, st)
  elsif key > n.key
    n.right = insert(n.right, key, st)
  else
    return n
  end
  rebalance(n, st)
end

def remove_min(n, st)
  return n.right if !n.left    
  n.left = remove_min(n.left, st)
  rebalance(n, st)
end

def delete(n, key, st)
  return nil if !n    
  if key < n.key
    n.left = delete(n.left, key, st)
  elsif key > n.key
    n.right = delete(n.right, key, st)
  else
    l = n.left
    r = n.right
    return l if !r    
    m = r
    m = m.left while m.left
    m.right = remove_min(r, st)
    m.left = l
    return rebalance(m, st)
  end
  rebalance(n, st)
end

def valid?(n, lo, hi)
  return true if !n    
  k = n.key
  return false if (lo && k <= lo) || (hi && k >= hi)
  return false unless (-1..1).cover?(balance(n))
  return false if n.height != 1 + [h(n.left), h(n.right)].max
  valid?(n.left, lo, k) && valid?(n.right, k, hi)
end

def keys(n, out)
  return out if !n    
  keys(n.left, out)
  out << n.key
  keys(n.right, out)
end

def draw(n, depth, lines)
  return lines if !n    
  draw(n.right, depth + 1, lines)
  lines << "#{"    " * depth}#{n.key}"
  draw(n.left, depth + 1, lines)
end

def level_order(root)
  levels = []
  queue = [[root, 0]]
  until queue.empty?
    node, d = queue.shift
    next if !node    
    levels << [] if levels.size <= d
    levels[d] << node.key
    queue << [node.left, d + 1] << [node.right, d + 1]
  end
  levels
end

st = Stats.new(0)
root = nil
(1..15).each { |i| root = insert(root, i, st) }
puts "ascending 1..15: height #{h(root)}, rotations #{st.rotations}, valid #{valid?(root, nil, nil)}"
level_order(root).each_with_index { |lv, d| puts "  level #{d}: #{lv.join(" ")}" }

st2 = Stats.new(0)
root2 = nil
seq = [50, 20, 70, 10, 30, 25, 27, 26, 80, 90, 85, 60, 65, 64, 5, 1]
seq.each { |k| root2 = insert(root2, k, st2) }
root2 = insert(root2, 30, st2)
puts "mixed: height #{h(root2)}, rotations #{st2.rotations}, valid #{valid?(root2, nil, nil)}"
draw(root2, 0, []).each { |l| puts l }

[20, 50, 99, 1, 5, 10].each do |k|
  before = st2.rotations
  root2 = delete(root2, k, st2)
  puts "delete #{k}: root #{root2.key}, height #{h(root2)}, +#{st2.rotations - before} rotations, valid #{valid?(root2, nil, nil)}"
end
puts "keys: #{keys(root2, []).join(",")}"
