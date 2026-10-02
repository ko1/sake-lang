# frozen_string_literal: true

require_relative "ast"

module Sake
  # Prism AST + the Resolver's tables -> SakeAST. A function body is lowered once per namespace it
  # lives in (an included module's function resolves in each including type).
  class Lower
    include AST

    # A frame's slots; one Scope per function or block, all sharing the function's frame.
    class Frame
      attr_reader :names

      def initialize = @names = []

      def alloc(name)
        @names << name
        @names.size - 1
      end
    end

    Scope = Struct.new(:vars, :frame) do
      def slot(name) = vars[name] ||= frame.alloc(name.to_s)
    end

    def self.program(program) = new(program).program

    def initialize(program)
      @program = program
      @functions = {}.compare_by_identity
    end

    def program
      main = function("<main>", nil, [], @program.toplevel)
      @program.functions.each_value { |fs| fs.each_value { |fn| @functions[fn] = function(fn.full_name, fn, fn.params, [fn.body]) } }
      AST::Program.new(main:, functions: @functions)
    end

    private

    def function(name, fn, params, stmts)
      @ns = fn&.namespace
      @fn = fn
      frame = Frame.new
      @scopes = [Scope.new({}, frame)]
      params.each { @scopes[0].slot(_1.to_sym) }
      @prev = nil
      body = statements(stmts.compact, stmts.first)
      AST::Function.new(name:, fn:, nparams: params.size, nslots: frame.names.size, slot_names: frame.names, body:)
    end

    def seq(nodes, origin) = nodes.size == 1 ? nodes[0] : Seq.new(body: nodes, origin:)

    # The previous statement's value, for `_`: a slot is made only when some `_` reads it.
    Prev = Struct.new(:slot)

    # inherit: the first statement reads the `_` of the enclosing statement (parentheses, interpolation).
    def statements(stmts, origin, inherit: false)
      outer = @prev
      nodes = []
      stmts.each_with_index do |st, i|
        @prev = i.positive? ? Prev.new : (inherit ? outer : nil)
        node = lower(st)
        nodes[-1] = LVarSet.new(slot: @prev.slot, value: nodes[-1], origin: stmts[i - 1]) if i.positive? && @prev.slot
        nodes << node
      end
      @prev = outer
      seq(nodes, origin)
    end

    def prev_value(n)
      raise "BUG: `_` with no previous statement at line #{n.location.start_line}" unless @prev
      @prev.slot ||= @scopes[-1].slot(:"_#{n.location.start_offset}")
      get(@prev.slot, n)
    end

    def scope(depth) = @scopes[-1 - depth]
    def slot(depth, name) = scope(depth).slot(name)

    def target(node) = @program.calls.fetch(node, {}).fetch(@ns) { nil }

    def lit(v, o) = Lit.new(value: v, origin: o)
    def get(s, o) = LVarGet.new(slot: s, origin: o)

    def lower(n)
      case n
      when nil then lit(nil, n)
      when Prism::StatementsNode then statements(n.body, n)
      when Prism::IntegerNode, Prism::FloatNode, Prism::RationalNode, Prism::ImaginaryNode then lit(n.value, n)
      when Prism::StringNode then Str.new(string: n.unescaped.dup.freeze, origin: n)
      when Prism::SymbolNode then lit(n.unescaped.to_sym, n)
      when Prism::InterpolatedStringNode then interp(n)
      when Prism::InterpolatedSymbolNode then ToSym.new(value: interp(n), origin: n)
      when Prism::InterpolatedRegularExpressionNode then MakeRegexp.new(parts: interp(n).parts, options: regexp_options(n), origin: n)
      when Prism::RegularExpressionNode then lit(Regexp.new(n.unescaped, regexp_options(n)), n)
      when Prism::RangeNode then MakeRange.new(left: lower(n.left), right: lower(n.right), exclusive: n.exclude_end?, origin: n)
      when Prism::KeywordHashNode
        MakePairs.new(keys: n.elements.map { lower(_1.key) }, values: n.elements.map { lower(_1.value) }, origin: n)
      when Prism::TrueNode then lit(true, n)
      when Prism::FalseNode then lit(false, n)
      when Prism::NilNode then lit(nil, n)
      when Prism::LocalVariableReadNode then get(slot(n.depth, n.name), n)
      when Prism::ItLocalVariableReadNode then get(slot(0, :it), n)
      when Prism::LocalVariableWriteNode then LVarSet.new(slot: slot(n.depth, n.name), value: lower(n.value), origin: n)
      when Prism::LocalVariableOperatorWriteNode
        s = slot(n.depth, n.name)
        LVarSet.new(slot: s, value: BinOp.new(op: n.binary_operator.to_s, left: get(s, n), right: lower(n.value), origin: n), origin: n)
      when Prism::LocalVariableOrWriteNode
        s = slot(n.depth, n.name)
        Or.new(left: get(s, n), right: LVarSet.new(slot: s, value: lower(n.value), origin: n), origin: n)
      when Prism::MultiWriteNode
        MultiWrite.new(slots: n.lefts.map { slot(_1.depth, _1.name) }, value: lower(n.value), origin: n)
      when Prism::IndexOperatorWriteNode, Prism::IndexOrWriteNode then index_update(n)
      when Prism::IfNode then If.new(cond: lower(n.predicate), then_: lower(n.statements), else_: lower(n.subsequent), origin: n)
      when Prism::UnlessNode then If.new(cond: lower(n.predicate), then_: lower(n.else_clause), else_: lower(n.statements), origin: n)
      when Prism::ElseNode then lower(n.statements)
      when Prism::WhileNode, Prism::UntilNode
        While.new(cond: lower(n.predicate), body: lower(n.statements), until_: n.is_a?(Prism::UntilNode), origin: n)
      when Prism::AndNode then And.new(left: lower(n.left), right: lower(n.right), origin: n)
      when Prism::OrNode then Or.new(left: lower(n.left), right: lower(n.right), origin: n)
      when Prism::ParenthesesNode then n.body.is_a?(Prism::StatementsNode) ? statements(n.body.body, n.body, inherit: true) : lower(n.body)
      when Prism::ArrayNode then MakeTuple.new(elems: n.elements.map { lower(_1) }, origin: n)
      when Prism::HashNode then MakeRecord.new(keys: n.elements.map { _1.key.unescaped }, values: n.elements.map { lower(_1.value) }, origin: n)
      when Prism::MatchRequiredNode
        keys, slots = record_targets(n.pattern)
        MatchRecord.new(value: lower(n.value), keys:, slots:, origin: n)
      when Prism::BeginNode then begin_node(n)
      when Prism::RescueModifierNode then RescueMod.new(expr: lower(n.expression), rescue_: lower(n.rescue_expression), origin: n)
      when Prism::RetryNode then Retry.new(origin: n)
      when Prism::MatchPredicateNode then MatchP.new(value: lower(n.value), pattern: pattern(n.pattern), origin: n)
      when Prism::CaseMatchNode
        clauses = n.conditions.map { [pattern(_1.pattern), lower(_1.statements)] }
        CaseIn.new(subject: lower(n.predicate), clauses:, else_: n.else_clause && lower(n.else_clause), origin: n)
      when Prism::ReturnNode then Return.new(value: jump_value(n, tuple: true), origin: n)
      when Prism::NextNode then Next.new(value: jump_value(n), origin: n)
      when Prism::BreakNode then Break.new(value: jump_value(n), origin: n)
      when Prism::YieldNode then Yield.new(args: args(n.arguments), origin: n)
      when Prism::CallNode then call(n)
      when Prism::InstanceVariableReadNode
        fa = target(n) or return unresolved(n)
        field_get(fa.getter, get(0, n), n)
      when Prism::InstanceVariableWriteNode
        fa = target(n) or return unresolved(n)
        field_set(fa.setter, get(0, n), lower(n.value), n)
      when Prism::InstanceVariableOperatorWriteNode
        fa = target(n) or return unresolved(n)
        cur = field_get(fa.getter, get(0, n), n)
        field_set(fa.setter, get(0, n), BinOp.new(op: n.binary_operator.to_s, left: cur, right: lower(n.value), origin: n), n)
      when Prism::InstanceVariableOrWriteNode
        fa = target(n) or return unresolved(n)
        Or.new(left: field_get(fa.getter, get(0, n), n), right: field_set(fa.setter, get(0, n), lower(n.value), n), origin: n)
      else raise "BUG: unlowered node #{n.type} at line #{n.location.start_line}"
      end
    end

    def unresolved(n) = Unresolved.new(message: "#{n.slice} was not resolved in #{@ns || "the top level"}", origin: n)

    def field_name(fn) = fn.name.sub(/\A[gs]et_/, "")
    def field_get(fn, subject, o) = FieldGet.new(type: fn.namespace, field: field_name(fn), fn:, subject:, origin: o)
    def field_set(fn, subject, value, o) = FieldSet.new(type: fn.namespace, field: field_name(fn), fn:, subject:, value:, origin: o)

    def regexp_options(n)
      opts = 0
      opts |= Regexp::IGNORECASE if n.ignore_case?
      opts |= Regexp::EXTENDED if n.extended?
      opts |= Regexp::MULTILINE if n.multi_line?
      opts
    end

    def interp(n)
      parts = n.parts.map do |part|
        case part
        when Prism::StringNode then Str.new(string: part.unescaped.dup.freeze, origin: part)
        when Prism::EmbeddedStatementsNode
          ToS.new(value: part.statements ? statements(part.statements.body, part.statements, inherit: true) : lit(nil, part), origin: part)
        when Prism::EmbeddedVariableNode then ToS.new(value: lower(part.variable), origin: part)
        end
      end
      Interp.new(parts:, origin: n)
    end

    def args(args_node) = (args_node&.arguments || []).map { lower(_1) }

    def jump_value(n, tuple: false)
      vals = args(n.arguments)
      return lit(nil, n) if vals.empty?
      tuple && vals.size > 1 ? MakeTuple.new(elems: vals, origin: n) : vals.first
    end

    def index_update(n)
      op = n.is_a?(Prism::IndexOrWriteNode) ? "||" : n.binary_operator.to_s
      IndexUpdate.new(recv: lower(n.receiver), key: lower(n.arguments.arguments.first), op:, value: lower(n.value), origin: n)
    end

    def begin_node(n)
      rescues = []
      clause = n.rescue_clause
      while clause
        ref = clause.reference
        rescues << Rescue.new(names: clause.exceptions.map(&:slice), slot: ref && slot(ref.depth, ref.name),
                              body: lower(clause.statements), origin: clause)
        clause = clause.subsequent
      end
      Begin.new(body: lower(n.statements), rescues:, else_: n.else_clause && lower(n.else_clause),
                ensure_: n.ensure_clause && lower(n.ensure_clause.statements), origin: n)
    end

    def record_targets(pat)
      keys = pat.elements.map { _1.key.unescaped }
      slots = pat.elements.map do |el|
        t = el.value.is_a?(Prism::ImplicitNode) ? el.value.value : el.value
        slot(t.depth, t.name)
      end
      [keys, slots]
    end

    def pattern(pat)
      case pat
      when Prism::ConstantReadNode then PType.new(name: pat.name.to_s, origin: pat)
      when Prism::AlternationPatternNode then PAlt.new(left: pattern(pat.left), right: pattern(pat.right), origin: pat)
      when Prism::HashPatternNode
        keys, slots = record_targets(pat)
        PRecord.new(keys:, slots:, origin: pat)
      else PValue.new(value: lower(pat), origin: pat)
      end
    end

    def call(n)
      return prev_value(n) if n.receiver.nil? && n.name == :_ && n.variable_call?
      if n.name == :! && n.call_operator_loc.nil? && n.receiver && n.arguments.nil? # `!x` is `x ? false : true`
        return If.new(cond: lower(n.receiver), then_: lit(false, n), else_: lit(true, n), origin: n)
      end
      t = target(n)
      return unresolved(n) if t.nil?
      if t.is_a?(Operators::Call)
        subject = chain_subject(n)
        xs =
          if subject then [lower(subject), *args(n.arguments)]
          elsif n.receiver.is_a?(Prism::ConstantReadNode) then args(n.arguments)
          else [lower(n.receiver), *args(n.arguments)]
          end
        return UnOp.new(op: t.op, value: xs[0], origin: n) if Operators::UNARY.include?(t.op)
        return IndexGet.new(recv: xs[0], key: xs[1], origin: n) if t.module == "Indexable" && t.op == "[]"
        return IndexSet.new(recv: xs[0], key: xs[1], value: xs[2], origin: n) if t.module == "Indexable"
        return IsNil.new(value: xs[0], negate: t.op == "!=", origin: n) if %w[== !=].include?(t.op) && xs[1].is_a?(Lit) && xs[1].value.nil?
        return BinOp.new(op: t.op, left: xs[0], right: xs[1], origin: n)
      end
      return raise_node(n) if t == :raise

      subject = chain_subject(n)
      xs = [*(subject ? [lower(subject)] : []), *args(n.arguments)]
      blk = n.block && block(n.block)
      case t
      when UserFunction then CallUser.new(fn: t, args: xs, block: blk, origin: n)
      when Dispatch then CallDispatch.new(dispatch: t, args: xs, block: blk, origin: n)
      when UnionCall then CallUnion.new(union: t, args: xs, block: blk, origin: n)
      when Builtin
        if (dt = @program.struct_types[t.namespace]) && blk.nil?
          f = field_name(t)
          return field_get(t, xs[0], n) if t.name == "get_#{f}" && dt.fields.include?(f) && xs.size == 1
          return field_set(t, xs[0], xs[1], n) if t.name == "set_#{f}" && dt.fields.include?(f) && xs.size == 2
        end
        CallBuiltin.new(fn: t, args: xs, block: blk, origin: n)
      end
    end

    # `x.T.f(...)`: x (see Resolver#chain_subject).
    def chain_subject(n)
      r = n.receiver
      return nil unless n.call_operator_loc && r.is_a?(Prism::CallNode) && r.receiver && r.call_operator_loc
      r.name.to_s.match?(/\A[A-Z]/) && r.arguments.nil? && r.block.nil? ? r.receiver : nil
    end

    def raise_node(n)
      nodes = n.arguments&.arguments || []
      return ReRaise.new(origin: n) if nodes.empty?
      return Raise.new(type: nodes[0].slice, args: [lower(nodes[1])], origin: n) if nodes.size == 2
      Raise.new(type: nil, args: [lower(nodes[0])], origin: n)
    end

    def block(b)
      sc = Scope.new({}, @scopes[0].frame)
      @scopes.push(sc)
      begin
        params = @program.blocks.fetch(b).map { sc.slot(_1.to_sym) }
        body = lower(b.body)
        locals = sc.vars.values - params
        Block.new(params:, locals:, body:, origin: b)
      ensure
        @scopes.pop
      end
    end
  end
end
