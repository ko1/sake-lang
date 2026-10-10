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
      # Optional parameters (`b = 1`, `d: 2`) are set from their defaults when the call did not give them.
      required = fn ? fn.min_arity : 0
      kw_base = fn ? fn.positional + (fn.rest_param ? 1 : 0) : 0 # keywords come after `*rest`
      defaults = (fn&.defaults || []).each_with_index.filter_map { |d, j| ArgDefault.new(slot: required + j, value: lower(d), origin: d) if d }
      defaults += (fn&.keywords || {}).values.each_with_index.filter_map { |d, j| ArgDefault.new(slot: kw_base + j, value: lower(d), origin: d) if d }
      body = statements(stmts.compact, stmts.first)
      body = Seq.new(body: [*defaults, body], origin: fn.node) unless defaults.empty?
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
      when Prism::ImplicitNode then lower(n.value)
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
        rest = n.rest.is_a?(Prism::SplatNode) ? [TRest.new(slot: (e = n.rest.expression) && slot(e.depth, e.name), origin: n.rest)] : []
        MultiWrite.new(targets: [*n.lefts.map { mw_target(_1) }, *rest, *n.rights.map { mw_target(_1) }], value: lower(n.value), origin: n)
      when Prism::IndexOperatorWriteNode, Prism::IndexOrWriteNode then index_update(n)
      when Prism::IfNode then If.new(cond: lower(n.predicate), then_: lower(n.statements), else_: lower(n.subsequent), origin: n)
      when Prism::UnlessNode then If.new(cond: lower(n.predicate), then_: lower(n.else_clause), else_: lower(n.statements), origin: n)
      when Prism::ElseNode then lower(n.statements)
      when Prism::WhileNode, Prism::UntilNode
        (@jump_targets ||= []).push(:loop)
        body = begin
          lower(n.statements)
        ensure
          @jump_targets.pop
        end
        While.new(cond: lower(n.predicate), body:, until_: n.is_a?(Prism::UntilNode), origin: n)
      when Prism::AndNode then And.new(left: lower(n.left), right: lower(n.right), origin: n)
      when Prism::OrNode then Or.new(left: lower(n.left), right: lower(n.right), origin: n)
      when Prism::ParenthesesNode then n.body.is_a?(Prism::StatementsNode) ? statements(n.body.body, n.body, inherit: true) : lower(n.body)
      when Prism::ArrayNode then MakeTuple.new(elems: n.elements.map { lower(_1) }, origin: n)
      when Prism::HashNode then MakeRecord.new(keys: n.elements.map { _1.key.unescaped }, values: n.elements.map { lower(_1.value) }, origin: n)
      when Prism::MatchRequiredNode
        if n.pattern.is_a?(Prism::HashPatternNode)
          keys, slots = record_targets(n.pattern)
          MatchRecord.new(value: lower(n.value), keys:, slots:, origin: n)
        else # `x => Integer`: a case/in with one branch and no else (NoMatchingPatternError otherwise)
          CaseIn.new(subject: lower(n.value), clauses: [[pattern(n.pattern), lit(nil, n)]], else_: nil, origin: n)
        end
      when Prism::BeginNode then begin_node(n)
      when Prism::RescueModifierNode then RescueMod.new(expr: lower(n.expression), rescue_: lower(n.rescue_expression), origin: n)
      when Prism::RetryNode then Retry.new(origin: n)
      when Prism::MatchPredicateNode then MatchP.new(value: lower(n.value), pattern: pattern(n.pattern), origin: n)
      when Prism::CaseMatchNode
        clauses = n.conditions.map { [pattern(_1.pattern), lower(_1.statements)] }
        CaseIn.new(subject: lower(n.predicate), clauses:, else_: n.else_clause && lower(n.else_clause), origin: n)
      when Prism::ReturnNode then Return.new(value: jump_value(n, tuple: true), origin: n)
      when Prism::NextNode then Next.new(value: jump_value(n), origin: n)
      when Prism::BreakNode then Break.new(value: jump_value(n), target: (@jump_targets || []).last || :loop, origin: n)
      when Prism::YieldNode then Yield.new(args: args(n.arguments), origin: n)
      when Prism::CallNode then call(n)
      when Prism::ConstantReadNode, Prism::ConstantPathNode then CallBuiltin.new(fn: target(n), args: [], block: nil, origin: n) # ARGV, Math::PI
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
      when Prism::CallOperatorWriteNode, Prism::CallOrWriteNode, Prism::CallAndWriteNode
        pair = target(n) or return unresolved(n)
        reader, writer = pair
        tmp = @scopes[-1].slot(:"(subject #{n.location.start_offset})")
        subj = get(tmp, n)
        cur = reader.is_a?(UserFunction) ? CallUser.new(fn: reader, args: [subj], block: nil, origin: n) : field_get(reader, subj, n)
        newv =
          case n
          when Prism::CallOperatorWriteNode then BinOp.new(op: n.binary_operator.to_s, left: cur, right: lower(n.value), origin: n)
          else lower(n.value)
          end
        set = field_set(writer, subj, newv, n)
        body = case n
               when Prism::CallOrWriteNode then Or.new(left: cur, right: set, origin: n)
               when Prism::CallAndWriteNode then And.new(left: cur, right: set, origin: n)
               else set
               end
        Seq.new(body: [LVarSet.new(slot: tmp, value: lower(n.receiver.receiver), origin: n), body], origin: n)
      when Prism::InstanceVariableOrWriteNode
        fa = target(n) or return unresolved(n)
        Or.new(left: field_get(fa.getter, get(0, n), n), right: field_set(fa.setter, get(0, n), lower(n.value), n), origin: n)
      else raise "BUG: unlowered node #{n.type} at line #{n.location.start_line}"
      end
    end

    def mw_target(t)
      case t
      when Prism::LocalVariableTargetNode then TLocal.new(slot: slot(t.depth, t.name), origin: t)
      when Prism::IndexTargetNode then TIndex.new(recv: lower(t.receiver), key: lower(t.arguments.arguments[0]), origin: t)
      when Prism::InstanceVariableTargetNode
        fa = target(t) or return unresolved(t)
        TField.new(type: fa.setter.namespace, field: field_name(fa.setter), fn: fa.setter, subject: get(0, t), origin: t)
      end
    end

    def unresolved(n) = Unresolved.new(message: "#{n.slice} was not resolved in #{@ns || "the top level"}", origin: n)

    def field_name(fn) = fn.name.sub(/\Aset_/, "")
    def field_get(fn, subject, o) = FieldGet.new(type: fn.namespace, field: field_name(fn), fn:, subject:, origin: o)
    def field_set(fn, subject, value, o) = FieldSet.new(type: fn.namespace, field: field_name(fn), fn:, subject:, value:, origin: o)

    def regexp_options(n)
      opts = 0
      opts |= Regexp::IGNORECASE if n.ignore_case?
      opts |= Regexp::EXTENDED if n.extended?
      opts |= Regexp::MULTILINE if n.multi_line?
      opts |= Regexp::NOENCODING if n.ascii_8bit? # /n: byte ranges above \x7f
      opts
    end

    def interp(n)
      Interp.new(parts: interp_parts(n), origin: n)
    end

    # Adjacent literals ("a#{x}" "b") nest an interpolated literal in the parts: flattened here.
    def interp_parts(n)
      n.parts.flat_map do |part|
        case part
        when Prism::StringNode then [Str.new(string: part.unescaped.dup.freeze, origin: part)]
        when Prism::EmbeddedStatementsNode
          [ToS.new(value: part.statements ? statements(part.statements.body, part.statements, inherit: true) : lit(nil, part), origin: part)]
        when Prism::EmbeddedVariableNode then [ToS.new(value: lower(part.variable), origin: part)]
        when Prism::InterpolatedStringNode then interp_parts(part)
        else raise "BUG: interpolated part #{part.class}"
        end
      end
    end

    def args(args_node)
      (args_node&.arguments || []).map { _1.is_a?(Prism::SplatNode) ? Splat.new(value: lower(_1.expression), origin: _1) : lower(_1) }
    end

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
        # `rescue StandardError` catches everything rescuable, as a bare rescue (names: []).
        names = clause.exceptions.map(&:slice)
        names = [] if names.any? { Resolver::CATCH_ALL.include?(_1) }
        rescues << Rescue.new(names:, slot: ref && slot(ref.depth, ref.name),
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
      when Prism::ArrayPatternNode then PTuple.new(elems: pat.requireds.map { pattern(_1) }, origin: pat)
      when Prism::LocalVariableTargetNode then PBind.new(slot: slot(pat.depth, pat.name), origin: pat)
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
        return IndexGet.new(recv: xs[0], key: xs[1], extra: xs[2], origin: n) if t.module == "Indexable" && t.op == "[]"
        return IndexSet.new(recv: xs[0], key: xs[1], extra: (xs[2] if xs.size == 4), value: xs[-1], origin: n) if t.module == "Indexable"
        return IsNil.new(value: xs[0], negate: t.op == "!=", origin: n) if %w[== !=].include?(t.op) && xs[1].is_a?(Lit) && xs[1].value.nil?
        return BinOp.new(op: t.op, left: xs[0], right: xs[1], origin: n)
      end
      return raise_node(n) if t == :raise

      subject = chain_subject(n)
      xs = [*(subject ? [lower(subject)] : []), *args(n.arguments)]
      temps = []
      xs = keyword_args(t, n, xs, temps) if t.is_a?(UserFunction) || t.is_a?(Dispatch)
      xs = new_keyword_args(t, n, xs, temps) if t.is_a?(Builtin) && t.name == "new" && @program.struct_types.key?(t.namespace) && n.arguments&.arguments&.last.is_a?(Prism::KeywordHashNode)
      blk = n.block && block(n.block)
      call = user_call(t, n, xs, blk)
      temps.empty? ? call : Seq.new(body: [*temps, call], origin: n)
    end

    # `f(x, d: 5)` to `def f(a, b = 1, c: 2, d: 3)`: the arguments in parameter order, Missing where the
    # call gives none. Keyword values written out of order are evaluated first, in written order.
    def keyword_args(t, n, xs, temps)
      fn = t.is_a?(Dispatch) ? (@program.functions.dig(t.module, t.name) || t.table.values.first) : t
      return xs unless fn.is_a?(UserFunction) && (fn.keywords&.any? || fn.rest_param || fn.kwrest_param)
      kw = n.arguments&.arguments&.last
      given = {}
      if kw.is_a?(Prism::KeywordHashNode)
        xs = xs[0...-1]
        kw.elements.each { given[_1.key.unescaped] = _1.value }
      end if fn.keywords&.any? || fn.kwrest_param
      names = fn.keywords.keys
      in_order = given.keys == names.select { given.key?(_1) }
      temp = lambda do |x, o|
        tmp = @scopes[-1].slot(:"(argument #{@arg_temps = (@arg_temps || 0) + 1})")
        temps << LVarSet.new(slot: tmp, value: x, origin: o)
        get(tmp, o)
      end
      xs = xs.map { |x| [Lit, Str].include?(x.class) ? x : temp.(x, x.origin) } unless in_order
      vals = given.transform_values { |v| in_order ? lower(v) : temp.(lower(v), v) }
      fixed = xs.take(fn.positional)
      pad = Array.new(fn.positional - fixed.size) { Missing.new(origin: nil) }
      # `*rest`: the positional arguments after the fixed ones, as a new Array
      rest = fn.rest_param ? [CallBuiltin.new(fn: @program.registry.lookup("Array", CTOR), args: xs.drop(fn.positional), block: nil, origin: n)] : []
      # `**opts`: the keywords that are not parameters, as a Hash of Symbol keys
      extra = given.keys - names
      opts = fn.kwrest_param ? [CallBuiltin.new(fn: @program.registry.lookup("Hash", CTOR), block: nil, origin: kw || n,
                                                args: [MakePairs.new(keys: extra.map { lit(_1.to_sym, n) }, values: extra.map { vals[_1] }, origin: n)])] : []
      [*fixed, *pad, *rest, *names.map { vals[_1] || Missing.new(origin: nil) }, *opts]
    end

    # T.new(a, level: :warn): the fields in order, Missing where neither a position nor a keyword gives one
    # (T.new then stores the default). Keyword values written out of order are evaluated in written order.
    def new_keyword_args(t, n, xs, temps)
      fields = @program.struct_types[t.namespace].fields
      kw = n.arguments.arguments.last
      xs = xs[0...-1]
      given = kw.elements.to_h { [_1.key.unescaped, _1.value] }
      names = fields.drop(xs.size)
      in_order = given.keys == names.select { given.key?(_1) }
      vals = given.transform_values do |v|
        next lower(v) if in_order
        tmp = @scopes[-1].slot(:"(argument #{@arg_temps = (@arg_temps || 0) + 1})")
        temps << LVarSet.new(slot: tmp, value: lower(v), origin: v)
        get(tmp, v)
      end
      unless in_order # positional arguments are evaluated before the keywords, as written
        pos = []
        xs = xs.map do |x|
          next x if [Lit, Str].include?(x.class)
          tmp = @scopes[-1].slot(:"(argument #{@arg_temps = (@arg_temps || 0) + 1})")
          pos << LVarSet.new(slot: tmp, value: x, origin: x.origin)
          get(tmp, x.origin)
        end
        temps.unshift(*pos)
      end
      last = names.rindex { given.key?(_1) }
      [*xs, *names.take(last + 1).map { vals[_1] || Missing.new(origin: nil) }]
    end

    def user_call(t, n, xs, blk)
      case t
      when UserFunction then CallUser.new(fn: t, args: xs, block: blk, origin: n)
      when Dispatch then CallDispatch.new(dispatch: t, args: xs, block: blk, origin: n)
      when UnionCall then CallUnion.new(union: t, args: xs, block: blk, origin: n)
      when Builtin
        return BlockGiven.new(origin: n) if t.full_name == "Kernel.block_given?"
        if (dt = @program.struct_types[t.namespace]) && blk.nil?
          f = field_name(t)
          return field_get(t, xs[0], n) if t.name == f && dt.fields.include?(f) && xs.size == 1
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
      if nodes[0].is_a?(Prism::ConstantReadNode) # `raise T`: the message is the type's name
        return Raise.new(type: nodes[0].slice, args: [Str.new(string: nodes[0].slice.freeze, origin: nodes[0])], origin: n)
      end
      Raise.new(type: nil, args: [lower(nodes[0])], origin: n)
    end

    # names: the targets of one `(a, (b, c))` level; nested levels are taken apart after this one.
    def destructure(sc, names, from, origin, out)
      nested = []
      targets = names.each_with_index.map do |nm, j|
        next TLocal.new(slot: sc.slot(nm.to_sym), origin:) if nm.is_a?(String)
        inner = sc.slot(:"(param #{from}.#{j})")
        nested << [nm, inner]
        TLocal.new(slot: inner, origin:)
      end
      out << MultiWrite.new(targets:, value: get(from, origin), origin:)
      nested.each { |nm, inner| destructure(sc, nm, inner, origin, out) }
    end

    def block(b)
      return BlockPass.new(origin: b) if b.is_a?(Prism::BlockArgumentNode)
      sc = Scope.new({}, @scopes[0].frame)
      @scopes.push(sc)
      begin
        # `(a, b)` parameters get a hidden slot, taken apart at the start of the body like `a, b = x`.
        prologue = []
        names = @program.blocks.fetch(b)
        rest = names.index { _1.is_a?(RestParam) }
        params = names.each_with_index.map do |name, i|
          next sc.slot(name.to_sym) if name.is_a?(String)
          next sc.slot(name.name ? name.name.to_sym : :"(rest #{i})") if name.is_a?(RestParam)
          hidden = sc.slot(:"(param #{i})")
          destructure(sc, name, hidden, b, prologue)
          hidden
        end
        (@jump_targets ||= []).push(:block)
        body = begin
          lower(b.body)
        ensure
          @jump_targets.pop
        end
        body = Seq.new(body: [*prologue, body], origin: b.body || b) unless prologue.empty?
        locals = sc.vars.values - params
        Block.new(params:, locals:, body:, rest:, origin: b)
      ensure
        @scopes.pop
      end
    end
  end
end
