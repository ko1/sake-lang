require "set"

class BT
  attr_reader :label, :left, :right

  def initialize(label, left, right)
    @label = label
    @left = left
    @right = right
  end
end

def balanced(labels)
  return nil if labels.empty?
  mid = labels.size / 2
  BT.new(labels[mid], balanced(labels.take(mid)), balanced(labels.drop(mid + 1)))
end

def recursive(node, order, out)
  return out if !node    
  out << node.label if order == :pre
  recursive(node.left, order, out)
  out << node.label if order == :in
  recursive(node.right, order, out)
  out << node.label if order == :post
  out
end

def iter_preorder(root)
  out = []
  stack = [root]
  until stack.empty?
    n = stack.pop
    next if !n    
    out << n.label
    stack.push(n.right, n.left)
  end
  out
end

def iter_inorder(root)
  out = []
  stack = []
  cur = root
  while cur || !stack.empty?
    while cur
      stack << cur
      cur = cur.left
    end
    n = stack.pop
    out << n.label
    cur = n.right
  end
  out
end

def iter_postorder(root)
  out = []
  stack = [root]
  until stack.empty?
    n = stack.pop
    next if !n    
    out.unshift(n.label)
    stack.push(n.left, n.right)
  end
  out
end

def levels(root)
  result = []
  level = [root].compact
  until level.empty?
    result << level.map(&:label)
    level = level.flat_map { |n| [n.left, n.right] }.compact
  end
  result
end

def vertical(root)
  cols = Hash.new { |h, k| h[k] = [] }
  queue = [[root, 0]]
  until queue.empty?
    n, col = queue.shift
    next if !n    
    cols[col] << n.label
    queue.push([n.left, col - 1], [n.right, col + 1])
  end
  cols.keys.sort.map { |c| [c, cols[c]] }
end

def path_to(node, label, path)
  return false if !node    
  path << node.label
  return true if node.label == label
  return true if path_to(node.left, label, path) || path_to(node.right, label, path)
  path.pop
  false
end

def parents(node, map)
  return map if !node    
  [node.left, node.right].compact.each do |c|
    map[c.label] = node
    parents(c, map)
  end
  map
end

def find(node, label)
  return nil if !node    
  return node if node.label == label
  find(node.left, label) || find(node.right, label)
end

def at_distance(root, label, k)
  up = parents(root, {})
  start = find(root, label)
  return [] if !start    
  seen = Set[label]
  frontier = [start]
  k.times do
    frontier = frontier.flat_map { |n| [n.left, n.right, up[n.label]] }
                       .compact
                       .select { |m| seen.add?(m.label) }
  end
  frontier.map(&:label).sort
end

root = balanced("ABCDEFGHIJKL".chars)
%i[pre in post].each do |order|
  rec = recursive(root, order, []).join
  it = case order
       when :pre then iter_preorder(root)
       when :in then iter_inorder(root)
       else iter_postorder(root)
       end
  its = it.join
  puts format("%-5s %s %s", order.to_s, rec, rec == its ? "(iterative agrees)" : "(iterative: #{its})")
end
lv = levels(root)
puts "levels: #{lv.map(&:join).join(" | ")}"
zig = lv.each_with_index.map { |l, i| i.odd? ? l.reverse : l }
puts "zigzag: #{zig.map(&:join).join(" | ")}"
puts "left view: #{lv.map(&:first).join}, right view: #{lv.map(&:last).join}"
puts "widest level: #{lv.map(&:size).max}"
vertical(root).each { |col, labels| puts format("  column %2d: %s", col, labels.join(" ")) }
%w[J A Z].each do |target|
  path = []
  found = path_to(root, target, path)
  puts "path to #{target}: #{found ? path.join(" > ") : "not found"}"
end
[["C", 2], ["G", 1], ["L", 3], ["Q", 1]].each do |label, k|
  near = at_distance(root, label, k)
  puts "distance #{k} from #{label}: #{near.empty? ? "(none)" : near.join(" ")}"
end
