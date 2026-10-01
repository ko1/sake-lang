def stops = ["Mill", "Park", "Quay", "Rise", "Stn", "Uni", "Vale", "Wharf"]

def legs
  [
    ["Mill", "Park", 4.5], ["Park", "Stn", 3.0], ["Stn", "Quay", 6.5],
    ["Quay", "Rise", 2.0], ["Rise", "Uni", 5.5], ["Uni", "Stn", 4.0],
    ["Mill", "Uni", 12.0], ["Park", "Quay", 11.0], ["Vale", "Mill", 7.0]
  ]
end

def build_matrix(names, edges)
  n = names.size
  index = names.each_with_index.to_h
  dist = Array.new(n) { |i| Array.new(n) { |j| i == j ? 0.0 : nil } }
  nxt = Array.new(n) { |i| Array.new(n) { |j| i == j ? j : nil } }
  edges.each do |a, b, w|
    i = index[a]
    j = index[b]
    # lines run both ways
    dist[i][j] = dist[j][i] = w
    nxt[i][j] = j
    nxt[j][i] = i
  end
  [dist, nxt]
end

def floyd!(dist, nxt)
  n = dist.size
  n.times do |k|
    n.times do |i|
      ik = dist[i][k]
      next if !ik    
      n.times do |j|
        kj = dist[k][j]
        next if !kj    
        cur = dist[i][j]
        if !cur     || ik + kj < cur
          dist[i][j] = ik + kj
          nxt[i][j] = nxt[i][k]
        end
      end
    end
  end
end

def path(nxt, names, i, j)
  return nil if !nxt[i][j]    
  out = [names[i]]
  while i != j
    i = nxt[i][j]
    out << names[i]
  end
  out
end

def cell(d) = !d     ? "   -" : format("%4.1f", d)

names = stops
dist, nxt = build_matrix(names, legs)
floyd!(dist, nxt)

puts "      " + names.map { |s| s.rjust(5) }.join
names.each_with_index do |s, i|
  puts s.ljust(5) + " " + dist[i].map { |d| " " + cell(d) }.join
end

# eccentricity over the stops each stop can reach; isolated stops are left out
eccentricity = (0...names.size).map { |i| dist[i].compact.max }
isolated = (0...names.size).select { |i| dist[i].compact.size == 1 }
candidates = (0...names.size).reject { |i| isolated.include?(i) }
center = candidates.min_by { |i| eccentricity[i] }
if center
  puts "best hub: #{names[center]} (worst trip #{eccentricity[center]} min)"
  puts "diameter: #{eccentricity.max} min"
end
puts "isolated: #{isolated.map { |i| names[i] }.join(", ")}"

[["Vale", "Rise"], ["Mill", "Quay"], ["Uni", "Park"], ["Wharf", "Mill"]].each do |from, to|
  i = names.index(from)
  j = names.index(to)
  route = path(nxt, names, i, j)
  if route
    puts "#{from} to #{to}: #{dist[i][j]} min via #{route.join(", ")}"
  else
    puts "#{from} to #{to}: no route"
  end
end

total = 0.0
pairs = 0
names.size.times do |i|
  (i + 1).upto(names.size - 1) do |j|
    d = dist[i][j]
    next unless d
    total += d
    pairs += 1
  end
end
puts format("average trip over %d pairs: %.2f min", pairs, total / pairs)
