class OrgTree
  attr_reader :names, :ids, :depth, :up, :levels, :children

  def initialize(names, ids, depth, up, levels, children)
    @names = names
    @ids = ids
    @depth = depth
    @up = up
    @levels = levels
    @children = children
  end

  def self.build(reports)
    names = []
    ids = {}
    boss_of = {}
    reports.each do |line|
      emp, boss = line.split("<").map(&:strip)
      [emp, boss].each do |n|
        next if !n     || ids.key?(n)
        ids[n] = names.size
        names << n
      end
      boss_of[ids[emp]] = ids[boss] if boss
    end
    n = names.size
    levels = 1
    levels += 1 while (1 << levels) < n
    children = Array.new(n) { [] }
    boss_of.each { |e, b| children[b] << e }
    roots = (0...n).reject { |i| boss_of.key?(i) }
    depth = Array.new(n, 0)
    up = Array.new(levels) { Array.new(n) { |i| boss_of.fetch(i, i) } }
    queue = roots.dup
    until queue.empty?
      v = queue.shift
      children[v].each do |c|
        depth[c] = depth[v] + 1
        queue << c
      end
    end
    (1...levels).each do |k|
      n.times { |i| up[k][i] = up[k - 1][up[k - 1][i]] }
    end
    new(names, ids, depth, up, levels, children)
  end

  def lift(v, steps)
    @levels.times do |k|
      v = @up[k][v] if (steps >> k) & 1 == 1
    end
    v
  end

  def lca(a, b)
    a, b = b, a if @depth[a] < @depth[b]
    a = lift(a, @depth[a] - @depth[b])
    return a if a == b
    (@levels - 1).downto(0) do |k|
      if @up[k][a] != @up[k][b]
        a = @up[k][a]
        b = @up[k][b]
      end
    end
    return nil if @up[0][a] == a
    @up[0][a]
  end

  def team_size(v) = 1 + @children[v].sum { |c| team_size(c) }

  def chain(v)
    out = [@names[v]]
    while @up[0][v] != v
      v = @up[0][v]
      out << @names[v]
    end
    out
  end
end

def query(t, x, y)
  a = t.ids[x]
  b = t.ids[y]
  return "#{x} / #{y}: unknown person" if !a     || !b    
  c = t.lca(a, b)
  return "#{x} / #{y}: different organizations" if !c    
  hops = t.depth[a] + t.depth[b] - 2 * t.depth[c]
  "#{x} / #{y}: meet at #{t.names[c]}, #{hops} hops"
end

reports = [
  "cto < ceo", "cfo < ceo", "vp_eng < cto", "vp_ops < cto", "lead_web < vp_eng",
  "lead_db < vp_eng", "ana < lead_web", "raj < lead_web", "lin < lead_db", "olu < lead_db",
  "max < vp_ops", "ivy < max", "controller < cfo", "pia < controller",
  "founder", "intern < ana", "zoe < partner_ceo"
]
t = OrgTree.build(reports)
names = t.names
puts "#{names.size} people, #{t.levels} lifting levels"
deepest = (0...names.size).max_by { |i| t.depth[i] }
puts "deepest: #{t.chain(deepest).join(" < ")}"
["ceo", "cto", "vp_eng", "cfo", "founder"].each do |n|
  puts format("  team of %-8s %2d", n, t.team_size(t.ids[n]))
end
[["ana", "raj"], ["ana", "lin"], ["intern", "ivy"], ["pia", "olu"],
 ["cto", "lin"], ["ceo", "ceo"], ["zoe", "ceo"], ["ana", "bob"]].each do |x, y|
  puts query(t, x, y)
end
