class NegativeCycle < StandardError
  attr_reader :cycle

  def initialize(message, cycle)
    super(message)
    @cycle = cycle
  end
end

class Arc
  attr_reader :from, :to, :weight

  def initialize(from, to, weight)
    @from = from
    @to = to
    @weight = weight
  end
end

def parse_arcs(spec)
  spec.split(";").map do |item|
    m = item.strip.match(/\A(\w+)\s*->\s*(\w+)\s+(-?\d+)\z/)
    raise ArgumentError, "bad arc: #{item}" if !m    
    Arc.new(m[1], m[2], m[3].to_i)
  end
end

def vertices(arcs)
  arcs.flat_map { |a| [a.from, a.to] }.uniq
end

def relax_all(arcs, dist, pred)
  changed = nil
  arcs.each do |a|
    du = dist[a.from]
    next if !du    
    cand = du + a.weight
    dv = dist[a.to]
    if !dv     || cand < dv
      dist[a.to] = cand
      pred[a.to] = a.from
      changed = a.to
    end
  end
  changed
end

def trace_cycle(pred, start, n)
  v = start
  n.times { v = pred[v] }
  cycle = [v]
  u = pred[v]
  while u != v
    cycle << u
    u = pred[u]
  end
  cycle << v
  cycle.reverse
end

def bellman_ford(arcs, source)
  vs = vertices(arcs)
  dist = { source => 0 }
  pred = {}
  rounds = 0
  (vs.size - 1).times do
    rounds += 1
    return [dist, pred, rounds] if !relax_all(arcs, dist, pred)    
  end
  last = relax_all(arcs, dist, pred)
  if last
    raise NegativeCycle.new("negative cycle reachable from #{source}", trace_cycle(pred, last, vs.size))
  end
  [dist, pred, rounds]
end

def route(pred, source, target)
  path = [target]
  while path.first != source
    up = pred[path.first]
    return nil unless up
    path.unshift(up)
  end
  path
end

def run(title, spec, source)
  puts "== #{title}"
  arcs = parse_arcs(spec)
  dist, pred, rounds = bellman_ford(arcs, source)
  puts "settled after #{rounds} round(s)"
  vertices(arcs).sort.each do |v|
    d = dist[v]
    if d
      puts format("  %-6s %5d  via %s", v, d, route(pred, source, v).join(">"))
    else
      puts format("  %-6s %5s", v, "--")
    end
  end
rescue NegativeCycle => e
  puts "  #{e.message}: #{e.cycle.join(" -> ")}"
rescue ArgumentError => e
  puts "  input error: #{e.message}"
end

run("delivery costs with rebates",
    "depot -> a 4; depot -> b 6; a -> b -3; b -> c 2; a -> c 5; c -> d 1; d -> e -2; b -> e 7; f -> depot 1",
    "depot")
run("arbitrage loop",
    "s -> x 1; x -> y 2; y -> z -4; z -> x 1; z -> t 3",
    "s")
run("broken input", "s -> x 1; x => y 2", "s")
run("chain", "n1 -> n2 1; n2 -> n3 1; n3 -> n4 1; n4 -> n5 1", "n1")
