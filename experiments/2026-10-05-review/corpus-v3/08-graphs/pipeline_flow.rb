require "set"

class FlowNet
  attr_reader :cap, :flow, :nodes

  def initialize
    @cap = {}
    @flow = Hash.new(0)
    @nodes = []
  end

  def add_node(v)
    @nodes << v unless @nodes.include?(v)
  end

  def add_pipe(a, b, c)
    add_node(a)
    add_node(b)
    @cap[[a, b]] = @cap.fetch([a, b], 0) + c
    @cap[[b, a]] ||= 0
  end

  def residual(a, b) = @cap.fetch([a, b], 0) - @flow[[a, b]]

  def neighbors(a) = @nodes.select { |b| @cap.key?([a, b]) }

  def augmenting_path(s, t)
    prev = { s => s }
    queue = [s]
    until queue.empty?
      u = queue.shift
      neighbors(u).each do |v|
        next if prev.key?(v) || residual(u, v) <= 0
        prev[v] = u
        return prev if v == t
        queue << v
      end
    end
    nil
  end

  def max_flow(s, t)
    total = 0
    rounds = 0
    while (prev = augmenting_path(s, t))
      bottleneck = nil
      v = t
      while v != s
        u = prev[v]
        r = residual(u, v)
        bottleneck = r if bottleneck.nil? || r < bottleneck
        v = u
      end
      v = t
      while v != s
        u = prev[v]
        @flow[[u, v]] += bottleneck
        @flow[[v, u]] -= bottleneck
        v = u
      end
      total += bottleneck
      rounds += 1
    end
    [total, rounds]
  end

  def min_cut(s)
    side = Set[s]
    stack = [s]
    until stack.empty?
      u = stack.pop
      neighbors(u).each do |v|
        stack << v if residual(u, v) > 0 && side.add?(v)
      end
    end
    @cap.filter_map do |(a, b), c|
      [a, b, c] if c > 0 && side.include?(a) && !side.include?(b)
    end
  end
end

def run(title, pipes, s, t)
  puts "== #{title}"
  net = FlowNet.new
  pipes.each { |a, b, c| net.add_pipe(a, b, c) }
  total, rounds = net.max_flow(s, t)
  puts "max flow #{s} -> #{t}: #{total} (#{rounds} augmenting paths)"
  used = pipes.select { |a, b, c| net.flow[[a, b]] > 0 }
  used.each do |a, b, c|
    f = net.flow[[a, b]]
    mark = f == c ? " FULL" : ""
    puts format("  %-8s -> %-8s %3d/%-3d%s", a, b, f, c, mark)
  end
  cut = net.min_cut(s)
  cut_total = cut.sum { |a, b, c| c }
  names = cut.map { |a, b, c| "#{a}->#{b}" }
  puts "  min cut (#{cut_total}): #{names.sort.join(", ")}"
  puts "  check: #{cut_total == total ? "ok" : "MISMATCH"}"
end

run("water mains", [
  ["reservoir", "pumpA", 50], ["reservoir", "pumpB", 40], ["pumpA", "pumpB", 10],
  ["pumpA", "tower", 30], ["pumpB", "tower", 20], ["pumpB", "mixer", 35],
  ["tower", "city", 45], ["mixer", "city", 30], ["mixer", "tower", 10]
], "reservoir", "city")

run("classic", [
  ["s", "a", 10], ["s", "c", 10], ["a", "b", 4], ["a", "c", 2], ["a", "d", 8],
  ["c", "d", 9], ["d", "b", 6], ["b", "t", 10], ["d", "t", 10]
], "s", "t")

run("disconnected", [["x", "y", 5], ["z", "w", 7]], "x", "w")
