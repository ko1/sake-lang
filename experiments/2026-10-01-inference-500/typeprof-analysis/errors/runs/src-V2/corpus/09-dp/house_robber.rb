class House
  attr_reader :name, :loot, :left, :right

  def initialize(name, loot, left, right)
    @name = name
    @loot = loot
    @left = left
    @right = right
  end
end

# houses on a street: no two neighbours
def street(loot)
  take = 0
  skip = 0
  loot.each do |v|
    take, skip = skip + v, [take, skip].max
  end
  [take, skip].max
end

def street_plan(loot)
  n = loot.size
  return [] if n == 0
  best = []
  loot.each_with_index do |v, i|
    with_it = v + (i >= 2 ? best[i - 2] : 0)
    without = i >= 1 ? best[i - 1] : 0
    best << [with_it, without].max
  end
  chosen = []
  i = n - 1
  while i >= 0
    prev = i >= 1 ? best[i - 1] : 0
    if best[i] != prev
      chosen.unshift(i)
      i -= 2
    else
      i -= 1
    end
  end
  chosen
end

# houses in a circle: first and last are neighbours
def circle(loot)
  n = loot.size
  return 0 if n == 0
  return loot[0] if n == 1
  [street(loot.take(n - 1)), street(loot.drop(1))].max
end

# houses on a tree: no parent together with its child; returns [with root, without root]
def tree_best(node)
  return [0, 0] if node.nil?
  lw, lo = tree_best(node.left)
  rw, ro = tree_best(node.right)
  [node.loot + lo + ro, [lw, lo].max + [rw, ro].max]
end

def tree_plan(node, may_take, out)
  return out if node.nil?
  with_root, without_root = tree_best(node)
  take = may_take && with_root > without_root
  out << node.name if take
  tree_plan(node.left, !take, out)
  tree_plan(node.right, !take, out)
  out
end

def tree_size(node)
  return 0 if node.nil?
  1 + tree_size(node.left) + tree_size(node.right)
end

streets = [
  [2, 7, 9, 3, 1],
  [1, 2, 3, 1],
  [5, 1, 1, 5],
  [10],
  [6, 7, 1, 30, 8, 2, 4],
  [4, 1, 2, 7, 5, 3, 1, 9, 2, 8]
]
streets.each do |loot|
  plan = street_plan(loot)
  taken = plan.map { |i| loot[i] }
  puts format("%-30s line %3d circle %3d  houses %s", loot.inspect, street(loot), circle(loot), plan.join(","))
  puts "  plan sum mismatch" if taken.sum != street(loot)
end

leaf = House.new("leaf", 1, nil, nil)
mill = House.new("mill", 3, nil, House.new("barn", 1, nil, nil))
farm = House.new("farm", 3, House.new("hut", 2, nil, House.new("shed", 3, nil, nil)), mill)
village = House.new("hall", 4,
  House.new("inn", 6, House.new("well", 5, nil, nil), House.new("forge", 1, leaf, nil)),
  House.new("chapel", 2, House.new("manor", 9, nil, nil), House.new("dock", 3, nil, House.new("pier", 7, nil, nil))))

[["farm", farm], ["village", village], ["empty", nil]].each do |label, root|
  best = tree_best(root).max
  names = tree_plan(root, true, [])
  puts "#{label} (#{tree_size(root)} houses): best #{best}, take #{names.empty? ? "nothing" : names.join(", ")}"
end
