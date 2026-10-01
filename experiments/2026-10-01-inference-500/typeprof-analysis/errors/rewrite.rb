# Column-preserving source rewrites for the counterfactual runs (never applied to the corpus itself).
#   nilq : `E.nil?` / `E&.nil?` / `E == nil` -> `!E` and `E != nil` -> `!!E`, padded with spaces to
#          the original length, so that TypeProf's truthiness narrowing applies.
#   acond: `if (v = E)` / `while (v = E)` / `... unless (v = E)` -> `... (v = E) && v`, only when the
#          predicate ends its line (so no later column on that line moves).
# usage (library): Rewrite.apply(src, %i[nilq acond]) -> [new_src, {nilq: n, acond: n}]
require "prism"

module Rewrite
  module_function

  def apply(src, kinds)
    edits = [] # [start_byte, end_byte, text]
    stats = Hash.new(0)
    walk = lambda do |n|
      return unless n
      if kinds.include?(:nilq) && n.is_a?(Prism::CallNode) && n.receiver && single_line?(n)
        recv = n.receiver.slice
        if n.name == :nil? && n.arguments.nil? && n.block.nil?
          edits << [n.location.start_offset, n.location.end_offset, "!#{paren(n.receiver)}"]; stats[:nilq] += 1
        elsif %i[== !=].include?(n.name) && n.arguments&.arguments&.size == 1 && n.arguments.arguments[0].is_a?(Prism::NilNode)
          edits << [n.location.start_offset, n.location.end_offset, "#{n.name == :== ? "!" : "!!"}#{paren(n.receiver)}"]; stats[:nilq] += 1
        end
      end
      if kinds.include?(:acond) && [Prism::IfNode, Prism::UnlessNode, Prism::WhileNode, Prism::UntilNode].any? { n.is_a?(_1) }
        pr = n.predicate
        w = pr.is_a?(Prism::ParenthesesNode) && pr.body.is_a?(Prism::StatementsNode) && pr.body.body.size == 1 ? pr.body.body[0] : nil
        if w.is_a?(Prism::LocalVariableWriteNode) && rest_of_line_blank?(src, pr.location.end_offset)
          edits << [pr.location.end_offset, pr.location.end_offset, " && #{w.name}"]; stats[:acond] += 1
        end
      end
      n.compact_child_nodes.each { walk.(_1) }
    end
    walk.(Prism.parse(src).value)
    out = src.b.dup
    edits.sort_by { -_1[0] }.each do |s, e, text|
      text = text.ljust(e - s) if e > s
      raise "rewrite longer than original" if e > s && text.bytesize > e - s
      out[s...e] = text.b
    end
    [out.force_encoding(src.encoding), stats]
  end

  def single_line?(n) = n.location.start_line == n.location.end_line

  # `!` binds looser than a method call but tighter than binary operators.
  def paren(r)
    simple = r.is_a?(Prism::LocalVariableReadNode) || r.is_a?(Prism::InstanceVariableReadNode) ||
             r.is_a?(Prism::ParenthesesNode) || (r.is_a?(Prism::CallNode) && (r.name.match?(/\A[a-z_]\w*[?!]?\z/) || r.name == :[]))
    simple ? r.slice : "(#{r.slice})"
  end

  def rest_of_line_blank?(src, off)
    rest = src.byteslice(off, src.bytesize - off)
    rest.match?(/\A[ \t]*(#.*)?(\n|\z)/)
  end
end
