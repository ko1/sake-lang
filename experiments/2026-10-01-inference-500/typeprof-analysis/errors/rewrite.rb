# Column-preserving source rewrites for the counterfactual runs (never applied to the corpus itself).
#   nilq : `E.nil?` / `E&.nil?` / `E == nil` -> `!E` and `E != nil` -> `!!E`, padded with spaces to
#          the original length, so that TypeProf's truthiness narrowing applies.
#   acond: `if (v = E)` / `while (v = E)` / `... unless (v = E)` -> `... (v = E) && v`, only when the
#          predicate ends its line (so no later column on that line moves).
#   modfunc: a bare `module_function` statement -> `class << self` (padded), plus `; end` after the
#          module's closing `end`, so the methods after it become singleton methods.
#   shadow: a block parameter that has the same name as a local variable of an enclosing scope is
#          renamed (with every use of it inside the block) to an unused name of the same length.
# usage (library): Rewrite.apply(src, %i[nilq acond]) -> [new_src, {nilq: n, acond: n}]
require "prism"
require "set"

module Rewrite
  module_function

  # passes run one after another (re-parsing in between), so their edits never overlap
  def apply(src, kinds)
    stats = Hash.new(0)
    [%i[modfunc shadow], %i[nilq acond]].each do |pass|
      ks = kinds & pass
      next if ks.empty?
      src, st = apply1(src, ks)
      st.each { stats[_1] += _2 }
    end
    [src, stats]
  end

  def apply1(src, kinds)
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
    root = Prism.parse(src).value
    walk.(root)
    modfunc(root, edits, stats) if kinds.include?(:modfunc)
    shadow(root, src, edits, stats) if kinds.include?(:shadow)
    out = src.b.dup
    edits.sort_by { -_1[0] }.each do |s, e, text|
      text = text.ljust(e - s) if e > s
      raise "rewrite longer than original" if e > s && text.bytesize > e - s
      out[s...e] = text.b
    end
    [out.force_encoding(src.encoding), stats]
  end

  def modfunc(root, edits, stats)
    each_node(root) do |n|
      next unless n.is_a?(Prism::ModuleNode) && n.body.is_a?(Prism::StatementsNode)
      mf = n.body.body.find { _1.is_a?(Prism::CallNode) && _1.name == :module_function && _1.receiver.nil? && _1.arguments.nil? }
      next unless mf
      edits << [mf.location.start_offset, mf.location.end_offset, "class << self"]
      edits << [n.location.end_offset, n.location.end_offset, "; end"]
      stats[:modfunc] += 1
    end
  end

  LVAR_NODES = [Prism::LocalVariableReadNode, Prism::LocalVariableWriteNode, Prism::LocalVariableTargetNode,
                Prism::LocalVariableOperatorWriteNode, Prism::LocalVariableAndWriteNode, Prism::LocalVariableOrWriteNode]

  def shadow(root, src, edits, stats)
    used = src.scan(/[A-Za-z_][A-Za-z0-9_]*/).to_set
    scope_walk = lambda do |n, outer|
      return unless n
      if n.is_a?(Prism::BlockNode) && n.parameters.is_a?(Prism::BlockParametersNode) && n.parameters.parameters
        pn = n.parameters.parameters
        params = (pn.requireds + pn.optionals + pn.posts).flat_map { param_nodes(_1) }
        params.each do |p|
          next unless outer.include?(p.name)
          fresh = fresh_name(p.name.to_s.bytesize, used)
          used << fresh
          loc = p.respond_to?(:name_loc) ? p.name_loc : p.location
          edits << [loc.start_offset, loc.end_offset, fresh]
          rename_in(n.body, p.name, 0, fresh, edits)
          stats[:shadow] += 1
        end
        inner = outer | n.locals
        n.compact_child_nodes.each { scope_walk.(_1, inner) }
      elsif n.is_a?(Prism::DefNode) || n.is_a?(Prism::ClassNode) || n.is_a?(Prism::ModuleNode) || n.is_a?(Prism::SingletonClassNode)
        n.compact_child_nodes.each { scope_walk.(_1, n.locals) }
      elsif n.is_a?(Prism::ProgramNode) || n.is_a?(Prism::LambdaNode)
        n.compact_child_nodes.each { scope_walk.(_1, outer | n.locals) }
      else
        n.compact_child_nodes.each { scope_walk.(_1, outer) }
      end
    end
    scope_walk.(root, [])
  end

  def param_nodes(p)
    case p
    when Prism::MultiTargetNode then (p.lefts + p.rights).flat_map { param_nodes(_1) }
    when Prism::RequiredParameterNode, Prism::OptionalParameterNode then [p]
    else []
    end
  end

  def rename_in(n, name, depth, fresh, edits)
    return unless n
    if LVAR_NODES.any? { n.is_a?(_1) } && n.name == name && n.depth == depth
      loc = n.respond_to?(:name_loc) ? n.name_loc : n.location
      edits << [loc.start_offset, loc.start_offset + name.to_s.bytesize, fresh]
    end
    d = n.is_a?(Prism::BlockNode) || n.is_a?(Prism::LambdaNode) ? depth + 1 : depth
    n.compact_child_nodes.each { rename_in(_1, name, d, fresh, edits) }
  end

  def fresh_name(len, used)
    ("a" * len..."z" * len).lazy.chain(["z" * len]).find { |c| c.match?(/\A[a-z]/) && !used.include?(c) && !%w[do if in or end def nil not and for].include?(c) } or raise "no fresh name"
  end

  def each_node(n, &blk)
    return unless n
    yield n
    n.compact_child_nodes.each { each_node(_1, &blk) }
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
