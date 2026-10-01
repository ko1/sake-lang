class BNode
  attr_accessor :keys, :children

  def initialize(keys, children)
    @keys = keys
    @children = children
  end

  def leaf? = children.empty?
  def full?(t) = keys.size == 2 * t - 1
end

class BTree
  attr_reader :t
  attr_accessor :root, :splits

  def initialize(t)
    @t = t
    @root = BNode.new([], [])
    @splits = 0
  end

  def search(key)
    node = root
    depth = 0
    while node
      i = 0
      i += 1 while i < node.keys.size && key > node.keys[i]
      return [true, depth] if i < node.keys.size && node.keys[i] == key
      return [false, depth] if node.leaf?
      node = node.children[i]
      depth += 1
    end
    [false, depth]
  end

  def insert(key)
    found, _d = search(key)
    return false if found
    r = root
    if r.full?(t)
      new_root = BNode.new([], [r])
      self.root = new_root
      split_child(new_root, 0)
      r = new_root
    end
    insert_nonfull(r, key)
    true
  end

  def each_key(&block) = walk(root, &block)

  def levels
    out = []
    level = [root]
    until level.empty?
      out << level.map { |n| "[#{n.keys.join(" ")}]" }.join(" ")
      level = level.flat_map(&:children)
    end
    out
  end

  def range_count(lo, hi)
    n = 0
    each_key { |k| n += 1 if lo <= k && k <= hi }
    n
  end

  private

  def split_child(parent, i)
    full = parent.children[i]
    right = BNode.new(full.keys.drop(t), full.leaf? ? [] : full.children.drop(t))
    median = full.keys[t - 1]
    full.keys = full.keys.take(t - 1)
    full.children = full.children.take(t) unless full.leaf?
    parent.keys.insert(i, median)
    parent.children.insert(i + 1, right)
    self.splits += 1
  end

  def insert_nonfull(node, key)
    i = node.keys.size
    i -= 1 while i > 0 && key < node.keys[i - 1]
    if node.leaf?
      node.keys.insert(i, key)
      return
    end
    if node.children[i].full?(t)
      split_child(node, i)
      i += 1 if key > node.keys[i]
    end
    insert_nonfull(node.children[i], key)
  end

  def walk(node, &block)
    if node.leaf?
      node.keys.each(&block)
      return
    end
    node.keys.each_with_index do |k, i|
      walk(node.children[i], &block)
      yield k
    end
    walk(node.children.last, &block)
  end
end

[2, 3].each do |t|
  bt = BTree.new(t)
  keys = [50, 20, 80, 10, 30, 60, 90, 25, 35, 55, 65, 85, 95, 5, 15, 40, 45, 70, 75, 30, 100, 1]
  dupes = keys.count { |k| !bt.insert(k) }
  puts "== minimum degree #{t}: #{keys.size - dupes} keys, #{dupes} duplicate(s), #{bt.splits} splits =="
  bt.levels.each_with_index { |line, d| puts "  L#{d}: #{line}" }
  all = []
  bt.each_key { |k| all << k }
  sorted = all == all.sort
  puts "  in order: #{all.join(",")} (#{sorted ? "sorted" : "NOT SORTED"})"
  [45, 100, 33, 1].each do |k|
    found, depth = bt.search(k)
    puts "  search #{k}: #{found ? "found" : "missing"} at depth #{depth}"
  end
  puts "  keys in 20..60: #{bt.range_count(20, 60)}"
end
