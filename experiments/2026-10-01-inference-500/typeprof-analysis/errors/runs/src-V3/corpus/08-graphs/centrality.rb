def undirected(edges)
  adj = Hash.new { |h, k| h[k] = [] }
  edges.each do |a, b|
    adj[a] << b
    adj[b] << a
  end
  adj.transform_values(&:sort)
end

def bfs_distances(adj, s)
  dist = { s => 0 }
  queue = [s]
  until queue.empty?
    v = queue.shift
    adj[v].each do |w|
      next if dist.key?(w)
      dist[w] = dist[v] + 1
      queue << w
    end
  end
  dist
end

def closeness(adj, v)
  d = bfs_distances(adj, v)
  reach = d.size - 1
  return 0.0 if reach == 0
  # Wasserman-Faust correction for disconnected graphs
  total = d.values.sum
  (reach / Float(total)) * (reach / Float(adj.size - 1))
end

# Brandes' algorithm for betweenness centrality.
def betweenness(adj)
  cb = Hash.new(0.0)
  adj.each_key do |s|
    stack = []
    preds = Hash.new { |h, k| h[k] = [] }
    sigma = Hash.new(0)
    sigma[s] = 1
    dist = { s => 0 }
    queue = [s]
    until queue.empty?
      v = queue.shift
      stack << v
      adj[v].each do |w|
        unless dist.key?(w)
          dist[w] = dist[v] + 1
          queue << w
        end
        if dist[w] == dist[v] + 1
          sigma[w] += sigma[v]
          preds[w] << v
        end
      end
    end
    delta = Hash.new(0.0)
    until stack.empty?
      w = stack.pop
      preds[w].each do |v|
        delta[v] += sigma[v] / Float(sigma[w]) * (1.0 + delta[w])
      end
      cb[w] += delta[w] if w != s
    end
  end
  # each undirected path was counted from both ends
  cb.transform_values { |x| x / 2.0 }
end

def clustering(adj, v)
  ns = adj[v]
  k = ns.size
  return 0.0 if k < 2
  links = ns.combination(2).count { |a, b| adj[a].include?(b) }
  2.0 * links / (k * (k - 1))
end

edges = [
  ["ann", "bea"], ["ann", "cal"], ["bea", "cal"], ["cal", "dov"], ["dov", "eli"],
  ["eli", "fin"], ["eli", "gil"], ["fin", "gil"], ["gil", "hus"], ["hus", "ida"],
  ["ida", "jon"], ["jon", "hus"], ["dov", "kai"], ["lux", "mia"]
]
adj = undirected(edges)
bc = betweenness(adj)
names = adj.keys.sort
puts format("%-5s %3s %6s %7s %6s", "who", "deg", "close", "between", "clust")
names.each do |n|
  puts format("%-5s %3d %6.3f %7.2f %6.2f", n, adj[n].size, closeness(adj, n),
              bc.fetch(n, 0.0), clustering(adj, n))
end
broker = names.max_by { |n| bc.fetch(n, 0.0) }
central = names.max_by { |n| closeness(adj, n) }
puts "top broker: #{broker}, most central: #{central}"
avg_clust = names.sum { |n| clustering(adj, n) } / names.size
puts format("average clustering: %.3f", avg_clust)
far = names.map { |n| bfs_distances(adj, n).values.max }.max
puts "diameter (within components): #{far}"
