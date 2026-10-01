class UnionFind
  attr_reader :sets

  def initialize(n)
    @parent = (0...n).to_a
    @rank = Array.new(n, 0)
    @sets = n
  end

  def find(x)
    root = x
    root = @parent[root] while @parent[root] != root
    while @parent[x] != root
      @parent[x], x = root, @parent[x]
    end
    root
  end

  def union(a, b)
    ra = find(a)
    rb = find(b)
    return false if ra == rb
    ra, rb = rb, ra if @rank[ra] < @rank[rb]
    @parent[rb] = ra
    @rank[ra] += 1 if @rank[ra] == @rank[rb]
    @sets -= 1
    true
  end
end

class Edge
  include Comparable
  attr_reader :a, :b, :cost

  def initialize(a, b, cost)
    @a = a
    @b = b
    @cost = cost
  end

  def <=>(other)
    c = cost <=> other.cost
    return c if c != 0
    "#{a}-#{b}" <=> "#{other.a}-#{other.b}"
  end

  def to_s = "#{a}-#{b} (#{cost})"
end

def kruskal(names, edges)
  index = names.each_with_index.to_h
  uf = UnionFind.new(names.size)
  chosen = []
  rejected = 0
  edges.sort.each do |e|
    if uf.union(index[e.a], index[e.b])
      chosen << e
    else
      rejected += 1
    end
  end
  { tree: chosen, rejected: rejected, parts: uf.sets }
end

def parse_edges(text)
  text.lines.filter_map do |line|
    m = line.match(/^\s*(\w+)\s*-\s*(\w+)\s*:\s*(\d+)/)
    Edge.new(m[1], m[2], m[3].to_i) if m
  end
end

def summarize(title, names, text)
  puts "== #{title}"
  edges = parse_edges(text)
  result = kruskal(names, edges)
  result => { tree:, rejected:, parts: }
  tree.each { |e| puts "  #{e}" }
  total = tree.sum(&:cost)
  all = edges.sum(&:cost)
  puts "  cable: #{total} of #{all} (#{rejected} links skipped)"
  puts "  WARNING: network splits into #{parts} parts" if parts > 1
  cheapest = edges.min
  priciest = tree.max
  puts "  cheapest link: #{cheapest}" if cheapest
  puts "  priciest used: #{priciest}" if priciest
end

office = ["hq", "lab", "dock", "shop", "mill", "farm", "port"]
office_links = "hq - lab : 7\n" \
               "hq - dock : 5\n" \
               "lab - dock : 8\n" \
               "lab - shop : 9\n" \
               "lab - mill : 7\n" \
               "dock - shop : 15\n" \
               "dock - farm : 6\n" \
               "shop - farm : 8\n" \
               "shop - mill : 5\n" \
               "farm - mill : 9\n" \
               "farm - port : 11\n" \
               "mill - port : 9\n" \
               "# a comment line\n"
summarize("office campus", office, office_links)

islands = ["a", "b", "c", "d", "e"]
island_links = "a - b : 3\nb - c : 1\na - c : 2\nd - e : 4\n"
summarize("two islands", islands, island_links)
