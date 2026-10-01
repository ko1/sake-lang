# A friendship graph as a Hash of Sets: components, BFS distances, mutual friends, suggestions.

def build_graph(edges)
  g = Hash.new { |h, k| h[k] = Set[] }
  edges.each do |a, b|
    g[a] << b
    g[b] << a
  end
  g
end

def bfs(g, start)
  dist = {start => 0}
  queue = [start]
  until queue.empty?
    node = queue.shift
    g[node].sort.each do |nb|
      next if dist.key?(nb)
      dist[nb] = dist[node] + 1
      queue << nb
    end
  end
  dist
end

def components(g)
  seen = Set[]
  comps = []
  g.keys.sort.each do |node|
    next if seen.include?(node)
    comp = bfs(g, node).keys.to_set
    seen.merge(comp)
    comps << comp
  end
  comps
end

def suggestions(g, person)
  friends = g[person]
  counts = Hash.new(0)
  friends.each do |f|
    g[f].each { |ff| counts[ff] += 1 unless ff == person || friends.include?(ff) }
  end
  counts.sort_by { |name, n| [-n, name] }
end

edges = [
  ["ana", "ben"], ["ana", "cai"], ["ben", "cai"], ["ben", "dee"], ["cai", "eli"],
  ["dee", "eli"], ["eli", "fox"], ["fox", "gil"], ["dee", "fox"],
  ["hana", "ivo"], ["ivo", "jun"], ["kit", "kit2"]
]
g = build_graph(edges)

puts "people: #{g.size}, friendships: #{edges.size}"
degree = g.transform_values(&:size)
most = degree.max_by { |n, d| d }
puts "most connected: #{most[0]} (#{most[1]})"
hist = degree.values.tally
puts "degree histogram: #{hist.keys.sort.map { |d| "#{d}:#{hist[d]}" }.join(" ")}"

comps = components(g)
puts "components: #{comps.size}"
comps.sort_by { |c| -c.size }.each { |c| puts "  #{c.sort.join(" ")}" }

dist = bfs(g, "ana")
puts "distances from ana:"
by_d = dist.keys.group_by { |n| dist[n] }
by_d.keys.sort.each { |d| puts "  #{d}: #{by_d[d].sort.join(", ")}" }
unreachable = g.keys.to_set - dist.keys.to_set
puts "  unreachable: #{unreachable.size}"
p dist["hana"]

puts "mutual friends:"
[["ana", "dee"], ["cai", "fox"], ["ana", "hana"]].each do |a, b|
  m = (g[a] & g[b]).sort
  puts "  #{a}/#{b}: #{m.empty? ? "-" : m.join(",")}"
end

puts "suggestions:"
["ana", "gil", "jun"].each do |who|
  s = suggestions(g, who).take(3)
  puts "  #{who}: #{s.map { |name, n| "#{name}(#{n})" }.join(" ")}"
end

triangles = Set[]
g.each do |a, ns|
  ns.sort.combination(2).each do |b, c|
    triangles << [a, b, c].sort.join("-") if g[b].include?(c)
  end
end
puts "triangles: #{triangles.sort.join(" ")}"
leaves = degree.select { |n, d| d == 1 }.keys.sort
puts "leaves: #{leaves.join(" ")}"
