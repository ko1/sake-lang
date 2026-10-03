require "tsort"

# 1. Ruby's doc example: Hash includes TSort
class Hash
  include TSort
  alias tsort_each_node each_key
  def tsort_each_child(node, &block) = fetch(node).each(&block)
end

p({1 => [2, 3], 2 => [3], 3 => [], 4 => []}.tsort)
p({1 => [2, 3], 2 => [3], 3 => [], 4 => []}.tsort)
p({1 => [2], 2 => [3, 4], 3 => [2], 4 => []}.strongly_connected_components)
g = {1 => [2], 2 => [3, 4], 3 => [2], 4 => []}
g.each_strongly_connected_component { |c| p(c) }
p(g.each_strongly_connected_component_from(2) { |c| p(c) })
{1 => [2, 3], 2 => [3], 3 => [], 4 => []}.tsort_each { |n| puts("node #{n}") }
p({}.tsort)
begin
  {1 => [2], 2 => [3, 4], 3 => [2], 4 => []}.tsort
rescue TSort::Cyclic => e
  puts("Cyclic: #{e.message}")
end
begin
  {:a => [:a]}.tsort
rescue TSort::Cyclic => e
  puts("Cyclic: #{e.message}")
end
p({:a => [:a]}.strongly_connected_components)
begin
  {1 => [9]}.tsort
rescue KeyError => e
  p(e.message.end_with?("key not found: 9"))
end

# 2. A type of your own includes TSort
class Build
  include TSort
  def initialize(names, deps) = (@names, @deps = names, deps)
  def tsort_each_node(&b) = @names.each(&b)
  def tsort_each_child(name, &b) = (@deps[name] || []).each(&b)
end

b = Build.new(["app", "lib", "test", "util", "docs"],
              {"app" => ["lib", "util"], "lib" => ["util"], "test" => ["app", "lib"]})
p(b.tsort)
p(b.strongly_connected_components)
puts(b.tsort.join(" -> "))

# 3. A Hash graph without including anything (Ruby: TSort's module functions with callables)
def each_child_of(h) = lambda { |n, &blk| (h[n] || []).each(&blk) }
def tsort_hash(h) = TSort.tsort(h.method(:each_key), each_child_of(h))
p(tsort_hash({"c" => ["b"], "b" => ["a"], "a" => []}))
p(tsort_hash({"c" => ["b"], "b" => ["a"]}))
p(TSort.strongly_connected_components((h = {1 => [2], 2 => [1, 3], 3 => [4], 4 => [3], 5 => []}).method(:each_key), each_child_of(h)))
TSort.tsort_each((h = {[0, 0] => [[0, 1]], [0, 1] => []}).method(:each_key), each_child_of(h)) { |n| p(n) }
TSort.each_strongly_connected_component((h = {:x => [:y], :y => [:x]}).method(:each_key), each_child_of(h)) { |c| p(c) }
begin
  tsort_hash({"a" => ["b"], "b" => ["c"], "c" => ["a"]})
rescue TSort::Cyclic => e
  puts("Cyclic: #{e.message}")
end
p(tsort_hash({}))

# a long chain
h = {}
(0...1000).each { |i| h[i] = [i + 1] }
order = tsort_hash(h)
p([order.size, order.first, order.last])
