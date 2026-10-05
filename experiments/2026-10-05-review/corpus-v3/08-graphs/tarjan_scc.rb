require "set"

class Tarjan
  def self.run(graph) = new(graph).run

  def initialize(graph)
    @graph = graph
    @index = {}
    @low = {}
    @on_stack = Set.new
    @stack = []
    @counter = 0
    @sccs = []
  end

  def run
    @graph.keys.sort.each do |v|
      visit(v) unless @index.key?(v)
    end
    @sccs
  end

  private

  def visit(v)
    @index[v] = @low[v] = @counter
    @counter += 1
    @stack << v
    @on_stack << v
    @graph.fetch(v, []).each do |w|
      if !@index.key?(w)
        visit(w)
        @low[v] = @low[w] if @low[w] < @low[v]
      elsif @on_stack.include?(w)
        @low[v] = @index[w] if @index[w] < @low[v]
      end
    end
    return unless @low[v] == @index[v]
    comp = []
    loop do
      w = @stack.pop
      @on_stack.delete(w)
      comp << w
      break if w == v
    end
    @sccs << comp.sort
  end
end

def parse(text)
  graph = {}
  text.each_line do |line|
    from, _, rest = line.strip.partition(" uses ")
    next if from.empty?
    graph[from] ||= []
    rest.split(/,\s*/).each do |to|
      graph[from] << to
      graph[to] ||= []
    end
  end
  graph
end

def condense(graph, sccs)
  owner = {}
  sccs.each_with_index { |comp, i| comp.each { |v| owner[v] = i } }
  links = Set.new
  graph.each do |v, outs|
    outs.each do |w|
      a = owner[v]
      b = owner[w]
      links << [a, b] if a != b
    end
  end
  links
end

text = <<~DEPS
  app uses router, view, db
  router uses controller
  controller uses model, view
  model uses db, validator
  validator uses model
  view uses helper, template
  template uses helper
  helper uses view
  db uses pool
  pool uses logger
  logger uses config
  config uses logger
  cli uses app, config
DEPS

graph = parse(text)
sccs = Tarjan.run(graph)
puts "modules: #{graph.size}, components: #{sccs.size}"
# Tarjan emits components in reverse topological order: dependencies first.
sccs.each_with_index do |comp, i|
  tag = comp.size > 1 ? "CYCLE" : "ok"
  puts format("%2d %-5s %s", i, tag, comp.join(" "))
end
cycles = sccs.select { |c| c.size > 1 }
puts "modules caught in cycles: #{cycles.sum(&:size)}"
links = condense(graph, sccs)
puts "links between components: #{links.size}"
links.to_a.sort_by { |a, b| a * 100 + b }.each do |a, b|
  puts "  #{sccs[a].join("+")} -> #{sccs[b].join("+")}"
end
