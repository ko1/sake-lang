class ParseError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

class Graph
  attr_reader :name, :nodes, :edges

  def initialize(name, nodes, edges)
    @name = name
    @nodes = nodes
    @edges = edges
  end

  def add_node(n)
    @nodes << n unless @nodes.include?(n)
  end
end

def parse_dot(src)
  lines = src.lines
  header = (lines[0] || "").match(/^\s*digraph\s+(\w+)\s*\{\s*$/)
  raise ParseError.new("expected 'digraph NAME {'", 1) unless header
  g = Graph.new(header[1], [], [])
  closed = false
  lines.drop(1).each_with_index do |raw, i|
    lineno = i + 2
    line = raw.sub(%r{//.*$}, "").strip
    next if line.empty?
    if line == "}"
      closed = true
      next
    end
    raise ParseError.new("text after closing brace", lineno) if closed
    if (m = line.match(/^(\w+)\s*->\s*(\w+)\s*(?:\[weight=(\d+)\])?\s*;$/)) && m
      w = m[3] ? m[3].to_i : 1
      g.edges << { from: m[1], to: m[2], weight: w }
      g.add_node(m[1])
      g.add_node(m[2])
    elsif (m = line.match(/^(\w+)\s*;$/)) && m
      g.add_node(m[1])
    else
      raise ParseError.new("cannot parse '#{line}'", lineno)
    end
  end
  raise ParseError.new("missing closing brace", lines.size) unless closed
  g
end

def stats(g)
  outdeg = Hash.new(0)
  indeg = Hash.new(0)
  pairs = Hash.new(0)
  loops = 0
  g.edges.each do |e|
    e => { from:, to: }
    outdeg[from] += 1
    indeg[to] += 1
    pairs[[from, to]] += 1
    loops += 1 if from == to
  end
  {
    sources: g.nodes.select { |n| indeg[n] == 0 },
    sinks: g.nodes.select { |n| outdeg[n] == 0 },
    loops: loops,
    parallel: pairs.count { |k, c| c > 1 },
    mutual: pairs.count { |(a, b), c| a < b && pairs.key?([b, a]) },
    hub: g.nodes.max_by { |n| indeg[n] + outdeg[n] },
    total_weight: g.edges.sum { |e| e[:weight] }
  }
end

def describe(src)
  g = parse_dot(src)
  s = stats(g)
  s => { sources:, sinks:, loops:, parallel:, mutual:, hub:, total_weight: }
  puts "graph #{g.name}: #{g.nodes.size} nodes, #{g.edges.size} edges, weight #{total_weight}"
  puts "  sources: #{sources.join(" ")}"
  puts "  sinks:   #{sinks.join(" ")}"
  puts "  self-loops=#{loops} parallel=#{parallel} mutual=#{mutual} hub=#{hub}"
rescue ParseError => e
  puts "parse error on line #{e.line}: #{e.message}"
end

describe(<<~DOT)
  digraph pipeline {
    fetch -> parse [weight=2];
    parse -> check;
    check -> parse;   // retry
    check -> store [weight=5];
    store -> store;
    fetch -> parse;
    report;
    store -> notify [weight=1];
  }
DOT

describe(<<~DOT)
  digraph web {
    home -> about;
    home -> blog;
    blog -> post1;
    blog -> post2;
    post1 -> post2;
    post2 -> post1;
    post2 -> home;
  }
DOT

describe("graph bad {\n}\n")
describe("digraph x {\n  a -> b;\n  a => c;\n}\n")
describe("digraph y {\n  a -> b;\n")
describe("digraph z {\n  a;\n}\n  b;\n")
