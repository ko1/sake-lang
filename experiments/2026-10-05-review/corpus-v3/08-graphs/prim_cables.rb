class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def -(other) = Point.new(x - other.x, y - other.y)
  def +(other) = Point.new(x + other.x, y + other.y)
  def length = Math.hypot(x, y)
  def to_s = format("(%.1f, %.1f)", x, y)
end

class Site
  attr_reader :name, :pos

  def initialize(name, pos)
    @name = name
    @pos = pos
  end
end

def dist(a, b) = (a.pos - b.pos).length

# Prim's algorithm on the complete graph, O(n^2) with a plain array of best links.
def prim(sites)
  n = sites.size
  in_tree = Array.new(n, false)
  best = Array.new(n)
  link = Array.new(n)
  best[0] = 0.0
  edges = []
  n.times do
    u = nil
    n.times do |i|
      next if in_tree[i] || best[i].nil?
      u = i if u.nil? || best[i] < best[u]
    end
    in_tree[u] = true
    edges << [link[u], u, best[u]] if link[u]
    n.times do |v|
      next if in_tree[v]
      d = dist(sites[u], sites[v])
      if best[v].nil? || d < best[v]
        best[v] = d
        link[v] = u
      end
    end
  end
  edges
end

def centroid(sites)
  sum = sites.reduce(Point.new(0.0, 0.0)) { |acc, s| acc + s.pos }
  n = sites.size
  Point.new(sum.x / n, sum.y / n)
end

def plan(title, raw)
  sites = raw.map { |name, x, y| Site.new(name, Point.new(x, y)) }
  puts "== #{title}: #{sites.size} sites"
  edges = prim(sites)
  total = 0.0
  edges.each do |a, b, d|
    total += d
    puts format("  %-7s - %-7s %6.2f km", sites[a].name, sites[b].name, d)
  end
  puts format("  total cable: %.2f km", total)
  longest = edges.max_by { |a, b, d| d }
  if longest
    a, b, d = longest
    puts format("  longest run: %s-%s", sites[a].name, sites[b].name)
  end
  degree = Hash.new(0)
  edges.each do |a, b, d|
    degree[a] += 1
    degree[b] += 1
  end
  hub, deg = degree.max_by { |i, c| c } || [0, 0]
  puts "  busiest junction: #{sites[hub].name} (#{deg} cables)"
  puts "  centre of sites: #{centroid(sites)}"
end

plan("farm sensors", [
  ["barn", 0.0, 0.0], ["silo", 1.5, 0.5], ["pump", 4.0, 1.0], ["gate", 0.5, 3.5],
  ["pond", 5.5, 4.0], ["field1", 2.5, 2.5], ["field2", 3.5, 5.0], ["house", -1.0, 1.5],
  ["shed", 6.0, 0.0], ["well", 2.0, -1.5]
])
plan("ring of towers", (0...6).map { |i|
  ang = i * Math::PI / 3
  ["t#{i}", (Math.cos(ang) * 10).round(3), (Math.sin(ang) * 10).round(3)]
})
plan("single", [["solo", 1.0, 1.0]])
