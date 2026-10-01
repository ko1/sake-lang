class Taxonomy
  attr_reader :names, :index, :children, :parent, :depth, :up, :tin, :tout, :levels

  def initialize(pairs)
    @names = []
    @index = {}
    pairs.each do |child, par|
      [par, child].each do |n|
        next if index.key?(n)
        index[n] = names.size
        names << n
      end
    end
    n = names.size
    @children = Array.new(n) { [] }
    @parent = Array.new(n, -1)
    pairs.each do |child, par|
      c = index[child]
      raise ArgumentError, "#{child} has two parents" if parent[c] != -1
      parent[c] = index[par]
      children[index[par]] << c
    end
    @levels = 1
    @levels += 1 while (1 << @levels) < n
    @depth = Array.new(n, 0)
    @tin = Array.new(n, 0)
    @tout = Array.new(n, 0)
    @up = []
    roots = (0...n).select { |v| parent[v] == -1 }
    raise ArgumentError, "expected one root, found #{roots.size}" if roots.size != 1
    number(roots.first)
    lift
  end

  def id(name)
    index.fetch(name) { raise KeyError, "unknown taxon: #{name}" }
  end

  def ancestor?(a, b) = tin[a] <= tin[b] && tout[b] <= tout[a]

  def kth_ancestor(v, k)
    return nil if k > depth[v]
    levels.times { |j| v = up[j][v] if (k >> j) & 1 == 1 }
    v
  end

  def lca(a, b)
    return a if ancestor?(a, b)
    return b if ancestor?(b, a)
    (levels - 1).downto(0) do |k|
      cand = up[k][a]
      a = cand unless ancestor?(cand, b)
    end
    up[0][a]
  end

  def subtree_size(v) = (tout[v] - tin[v] + 1) / 2

  private

  # iterative DFS assigning depth and entry/exit times
  def number(root)
    clock = 0
    stack = [[root, false]]
    until stack.empty?
      v, leaving = stack.pop
      if leaving
        tout[v] = clock
        clock += 1
        next
      end
      tin[v] = clock
      clock += 1
      stack << [v, true]
      children[v].sort_by { |c| names[c] }.reverse_each do |c|
        depth[c] = depth[v] + 1
        stack << [c, false]
      end
    end
  end

  def lift
    root = parent.index(-1)
    up << parent.map { |p| p == -1 ? root : p }
    (1...levels).each do |k|
      prev = up[k - 1]
      up << prev.map { |mid| prev[mid] }
    end
  end
end

pairs = [
  ["Mammalia", "Chordata"], ["Aves", "Chordata"], ["Reptilia", "Chordata"],
  ["Carnivora", "Mammalia"], ["Primates", "Mammalia"], ["Rodentia", "Mammalia"],
  ["Felidae", "Carnivora"], ["Canidae", "Carnivora"], ["Ursidae", "Carnivora"],
  ["Felis", "Felidae"], ["Panthera", "Felidae"], ["lion", "Panthera"], ["tiger", "Panthera"],
  ["house cat", "Felis"], ["wolf", "Canidae"], ["fox", "Canidae"], ["brown bear", "Ursidae"],
  ["Hominidae", "Primates"], ["human", "Hominidae"], ["chimpanzee", "Hominidae"],
  ["mouse", "Rodentia"], ["Passeriformes", "Aves"], ["sparrow", "Passeriformes"],
  ["crow", "Passeriformes"], ["eagle", "Aves"], ["Squamata", "Reptilia"], ["gecko", "Squamata"]
]
tax = Taxonomy.new(pairs)
names = tax.names
puts "#{names.size} taxa, #{tax.levels} lifting levels"
%w[Chordata Mammalia Carnivora Panthera wolf].each do |n|
  v = tax.id(n)
  puts format("  %-10s depth %d, subtree %2d", n, tax.depth[v], tax.subtree_size(v))
end

queries = [["lion", "tiger"], ["lion", "house cat"], ["wolf", "brown bear"], ["human", "mouse"],
           ["sparrow", "gecko"], ["crow", "eagle"], ["Felidae", "lion"], ["fox", "fox"], ["lion", "unicorn"]]
queries.each do |x, y|
  a = tax.id(x)
  b = tax.id(y)
  c = tax.lca(a, b)
  dist = tax.depth[a] + tax.depth[b] - 2 * tax.depth[c]
  puts "#{x} / #{y}: common #{names[c]}, distance #{dist}"
rescue KeyError => e
  puts "#{x} / #{y}: #{e.message}"
end

lion = tax.id("lion")
lineage = (0..7).filter_map { |k| (anc = tax.kth_ancestor(lion, k)) && names[anc] }
puts "lion lineage: #{lineage.join(" < ")}"

[[%w[b a], %w[c a], %w[c b]], [%w[b a], %w[d c]]].each do |bad|
  Taxonomy.new(bad)
rescue ArgumentError => e
  puts "bad tree: #{e.message}"
end
