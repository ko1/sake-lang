class NegativeCycle < StandardError
  attr_reader :node

  def initialize(message, node)
    super(message)
    @node = node
  end
end

class Graph
  attr_reader :names, :index, :edges

  def initialize(names, index, edges)
    @names = names
    @index = index
    @edges = edges
  end

  def self.build(edge_list)
    names = []
    index = {}
    edge_list.each do |from, to, _|
      [from, to].each do |name|
        unless index.key?(name)
          index[name] = names.size
          names << name
        end
      end
    end
    new(names, index, edge_list)
  end

  def size = @names.size
end

def all_pairs(g)
  n = g.size
  index = g.index
  dist = Array.new(n) { |i| Array.new(n) { |j| i == j ? 0 : nil } }
  nxt = Array.new(n) { |i| Array.new(n) { |j| i == j ? j : nil } }
  g.edges.each do |from, to, w|
    i = index[from]
    j = index[to]
    old = dist[i][j]
    if old.nil? || w < old
      dist[i][j] = w
      nxt[i][j] = j
    end
  end
  n.times do |k|
    n.times do |i|
      ik = dist[i][k]
      next if ik.nil?
      n.times do |j|
        kj = dist[k][j]
        next if kj.nil?
        cur = dist[i][j]
        if cur.nil? || ik + kj < cur
          dist[i][j] = ik + kj
          nxt[i][j] = nxt[i][k]
        end
      end
    end
  end
  n.times do |i|
    raise NegativeCycle.new("negative cycle", g.names[i]) if dist[i][i] < 0
  end
  [dist, nxt]
end

def route(g, nxt, from, to)
  i = g.index[from]
  j = g.index[to]
  return nil if nxt[i][j].nil?
  path = [from]
  while i != j
    i = nxt[i][j]
    path << g.names[i]
  end
  path
end

def print_matrix(g, dist)
  puts "        " + g.names.map { |nm| nm.rjust(7) }.join
  dist.each_with_index do |row, i|
    cells = row.map { |d| (d.nil? ? "-" : d.to_s).rjust(7) }
    puts "  " + g.names[i].ljust(6) + cells.join
  end
end

roads = [
  ["Oslo", "Bergen", 7], ["Oslo", "Lund", 9], ["Oslo", "Kiel", 14],
  ["Bergen", "Lund", 10], ["Bergen", "Turku", 15], ["Lund", "Turku", 11],
  ["Lund", "Kiel", 2], ["Kiel", "Riga", 9], ["Turku", "Riga", 6],
  ["Riga", "Oslo", 20], ["Turku", "Bergen", 15], ["Kiel", "Oslo", 14]
]
g = Graph.build(roads)
dist, nxt = all_pairs(g)
puts "shortest travel times:"
print_matrix(g, dist)

queries = [["Oslo", "Riga"], ["Bergen", "Kiel"], ["Riga", "Bergen"], ["Turku", "Lund"]]
queries.each do |from, to|
  path = route(g, nxt, from, to)
  i = g.index[from]
  j = g.index[to]
  if path
    puts "#{from} -> #{to}: #{dist[i][j]} via #{path.join(" > ")}"
  else
    puts "#{from} -> #{to}: unreachable"
  end
end

ecc = (0...g.size).map { |i| [g.names[i], dist[i].compact.max] }
center = ecc.min_by { |_, worst| worst }
puts "best hub: #{center[0]} (farthest city #{center[1]} away)"

oneway = Graph.build([["A", "B", 3], ["B", "C", 4], ["D", "C", 1]])
d2, n2 = all_pairs(oneway)
print_matrix(oneway, d2)
p route(oneway, n2, "C", "A")

begin
  all_pairs(Graph.build([["x", "y", 2], ["y", "z", -5], ["z", "x", 1]]))
rescue NegativeCycle => e
  puts "#{e.message} through #{e.node}"
end
