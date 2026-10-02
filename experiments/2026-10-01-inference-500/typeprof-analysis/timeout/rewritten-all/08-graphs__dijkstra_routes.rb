require "set"

class MinHeap
  def initialize
    @items = []
  end

  def empty? = @items.empty?
  def size = @items.size

  def push(prio, value)
    @items << [prio, value]
    i = @items.size - 1
    while i > 0
      parent = (i - 1) / 2
      break if prio_at(parent) <= prio_at(i)
      swap(i, parent)
      i = parent
    end
    self
  end

  def pop
    return nil if @items.empty?
    top = @items[0]
    last = @items.pop
    unless @items.empty?
      @items[0] = last
      sift_down(0)
    end
    top
  end

  private

  def prio_at(i) = @items[i][0]

  def swap(i, j)
    @items[i], @items[j] = @items[j], @items[i]
  end

  def sift_down(i)
    n = @items.size
    loop do
      smallest = i
      l = 2 * i + 1
      r = l + 1
      smallest = l if l < n && prio_at(l) < prio_at(smallest)
      smallest = r if r < n && prio_at(r) < prio_at(smallest)
      break if smallest == i
      swap(i, smallest)
      i = smallest
    end
  end
end

def build_graph(roads)
  graph = {}
  roads.each do |a, b, km|
    (graph[a] ||= []) << [b, km]
    (graph[b] ||= []) << [a, km]
  end
  graph
end

def dijkstra(graph, source)
  dist = { source => 0 }
  prev = {}
  done = Set.new
  heap = MinHeap.new
  heap.push(0, source)
  pops = 0
  until heap.empty?
    d, city = heap.pop
    pops += 1
    next if done.include?(city)
    done << city
    graph.fetch(city, []).each do |nb, km|
      nd = d + km
      old = dist[nb]
      if old.nil? || nd < old
        dist[nb] = nd
        prev[nb] = city
        heap.push(nd, nb)
      end
    end
  end
  [dist, prev, pops]
end

def path_to(prev, source, target)
  path = [target]
  cur = target
  while cur != source
    cur = prev[cur]
    return nil if cur.nil?
    path.unshift(cur)
  end
  path
end

roads = [
  ["Amsterdam", "Utrecht", 45], ["Amsterdam", "Haarlem", 20], ["Haarlem", "Leiden", 33],
  ["Leiden", "Den Haag", 19], ["Den Haag", "Rotterdam", 27], ["Utrecht", "Rotterdam", 61],
  ["Utrecht", "Arnhem", 64], ["Utrecht", "Den Bosch", 55], ["Rotterdam", "Breda", 50],
  ["Breda", "Den Bosch", 48], ["Den Bosch", "Eindhoven", 35], ["Eindhoven", "Maastricht", 87],
  ["Arnhem", "Nijmegen", 20], ["Nijmegen", "Den Bosch", 47], ["Amsterdam", "Zwolle", 105],
  ["Zwolle", "Arnhem", 68], ["Zwolle", "Groningen", 103], ["Leiden", "Utrecht", 56],
  ["Texel", "Den Helder", 4]
]
graph = build_graph(roads)
puts "cities: #{graph.size}, roads: #{roads.size}"

source = "Amsterdam"
dist, prev, pops = dijkstra(graph, source)
puts "heap pops: #{pops}"
sorted = graph.keys.sort_by { |c| [dist.fetch(c, 1_000_000), c] }
sorted.each do |city|
  d = dist[city]
  if d.nil?
    puts format("%-11s unreachable", city)
  else
    path = path_to(prev, source, city)
    puts format("%-11s %4d km  %s", city, d, path.join(" > "))
  end
end

far_city, far_d = dist.max_by { |e__0| c, d = e__0; d }
puts "farthest: #{far_city} (#{far_d} km)"
avg = dist.values.sum / Float(dist.size)
puts "mean distance: #{avg.round(1)} km"
