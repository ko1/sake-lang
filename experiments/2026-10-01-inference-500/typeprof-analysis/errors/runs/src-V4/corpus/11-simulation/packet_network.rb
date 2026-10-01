class Packet
  attr_reader :id, :src, :dst, :born, :hops
  attr_accessor :ttl

  def initialize(id, src, dst, born, ttl)
    @id = id
    @src = src
    @dst = dst
    @born = born
    @ttl = ttl
    @hops = [src]
  end
end

class Link
  attr_reader :a, :b, :delay
  attr_accessor :up

  def initialize(a, b, delay)
    @a = a
    @b = b
    @delay = delay
    @up = true
  end
end

class Router
  attr_reader :name, :queue, :limit
  attr_accessor :dropped, :forwarded

  def initialize(name, limit)
    @name = name
    @queue = []
    @limit = limit
    @dropped = 0
    @forwarded = 0
  end

  def accept(pkt)
    if @queue.size < @limit
      @queue << pkt
    else
      @dropped += 1
    end
  end
end

class InFlight
  attr_reader :packet, :to, :arrives

  def initialize(packet, to, arrives)
    @packet = packet
    @to = to
    @arrives = arrives
  end
end

module Routing
  module_function

  def neighbors(links, node)
    out = []
    links.each do |l|
      next unless l.up
      out << [l.b, l.delay] if l.a == node
      out << [l.a, l.delay] if l.b == node
    end
    out
  end

  def next_hops(links, nodes, source)
    dist = { source => 0 }
    first = {}
    todo = nodes.dup
    until todo.empty?
      u = todo.select { |n| dist[n] }.min_by { |n| dist[n] }
      break if !u    
      todo.delete(u)
      neighbors(links, u).each do |v, w|
        alt = dist[u] + w
        if !dist[v]     || alt < dist[v]
          dist[v] = alt
          first[v] = u == source ? v : first[u]
        end
      end
    end
    first
  end

  def table(links, nodes)
    nodes.to_h { |n| [n, next_hops(links, nodes, n)] }
  end
end

def link_between(links, a, b)
  links.find { |l| (l.a == a && l.b == b) || (l.a == b && l.b == a) }
end

nodes = ["A", "B", "C", "D", "E", "F"]
links = [
  Link.new("A", "B", 1), Link.new("B", "C", 1), Link.new("C", "D", 2),
  Link.new("A", "E", 2), Link.new("E", "F", 2), Link.new("F", "D", 1),
  Link.new("B", "E", 1), Link.new("C", "F", 3)
]
routers = nodes.to_h { |n| [n, Router.new(n, n == "C" ? 3 : 5)] }
routes = Routing.table(links, nodes)
puts "A routes: #{routes["A"].keys.sort.map { |d| "#{d}->#{routes["A"][d]}" }.join(" ")}"

flows = [["A", "D", 1], ["E", "C", 2], ["B", "F", 3], ["F", "A", 4], ["D", "B", 5]]
events = { 12 => ["C", "D", false], 25 => ["C", "D", true] }
in_flight = []
delivered = []
expired = []
next_id = 1
40.times do |t|
  if (ev = events[t])
    a, b, up = ev
    link_between(links, a, b).up = up
    routes = Routing.table(links, nodes)
    puts "t=#{t} link #{a}-#{b} #{up ? "restored" : "failed"}; A->D now via #{routes["A"]["D"]}"
  end
  if t < 30
    flows.each do |src, dst, every|
      next unless t % every == 0
      routers[src].accept(Packet.new(next_id, src, dst, t, 6))
      next_id += 1
    end
  end
  arrived, in_flight = in_flight.partition { |f| f.arrives == t }
  arrived.each do |f|
    pkt = f.packet
    pkt.hops << f.to
    if f.to == pkt.dst
      delivered << [pkt, t]
    else
      routers[f.to].accept(pkt)
    end
  end
  routers.each do |name, r|
    pkt = r.queue.shift
    next if !pkt    
    pkt.ttl -= 1
    if pkt.ttl == 0
      expired << pkt
      next
    end
    hop = routes[name][pkt.dst]
    if !hop    
      r.dropped += 1
      next
    end
    r.forwarded += 1
    in_flight << InFlight.new(pkt, hop, t + link_between(links, name, hop).delay)
  end
end

puts "--- routers"
routers.each do |name, r|
  puts format("%s forwarded %3d dropped %2d queued %d", name, r.forwarded, r.dropped, r.queue.size)
end
latencies = delivered.map { |pkt, at| at - pkt.born }
puts format("delivered %d, expired %d, in flight %d, avg latency %.2f, max %d",
  delivered.size, expired.size, in_flight.size, latencies.sum / latencies.size.to_f, latencies.max)
by_flow = delivered.group_by { |pkt, _at| "#{pkt.src}->#{pkt.dst}" }
by_flow.keys.sort.each do |k|
  rows = by_flow[k]
  paths = rows.map { |pkt, _at| pkt.hops.join }.tally
  puts "#{k}: #{rows.size} delivered, paths #{paths.map { |p, n| "#{p}x#{n}" }.join(" ")}"
end
