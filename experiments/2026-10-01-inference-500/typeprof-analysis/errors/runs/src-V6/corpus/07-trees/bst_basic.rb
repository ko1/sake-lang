class Node
  attr_accessor :key, :value, :left, :right

  def initialize(key, value, left, right)
    @key = key
    @value = value
    @left = left
    @right = right
  end

  def leaf?
    !left     && !right    
  end
end

def insert(node, key, value)
  return Node.new(key, value, nil, nil) if !node    
  if key < node.key
    node.left = insert(node.left, key, value)
  elsif key > node.key
    node.right = insert(node.right, key, value)
  else
    node.value = value
  end
  node
end

def search(node, key)
  while node
    return node.value if key == node.key
    node = key < node.key ? node.left : node.right
  end
  nil
end

def min_node(node)
  node = node.left while node.left
  node
end

def delete(node, key)
  return nil if !node    
  if key < node.key
    node.left = delete(node.left, key)
  elsif key > node.key
    node.right = delete(node.right, key)
  else
    return node.right if !node.left    
    return node.left if !node.right    
    succ = min_node(node.right)
    node.key = succ.key
    node.value = succ.value
    node.right = delete(node.right, succ.key)
  end
  node
end

def each_inorder(node, &block)
  return if !node    
  each_inorder(node.left, &block)
  yield node.key, node.value
  each_inorder(node.right, &block)
end

def height(node)
  return 0 if !node    
  1 + [height(node.left), height(node.right)].max
end

def count_leaves(node)
  return 0 if !node    
  return 1 if node.leaf?
  count_leaves(node.left) + count_leaves(node.right)
end

def range_keys(node, lo, hi, out)
  return out if !node    
  k = node.key
  range_keys(node.left, lo, hi, out) if lo < k
  out << k if lo <= k && k <= hi
  range_keys(node.right, lo, hi, out) if k < hi
  out
end

def floor_key(node, key)
  best = nil
  while node
    return node.key if node.key == key
    if node.key < key
      best = node.key
      node = node.right
    else
      node = node.left
    end
  end
  best
end

def kth_smallest(node, k)
  i = 0
  result = nil
  each_inorder(node) do |key, _v|
    i += 1
    result = key if i == k
  end
  result
end

words = "mango kiwi apple peach banana cherry grape lemon fig date plum".split(" ")
root = nil
words.each_with_index { |w, i| root = insert(root, w, i * 10) }
root = insert(root, "kiwi", 999)

puts "size: #{range_keys(root, "", "zzzz", []).size}"
puts "height: #{height(root)}"
puts "leaves: #{count_leaves(root)}"
pairs = []
each_inorder(root) { |k, v| pairs << "#{k}=#{v}" }
puts pairs.join(" ")
%w[kiwi fig orange].each do |w|
  v = search(root, w)
  puts(v ? "#{w} -> #{v}" : "#{w} missing")
end
puts "between c and l: #{range_keys(root, "c", "l", []).join(",")}"
puts "floor(coconut): #{floor_key(root, "coconut")}"
fl = floor_key(root, "aardvark")
puts "floor(aardvark): #{!fl     ? "none" : fl}"
puts "3rd smallest: #{kth_smallest(root, 3)}"

%w[mango apple zebra peach].each do |w|
  root = delete(root, w)
  keys = []
  each_inorder(root) { |k, _v| keys << k }
  puts "after delete #{w}: #{keys.join(" ")} (h=#{height(root)}, root=#{root.key})"
end
