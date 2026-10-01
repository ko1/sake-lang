class Node
  attr_reader :key, :left, :right

  def initialize(key, left, right)
    @key = key
    @left = left
    @right = right
  end
end

def optimal_tree(keys, freq)
  n = keys.size
  cost = Array.new(n + 1) { Array.new(n + 1, 0.0) }
  root = Array.new(n + 1) { Array.new(n + 1, 0) }
  weight = Array.new(n + 1) { Array.new(n + 1, 0.0) }
  n.times do |i|
    weight[i][i + 1] = freq[i]
    cost[i][i + 1] = freq[i]
    root[i][i + 1] = i
  end
  2.upto(n) do |len|
    0.upto(n - len) do |i|
      j = i + len
      weight[i][j] = weight[i][j - 1] + freq[j - 1]
      best = nil
      i.upto(j - 1) do |r|
        c = cost[i][r] + cost[r + 1][j] + weight[i][j]
        if best.nil? || c < best - 1.0e-12
          best = c
          root[i][j] = r
        end
      end
      cost[i][j] = best
    end
  end
  [cost[0][n], build(keys, root, 0, n)]
end

def build(keys, root, i, j)
  return nil if i >= j
  r = root[i][j]
  Node.new(keys[r], build(keys, root, i, r), build(keys, root, r + 1, j))
end

def balanced(keys, i, j)
  return nil if i >= j
  m = (i + j) / 2
  Node.new(keys[m], balanced(keys, i, m), balanced(keys, m + 1, j))
end

def expected_cost(node, freq_of, depth)
  return 0.0 if node.nil?
  freq_of[node.key] * depth + expected_cost(node.left, freq_of, depth + 1) + expected_cost(node.right, freq_of, depth + 1)
end

def lookups(node, key)
  steps = 0
  while node
    steps += 1
    return steps if node.key == key
    node = key < node.key ? node.left : node.right
  end
  nil
end

def draw(node, indent, out)
  return out if node.nil?
  draw(node.right, indent + "    ", out)
  out << indent + node.key
  draw(node.left, indent + "    ", out)
  out
end

def height(node)
  return 0 if node.nil?
  1 + [height(node.left), height(node.right)].max
end

# how often each keyword is looked up by a toy tokenizer
counts = { "begin" => 12, "def" => 140, "do" => 95, "else" => 30, "end" => 260, "if" => 80, "return" => 45, "while" => 8, "yield" => 4 }
keys = counts.keys.sort
total = counts.values.sum
freq = keys.map { |k| counts[k] / total.to_f }
freq_of = keys.zip(freq).to_h

best, tree = optimal_tree(keys, freq)
plain = balanced(keys, 0, keys.size)
puts format("optimal expected comparisons:  %.4f (dp %.4f), height %d", expected_cost(tree, freq_of, 1), best, height(tree))
puts format("balanced expected comparisons: %.4f, height %d", expected_cost(plain, freq_of, 1), height(plain))
puts "optimal tree (rotated):"
draw(tree, "  ", []).each { |line| puts line }

puts "comparisons per keyword (optimal / balanced):"
keys.each do |k|
  puts format("  %-7s %5.3f  %d / %d", k, freq_of[k], lookups(tree, k), lookups(plain, k))
end
missing = lookups(tree, "rescue")
puts "rescue: #{missing.nil? ? "not a key" : missing}"

uniform = keys.map { 1.0 / keys.size }
u_cost, u_tree = optimal_tree(keys, uniform)
puts format("uniform weights: optimal %.4f, root %s", u_cost, u_tree.key)
