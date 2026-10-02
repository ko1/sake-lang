# usage: ruby tools/rewrite.rb [--all] IN.rb OUT.rb
# Rewrites "trigger blocks" { |a, b| ... } into { |e__N| a, b = e__N; ... } (same Ruby semantics for a
# method that yields ONE value). Trigger block = >= 2 plain params, call is one of METHODS, and (unless --all)
# some value-producing leaf of the block's result is a bare read of one of its params.
# Prints the number of rewritten blocks to stderr.
require "prism"
all = ARGV.delete("--all")
METHODS = %i[max_by min_by sort_by filter_map flat_map to_h map min max sum group_by]
src, out = ARGV
code = File.read(src)
edits = []
leaves = ->(n) {
  case n
  when nil then []
  when Prism::StatementsNode then leaves[n.body.last]
  when Prism::ParenthesesNode then leaves[n.body]
  when Prism::IfNode then leaves[n.statements] + leaves[n.subsequent]
  when Prism::UnlessNode then leaves[n.statements] + leaves[n.else_clause]
  when Prism::ElseNode then leaves[n.statements]
  when Prism::CaseNode then n.conditions.flat_map { leaves[_1.statements] } + leaves[n.else_clause]
  when Prism::CaseMatchNode then n.conditions.flat_map { leaves[_1.statements] } + leaves[n.else_clause]
  else [n]
  end
}
walk = ->(n) {
  if n.is_a?(Prism::CallNode) && METHODS.include?(n.name) && n.block.is_a?(Prism::BlockNode) &&
     (bp = n.block.parameters).is_a?(Prism::BlockParametersNode) && (ps = bp.parameters) &&
     ps.requireds.size >= 2 && ps.optionals.empty? && ps.rest.nil? && ps.posts.empty? && ps.keywords.empty? && bp.locals.empty?
    names = ps.requireds.flat_map { _1.is_a?(Prism::RequiredParameterNode) ? [_1.name] : [] }
    hit = leaves[n.block.body].any? { _1.is_a?(Prism::LocalVariableReadNode) && _1.depth == 0 && names.include?(_1.name) }
    if all || hit
      i = edits.size
      lhs = code.byteslice(ps.location.start_offset, ps.location.length)
      edits << [bp.location.start_offset, bp.location.length, "|e__#{i}| #{lhs} = e__#{i};"]
    end
  end
  n.compact_child_nodes.each { walk[_1] }
}
walk[Prism.parse(code).value]
edits.sort_by { -_1[0] }.each { |off, len, s| code = code.byteslice(0, off) + s + code.byteslice(off + len..) }
File.write(out, code)
$stderr.puts edits.size
