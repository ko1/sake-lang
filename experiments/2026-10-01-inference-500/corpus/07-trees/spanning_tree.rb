require "set"

class DisjointSet
  attr_reader :parent, :rank, :sets

  def initialize(n)
    @parent = (0...n).to_a
    @rank = Array.new(n, 0)
    @sets = n
  end

  def find(x)
    root = x
    root = parent[root] while parent[root] != root
    while parent[x] != root
      nxt = parent[x]
      parent[x] = root
      x = nxt
    end
    root
  end

  def union(a, b)
    ra = find(a)
    rb = find(b)
    return false if ra == rb
    ra, rb = rb, ra if rank[ra] < rank[rb]
    parent[rb] = ra
    rank[ra] += 1 if rank[ra] == rank[rb]
    @sets -= 1
    true
  end
end

class Edge
  attr_reader :a, :b, :km

  def initialize(a, b, km)
    @a = a
    @b = b
    @km = km
  end
end

def kruskal(n, edges)
  ds = DisjointSet.new(n)
  chosen = edges.sort_by(&:km).select { |e| ds.union(e.a, e.b) }
  [chosen, ds.sets]
end

def adjacency(n, edges)
  adj = Array.new(n) { [] }
  edges.each do |e|
    adj[e.a] << [e.b, e.km]
    adj[e.b] << [e.a, e.km]
  end
  adj
end

# root the tree with BFS: parent index and edge weight to the parent
def root_tree(n, adj, root)
  parent = Array.new(n, -1)
  up_km = Array.new(n, 0)
  depth = Array.new(n, 0)
  seen = Set[root]
  queue = [root]
  until queue.empty?
    u = queue.shift
    adj[u].sort_by(&:first).each do |v, km|
      next unless seen.add?(v)
      parent[v] = u
      up_km[v] = km
      depth[v] = depth[u] + 1
      queue << v
    end
  end
  { parent: parent, up_km: up_km, depth: depth }
end

def tree_path(rooted, a, b)
  parent, up_km, depth = rooted.values_at(:parent, :up_km, :depth)
  left = [a]
  right = [b]
  worst = 0
  while a != b
    if depth[a] >= depth[b]
      worst = [worst, up_km[a]].max
      a = parent[a]
      left << a
    else
      worst = [worst, up_km[b]].max
      b = parent[b]
      right << b
    end
  end
  right.pop
  [left + right.reverse, worst]
end

def print_tree(names, adj_tree, rooted, u, indent)
  parent = rooted[:parent]
  label = parent[u] == -1 ? names[u] : "#{names[u]} (#{rooted[:up_km][u]} km)"
  puts "#{indent}#{label}"
  kids = adj_tree[u].map(&:first).select { |v| parent[v] == u }
  kids.sort_by { |v| names[v] }.each { |v| print_tree(names, adj_tree, rooted, v, indent + "  ") }
end

names = %w[Aachen Bonn Cologne Dortmund Essen Frankfurt Giessen Hagen]
idx = names.each_with_index.to_h
roads = <<~R
  Aachen Cologne 70
  Aachen Bonn 91
  Bonn Cologne 28
  Cologne Dortmund 94
  Cologne Essen 72
  Dortmund Essen 37
  Dortmund Hagen 27
  Essen Hagen 50
  Hagen Giessen 130
  Bonn Frankfurt 175
  Cologne Frankfurt 190
  Frankfurt Giessen 66
  Dortmund Giessen 170
R
edges = roads.each_line.map do |line|
  a, b, km = line.split
  Edge.new(idx[a], idx[b], km.to_i)
end

mst, components = kruskal(names.size, edges)
total_all = edges.sum(&:km)
total_mst = mst.sum(&:km)
puts "roads: #{edges.size} (#{total_all} km), spanning tree: #{mst.size} roads (#{total_mst} km), components: #{components}"
mst.each { |e| puts "  #{names[e.a]} - #{names[e.b]}: #{e.km}" }

adj_tree = adjacency(names.size, mst)
rooted = root_tree(names.size, adj_tree, idx["Cologne"])
print_tree(names, adj_tree, rooted, idx["Cologne"], "")

[%w[Aachen Giessen], %w[Hagen Bonn], %w[Essen Essen]].each do |from, to|
  path, worst = tree_path(rooted, idx[from], idx[to])
  puts "#{from} -> #{to}: #{path.map { |i| names[i] }.join(" > ")} (longest leg #{worst} km)"
end

closed = edges.reject { |e| e.km < 60 }
_m, parts = kruskal(names.size, closed)
puts "roads >= 60 km only: #{parts} component(s)"
short = edges.select { |e| e.km < 60 }
_m2, parts2 = kruskal(names.size, short)
puts "roads < 60 km only: #{parts2} component(s)"
