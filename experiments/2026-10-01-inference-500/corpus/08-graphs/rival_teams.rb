def other(side) = side == :left ? :right : :left

def build(pairs)
  adj = Hash.new { |h, k| h[k] = [] }
  pairs.each do |a, b|
    adj[a] << b
    adj[b] << a
  end
  adj
end

def ancestors(parent, x)
  path = [x]
  while (up = parent[x])
    path << up
    x = up
  end
  path
end

# Walk back from both endpoints of a conflicting edge to their common ancestor.
def odd_cycle(parent, a, b)
  path_a = ancestors(parent, a)
  path_b = ancestors(parent, b)
  common = path_a.find { |x| path_b.include?(x) }
  left = path_a.take_while { |x| x != common }
  right = path_b.take_while { |x| x != common }
  left + [common] + right.reverse
end

def split_teams(adj)
  side = {}
  parent = {}
  adj.keys.sort.each do |root|
    next if side.key?(root)
    side[root] = :left
    queue = [root]
    until queue.empty?
      cur = queue.shift
      adj[cur].each do |nb|
        if side.key?(nb)
          return { ok: false, cycle: odd_cycle(parent, cur, nb), side: side } if side[nb] == side[cur]
        else
          side[nb] = other(side[cur])
          parent[nb] = cur
          queue << nb
        end
      end
    end
  end
  { ok: true, cycle: [], side: side }
end

def show(title, pairs)
  puts "== #{title}: #{pairs.size} rivalries"
  adj = build(pairs)
  result = split_teams(adj)
  case result
  in { ok: true, side: }
    left, right = side.keys.sort.partition { |k| side[k] == :left }
    puts "  team A: #{left.join(" ")}"
    puts "  team B: #{right.join(" ")}"
    puts "  imbalance: #{(left.size - right.size).abs}"
  in { ok: false, cycle: }
    puts "  impossible, odd cycle of #{cycle.size}: #{cycle.join(" -> ")}"
  end
end

show("office", [
  ["ann", "bo"], ["bo", "cy"], ["cy", "dee"], ["dee", "ann"],
  ["eve", "fay"], ["fay", "gus"], ["ann", "hal"]
])
show("triangle", [["x", "y"], ["y", "z"], ["z", "x"]])
show("league", [
  ["lions", "tigers"], ["tigers", "bears"], ["bears", "wolves"], ["wolves", "hawks"],
  ["hawks", "eagles"], ["eagles", "lions"], ["owls", "lions"], ["bears", "owls"]
])
show("pentagon", [["p1", "p2"], ["p2", "p3"], ["p3", "p4"], ["p4", "p5"], ["p5", "p1"]])
