require "set"

def parse_friendships(text)
  adj = {}
  text.split("\n").each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    person, _, friends = line.partition(":")
    person = person.strip
    adj[person] ||= Set.new
    friends.split(",").each do |f|
      f = f.strip
      next if f.empty?
      adj[f] ||= Set.new
      adj[person] << f
      adj[f] << person
    end
  end
  adj
end

def components(adj)
  seen = Set.new
  groups = []
  adj.keys.sort.each do |start|
    next if seen.include?(start)
    group = []
    stack = [start]
    seen << start
    until stack.empty?
      cur = stack.pop
      group << cur
      adj[cur].each do |nb|
        stack << nb if seen.add?(nb)
      end
    end
    groups << group.sort
  end
  groups
end

def edge_count(adj, group)
  group.sum { |p| adj[p].size } / 2
end

def density(adj, group)
  n = group.size
  return 0.0 if n < 2
  edge_count(adj, group) * 2.0 / (n * (n - 1))
end

def most_connected(adj, group)
  group.max_by { |p| adj[p].size }
end

def suggest(adj, person)
  counts = Hash.new(0)
  adj[person].each do |f|
    adj[f].each do |ff|
      next if ff == person || adj[person].include?(ff)
      counts[ff] += 1
    end
  end
  return nil if counts.empty?
  name = counts.keys.sort.max_by { |n| counts[n] }
  [name, counts[name]]
end

text = <<~NET
  # who knows whom
  alice: bob, carol, dave
  bob: carol, erin
  carol: frank
  dave: erin
  gina: hank
  hank: ivan, judy
  judy: ivan
  kim:
  leo: mona
  erin: frank
NET

adj = parse_friendships(text)
groups = components(adj)
puts "people: #{adj.size}, groups: #{groups.size}"
groups.each_with_index do |g, i|
  hub = most_connected(adj, g)
  puts format("group %d: %-35s edges=%d density=%.2f hub=%s",
              i + 1, g.join(","), edge_count(adj, g), density(adj, g), hub)
end
loners = groups.select { |g| g.size == 1 }
puts "loners: #{loners.map(&:first).join(", ")}"
largest = groups.max_by(&:size)
puts "largest group size: #{largest.size}"

["alice", "gina", "kim", "zed"].each do |who|
  unless adj.key?(who)
    puts "#{who}: not in network"
    next
  end
  s = suggest(adj, who)
  if s
    name, common = s
    puts "#{who}: suggest #{name} (#{common} mutual)"
  else
    puts "#{who}: no suggestion"
  end
end
