# frozen_string_literal: true

# Where a Sake program dispatches by hand: a `case x in T ...` or an `if x in T` chain whose branches
# call the same operation on x through different types (`in Array then Array.size(x) in String then
# String.size(x)`). Each such operation is one place `(Array|String).size(x)` could replace.
# Also counts calls through a module's dispatch (`Shape.area(s)` where Shape is a module of the program).
# usage: ruby sake_dispatch.rb FILE.sake...   (prints one JSON object per program)
require "json"
require "prism"

def calls_on(node, var, out)
  return unless node
  if node.is_a?(Prism::CallNode) && node.receiver.is_a?(Prism::ConstantReadNode) &&
     (a = node.arguments&.arguments&.first).is_a?(Prism::LocalVariableReadNode) && a.name == var
    out << [node.receiver.name.to_s, node.name.to_s]
  end
  node.compact_child_nodes.each { calls_on(_1, var, out) }
end

# [[type names of the branch, calls on var in the branch]] for a case/in or an if-in chain on var.
def branches(node)
  case node
  when Prism::CaseMatchNode
    return unless node.predicate.is_a?(Prism::LocalVariableReadNode)
    var = node.predicate.name
    bs = node.conditions.map do |c|
      types = pattern_types(c.pattern)
      calls = []
      calls_on(c.statements, var, calls)
      [types, calls]
    end
    [var, bs]
  when Prism::IfNode
    pr = node.predicate
    return unless pr.is_a?(Prism::MatchPredicateNode) && pr.value.is_a?(Prism::LocalVariableReadNode)
    var = pr.value.name
    bs = []
    cur = node
    while cur.is_a?(Prism::IfNode) && cur.predicate.is_a?(Prism::MatchPredicateNode) && cur.predicate.value.is_a?(Prism::LocalVariableReadNode) && cur.predicate.value.name == var
      calls = []
      calls_on(cur.statements, var, calls)
      bs << [pattern_types(cur.predicate.pattern), calls]
      cur = cur.subsequent
    end
    bs.size >= 2 ? [var, bs] : nil
  end
end

def pattern_types(pat)
  case pat
  when Prism::ConstantReadNode then [pat.name.to_s]
  when Prism::AlternationPatternNode then pattern_types(pat.left) + pattern_types(pat.right)
  else []
  end
end

ARGV.each do |path|
  root = Prism.parse(File.read(path)).value
  modules = []
  root.breadth_first_search { modules << _1.constant_path.slice if _1.is_a?(Prism::ModuleNode); false }
  sites = []
  module_calls = 0
  walk = lambda do |n|
    if (b = branches(n))
      var, bs = b
      by_op = Hash.new { |h, k| h[k] = [] }
      bs.each { |types, calls| calls.each { |t, op| by_op[op] << t if types.include?(t) } }
      by_op.each do |op, ts|
        sites << { line: n.location.start_line, var:, op:, types: ts.uniq } if ts.uniq.size >= 2
      end
    end
    module_calls += 1 if n.is_a?(Prism::CallNode) && n.receiver.is_a?(Prism::ConstantReadNode) && modules.include?(n.receiver.name.to_s)
    n.compact_child_nodes.each { walk.(_1) }
  end
  walk.(root)
  puts JSON.generate(path:, manual: sites, module_calls:)
end
