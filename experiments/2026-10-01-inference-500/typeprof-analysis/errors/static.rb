# Static (Prism) detectors for TypeProf false-positive causes that the counterfactual runs do not toggle.
# Each detector looks at the variables involved in the call at the error position.
require_relative "locate"

module Static
  module_function

  def names_in_multitarget(mt)
    (mt.lefts + [mt.rest&.respond_to?(:expression) ? mt.rest.expression : nil] + mt.rights).compact.flat_map do |t|
      case t
      when Prism::MultiTargetNode then names_in_multitarget(t)
      when Prism::RequiredParameterNode, Prism::LocalVariableTargetNode then [t.name]
      when Prism::SplatNode then t.expression ? [t.expression.name] : []
      else []
      end
    end
  end

  def params_of(n)
    pn = case n
         when Prism::DefNode then n.parameters
         when Prism::BlockNode, Prism::LambdaNode then n.parameters.is_a?(Prism::BlockParametersNode) ? n.parameters.parameters : nil
         end
    pn
  end

  def destructured_names(n)
    pn = params_of(n) or return []
    (pn.requireds + pn.posts).grep(Prism::MultiTargetNode).flat_map { names_in_multitarget(_1) }
  end

  def plain_block_params(n)
    return [] unless n.is_a?(Prism::BlockNode)
    pn = params_of(n) or return []
    (pn.requireds + pn.optionals + pn.posts).filter_map { _1.respond_to?(:name) ? _1.name : nil }
  end

  # variables read by the erroring expression (receiver and arguments, one level)
  def involved(node)
    parts = []
    case node
    when Prism::CallNode
      parts << node.receiver
      parts.concat(node.arguments&.arguments || [])
    when Prism::LocalVariableOperatorWriteNode, Prism::LocalVariableOrWriteNode
      return [[:lvar, node.name]] + involved_expr(node.value)
    when Prism::InstanceVariableOperatorWriteNode
      return [[:ivar, node.name]] + involved_expr(node.value)
    when Prism::CallOperatorWriteNode, Prism::IndexOperatorWriteNode, Prism::CallOrWriteNode
      parts << node.receiver
      parts << node.value if node.respond_to?(:value)
      parts.concat(node.arguments&.arguments || []) if node.respond_to?(:arguments)
    when Prism::YieldNode
      parts.concat(node.arguments&.arguments || [])
    when Prism::LocalVariableReadNode
      parts << node
    end
    parts.compact.flat_map { involved_expr(_1) }
  end

  def involved_expr(e)
    case e
    when Prism::LocalVariableReadNode then [[:lvar, e.name]]
    when Prism::InstanceVariableReadNode then [[:ivar, e.name]]
    when Prism::ParenthesesNode then e.body ? e.body.body.flat_map { involved_expr(_1) } : []
    when Prism::CallNode
      # a.b / a[i] / a + b : look one level into receiver and args too
      ([e.receiver] + (e.arguments&.arguments || [])).compact.flat_map { involved_expr(_1) }.map { |k, v| [:"#{k}_sub", v] }
    else []
    end
  end

  def receiver_kind(node)
    r = node.respond_to?(:receiver) ? node.receiver : nil
    case r
    when nil then node.is_a?(Prism::LocalVariableOperatorWriteNode) ? :lvar : :none
    when Prism::LocalVariableReadNode then :lvar
    when Prism::InstanceVariableReadNode then :ivar
    when Prism::CallNode then r.name == :[] ? :index : :call
    else r.class.name.split("::").last.sub(/Node\z/, "").downcase.to_sym
    end
  end

  # lvars written anywhere in the scope that owns `blk` (outside blk itself)
  def outer_writes(scope, blk)
    names = []
    Locate.each_with_path(scope) do |n, path|
      next if n.equal?(blk) || path.any? { _1.equal?(blk) }
      next if path.drop(1).any? { _1.is_a?(Prism::DefNode) || _1.is_a?(Prism::ClassNode) || _1.is_a?(Prism::ModuleNode) }
      names << n.name if n.is_a?(Prism::LocalVariableWriteNode) || n.is_a?(Prism::LocalVariableTargetNode)
    end
    names
  end

  def facts(root, src, err)
    l, c, l2, c2, msg = Locate.parse_err(err)
    node, path = Locate.node_at(root, l, c, l2, c2)
    return { located: false } unless node
    inv = involved(node)
    lvars = inv.select { _1[0] == :lvar }.map(&:last)
    f = { located: true, node: node.class.name.split("::").last, recv: receiver_kind(node), lvars:, ivars: inv.select { _1[0] == :ivar }.map(&:last) }
    # nested destructuring parameters of an enclosing def/block
    dn = path.flat_map { destructured_names(_1) }
    f[:destructured] = (inv.map(&:last) & dn)
    # block parameter that has the same name as a local of the enclosing scope
    blocks = path.select { _1.is_a?(Prism::BlockNode) }
    f[:shadow] = blocks.flat_map do |b|
      scope = path.reverse.find { _1.is_a?(Prism::DefNode) || _1.is_a?(Prism::ProgramNode) || _1.is_a?(Prism::ClassNode) || _1.is_a?(Prism::ModuleNode) }
      ps = plain_block_params(b) & inv.map(&:last)
      ps & outer_writes(scope, b)
    end
    # case/in with a bare constant pattern on the same variable
    f[:case_in] = path.each_cons(2).any? do |cm, inn|
      cm.is_a?(Prism::CaseMatchNode) && inn.is_a?(Prism::InNode) &&
        [Prism::ConstantReadNode, Prism::ConstantPathNode, Prism::AlternationPatternNode].any? { inn.pattern.is_a?(_1) } &&
        cm.predicate.is_a?(Prism::LocalVariableReadNode) && inv.map(&:last).include?(cm.predicate.name)
    end
    # module_function: calling M.m where m is defined after `module_function`
    if msg =~ /undefined method: singleton\(([\w:]+)\)#/ && src.match?(/^\s*module_function\b/)
      f[:module_function] = true
    end
    f
  end
end
