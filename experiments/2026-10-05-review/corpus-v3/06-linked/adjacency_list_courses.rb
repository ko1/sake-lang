class Edge
  attr_reader :to, :next

  def initialize(to, nxt)
    @to = to
    @next = nxt
  end
end

class QCell
  attr_accessor :v, :next

  def initialize(v, nxt)
    @v = v
    @next = nxt
  end
end

class CycleError < StandardError
  attr_reader :stuck

  def initialize(message, stuck)
    super(message)
    @stuck = stuck
  end
end

class Graph
  attr_reader :names

  def initialize
    @names = []
    @ids = {}
    @heads = []
    @indegree = []
  end

  def id(name)
    i = @ids[name]
    return i if i
    i = @names.size
    @ids[name] = i
    @names << name
    @heads << nil
    @indegree << 0
    i
  end

  def add_edge(from, to)
    a = id(from)
    b = id(to)
    @heads[a] = Edge.new(b, @heads[a])
    @indegree[b] += 1
  end

  def each_neighbor(v)
    e = @heads[v]
    while e
      yield e.to
      e = e.next
    end
  end

  def topo_order
    deg = @indegree.dup
    ready = (0...@names.size).select { |v| deg[v] == 0 }.sort_by { |v| @names[v] }
    order = []
    until ready.empty?
      v = ready.shift
      order << @names[v]
      each_neighbor(v) do |w|
        deg[w] -= 1
        if deg[w] == 0
          ready << w
          ready = ready.sort_by { |x| @names[x] }
        end
      end
    end
    if order.size < @names.size
      stuck = (0...@names.size).select { |v| deg[v] > 0 }.map { |v| @names[v] }.sort
      raise CycleError.new("cycle among #{stuck.join(", ")}", stuck)
    end
    order
  end

  def bfs_levels(start)
    s = @ids[start]
    return nil unless s
    dist = { s => 0 }
    head = QCell.new(s, nil)
    tail = head
    while head
      v = head.v
      each_neighbor(v) do |w|
        next if dist.key?(w)
        dist[w] = dist[v] + 1
        cell = QCell.new(w, nil)
        tail.next = cell
        tail = cell
      end
      head = head.next
    end
    levels = {}
    dist.each do |v, d|
      (levels[d] ||= []) << @names[v]
    end
    levels
  end
end

def load(spec)
  g = Graph.new
  spec.lines.each do |line|
    m = line.strip.match(/\A(\S+)\s*:\s*(.*)\z/)
    next unless m
    course = m[1]
    g.id(course)
    m[2].split(",").each do |pre|
      pre = pre.strip
      g.add_edge(pre, course) unless pre.empty?
    end
  end
  g
end

catalog = "intro: \ndata: intro\nalgo: data, discrete\ndiscrete: intro\nos: data, arch\narch: intro\ncompilers: algo, arch\nml: algo, stats\nstats: discrete\ncapstone: compilers, ml, os\n"
g = load(catalog)
puts "#{g.names.size} courses"
begin
  puts "order: #{g.topo_order.join(" -> ")}"
rescue CycleError => e
  puts "error: #{e.message}"
end
levels = g.bfs_levels("intro")
levels.keys.sort.each { |d| puts "  #{d} step(s) after intro: #{levels[d].sort.join(", ")}" }
from_algo = g.bfs_levels("algo")
puts "unlocked by algo: #{from_algo.select { |d, _| d > 0 }.flat_map { |_, ns| ns }.sort.join(", ")}"
p g.bfs_levels("astrology")

bad = load("a: c\nb: a\nc: b\nd: \ne: d\n")
begin
  bad.topo_order
rescue CycleError => e
  puts "error: #{e.message} (#{e.stuck.size} stuck)"
end
