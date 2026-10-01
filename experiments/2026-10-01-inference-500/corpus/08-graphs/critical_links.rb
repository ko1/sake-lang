require "set"

class Grid
  attr_reader :names, :adj

  def initialize(names, adj)
    @names = names
    @adj = adj
  end

  def self.build(names, wires)
    g = new(names, Array.new(names.size) { [] })
    wires.each do |a, b|
      i = g.id(a)
      j = g.id(b)
      g.adj[i] << j
      g.adj[j] << i
    end
    g
  end

  def id(name)
    i = @names.index(name)
    raise KeyError, "unknown station #{name}" unless i
    i
  end

  def name(i) = @names[i]
  def size = @names.size
end

class Scan
  attr_accessor :disc, :low, :time, :bridges, :cut_points

  def initialize(disc, low, time, bridges, cut_points)
    @disc = disc
    @low = low
    @time = time
    @bridges = bridges
    @cut_points = cut_points
  end
end

def dfs(grid, scan, u, parent)
  disc = scan.disc
  low = scan.low
  disc[u] = low[u] = scan.time
  scan.time += 1
  children = 0
  grid.adj[u].each do |v|
    next if v == parent
    if disc[v].nil?
      children += 1
      dfs(grid, scan, v, u)
      low[u] = low[v] if low[v] < low[u]
      scan.bridges << [u, v] if low[v] > disc[u]
      scan.cut_points << u if !parent.nil? && low[v] >= disc[u]
    elsif disc[v] < low[u]
      low[u] = disc[v]
    end
  end
  scan.cut_points << u if parent.nil? && children > 1
end

def analyze(grid)
  n = grid.size
  scan = Scan.new(Array.new(n), Array.new(n, 0), 0, [], Set.new)
  islands = 0
  n.times do |u|
    next if scan.disc[u]
    islands += 1
    dfs(grid, scan, u, nil)
  end
  [scan, islands]
end

def label(grid, pair)
  x, y = pair.map { |i| grid.name(i) }
  x < y ? "#{x}--#{y}" : "#{y}--#{x}"
end

def report(title, names, wires)
  puts "== #{title}"
  grid = Grid.build(names, wires)
  scan, islands = analyze(grid)
  bridges = scan.bridges.map { |pr| label(grid, pr) }.sort
  cuts = scan.cut_points.map { |i| grid.name(i) }.sort
  puts "stations: #{grid.size}, wires: #{wires.size}, islands: #{islands}"
  puts "single points of failure: #{cuts.empty? ? "none" : cuts.join(", ")}"
  puts "critical wires: #{bridges.empty? ? "none" : bridges.join(", ")}"
  degrees = grid.adj.map(&:size)
  leaf_count = degrees.count { |d| d == 1 }
  puts "leaf stations: #{leaf_count}, max degree: #{degrees.max}"
rescue KeyError => e
  puts "bad input: #{e.message}"
end

report("city grid",
       ["plant", "north", "south", "east", "west", "mall", "farm", "mine", "port"],
       [["plant", "north"], ["plant", "south"], ["north", "south"], ["north", "east"],
        ["east", "mall"], ["mall", "west"], ["west", "east"], ["south", "farm"],
        ["farm", "mine"], ["port", "plant"]])
report("ring", ["a", "b", "c", "d"], [["a", "b"], ["b", "c"], ["c", "d"], ["d", "a"]])
report("two parts", ["p", "q", "r", "s", "t"], [["p", "q"], ["q", "r"], ["s", "t"]])
report("typo", ["x", "y"], [["x", "z"]])
