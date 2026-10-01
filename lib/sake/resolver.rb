# frozen_string_literal: true

require "prism"
require "did_you_mean"

module Sake
  UserFunction = Struct.new(:namespace, :name, :params, :body, :node, :yields) do
    def full_name = namespace ? "#{namespace}.#{name}" : name
  end

  # calls / blocks are identity hashes keyed by Prism nodes.
  Program = Struct.new(:path, :registry, :toplevel, :calls, :blocks, :functions, :data_types, keyword_init: true)

  # Static pass: collects definitions, resolves every call, and reports all errors before running.
  class Resolver
    BINARY_OPS = %i[+ - * / % ** == != < <= > >= <=> & | ^ << >>].freeze
    UNARY_OPS = %i[-@ +@ ! ~].freeze
    FORBIDDEN = %w[send __send__ public_send method_missing define_method eval instance_eval class_eval
                   module_eval instance_exec class_exec instance_variable_get instance_variable_set
                   const_get const_set binding].freeze
    Ctx = Struct.new(:ns, :fn, :in_block, :in_loop)

    def initialize(path, root, registry)
      @path = path
      @root = root
      @registry = registry
      @functions = Hash.new { |h, k| h[k] = {} } # namespace (nil = top level) => name => UserFunction
      @data_types = {}
      @toplevel = []
      @calls = {}.compare_by_identity
      @blocks = {}.compare_by_identity
      @diags = []
    end

    def resolve
      collect
      check_all
      raise StaticErrors.new(@diags.sort_by { [_1.line, _1.column] }) unless @diags.empty?
      Program.new(path: @path, registry: @registry, toplevel: @toplevel, calls: @calls, blocks: @blocks,
                  functions: @functions, data_types: @data_types)
    end

    private

    def error(node, message, hints = [])
      loc = node.respond_to?(:message_loc) && node.message_loc ? node.message_loc : node.location
      @diags << Diagnostic.new(@path, loc.start_line, loc.start_column, message, hints)
      nil
    end

    # --- collect definitions ---

    def collect
      stmts = @root.statements.body
      # Data types first so that `class Point` bodies can see their accessors.
      stmts.grep(Prism::ConstantWriteNode).each { collect_constant(_1) }
      stmts.each do |st|
        case st
        when Prism::ConstantWriteNode then nil
        when Prism::DefNode then collect_def(st, nil)
        when Prism::ClassNode, Prism::ModuleNode then collect_namespace(st)
        else @toplevel << st
        end
      end
    end

    def data_define?(v)
      v.is_a?(Prism::CallNode) && v.receiver.is_a?(Prism::ConstantReadNode) &&
        v.receiver.name == :Data && v.name == :define
    end

    def collect_constant(node)
      v = node.value
      unless data_define?(v)
        return error(node, "constant assignment is only supported as `#{node.name} = Data.define(...)`")
      end
      return error(v.block, "Data.define with a block is not supported; define functions in `class #{node.name}`") if v.block

      name = node.name.to_s
      fields = (v.arguments&.arguments || []).filter_map do |a|
        a.is_a?(Prism::SymbolNode) ? a.unescaped : error(a, "Data.define takes field names as symbols, like `Data.define(:x, :y)`")
      end
      dup = fields.find { fields.count(_1) > 1 }
      return error(v, "duplicate field `#{dup}` in Data.define") if dup
      return error(node, "`#{name}` is already defined") if @data_types[name] || @registry.namespace?(name)

      dt = @data_types[name] = DataType.new(name, fields)
      @registry.define(name, :new, fields.map { "Any" }) { |*vs| Record.new(dt, vs) }
      Stdlib.install_typed_array(@registry, name, data: true)
      Stdlib.define_nil_equality(@registry, name)
      fields.each_with_index do |f, i|
        @registry.define(name, "get_#{f}", [name]) { |r| r.values[i] }
        @registry.define(name, "set_#{f}", [name, "Any"]) { |r, x| r.values[i] = x }
      end
    end

    def collect_namespace(node)
      cp = node.constant_path
      return error(cp, "nested namespace `#{cp.slice}` is not supported") unless cp.is_a?(Prism::ConstantReadNode)

      ns = cp.name.to_s
      if node.is_a?(Prism::ClassNode) && node.superclass
        error(node.superclass, "class inheritance is not supported (Sake has no dispatch on receivers)")
      end
      @registry.add_namespace(ns)
      body = node.body
      return if body.nil?
      return error(body, "unsupported syntax in class body") unless body.is_a?(Prism::StatementsNode)

      body.body.each do |st|
        if !st.is_a?(Prism::DefNode)
          error(st, "only `def` is allowed in a class/module body")
        elsif st.receiver
          error(st, "`def #{st.receiver.slice}.#{st.name}` inside `#{cp.slice}`: write `def #{st.name}` (it defines #{ns}.#{st.name})")
        else
          collect_def(st, ns)
        end
      end
    end

    def collect_def(node, ns)
      case node.receiver
      when nil then nil
      when Prism::ConstantReadNode
        ns = node.receiver.name.to_s
        @registry.add_namespace(ns)
      when Prism::SelfNode
        return error(node, "Sake has no `self`; inside `class Foo`, `def #{node.name}` defines Foo.#{node.name}")
      else
        return error(node.receiver, "`def x.#{node.name}` is not supported; use `def Type.#{node.name}`")
      end

      name = node.name.to_s
      fn = UserFunction.new(ns, name, collect_params(node), node.body, node, yields?(node.body))
      if (prev = @functions[ns][name])
        error(node, "`#{fn.full_name}` is already defined at line #{prev.node.location.start_line}")
      elsif ns && @registry.lookup(ns, name)
        error(node, "`#{fn.full_name}` is a built-in operation and cannot be redefined")
      else
        @functions[ns][name] = fn
      end
    end

    def collect_params(node)
      pn = node.parameters
      return [] unless pn
      return error(pn.block, "block parameter `#{pn.block.slice}` is not supported; use `yield`") || [] if pn.block

      if pn.optionals.any? || pn.posts.any? || pn.keywords.any? || pn.rest || pn.keyword_rest
        error(pn, "only required positional parameters are supported (got `#{pn.slice}`)")
      end
      pn.requireds.map do |r|
        r.is_a?(Prism::RequiredParameterNode) ? r.name.to_s : (error(r, "parameter destructuring is not supported"); "_")
      end
    end

    def yields?(node)
      return false if node.nil?
      node.is_a?(Prism::YieldNode) || node.compact_child_nodes.any? { yields?(_1) }
    end

    # --- check bodies ---

    def check_all
      @functions.each_value do |fs|
        fs.each_value { |f| check(f.body, Ctx.new(f.namespace, f, false, false)) }
      end
      @toplevel.each { check(_1, Ctx.new(nil, nil, false, false)) }
    end

    def check(node, ctx)
      case node
      when nil, Prism::IntegerNode, Prism::FloatNode, Prism::StringNode, Prism::TrueNode,
           Prism::FalseNode, Prism::NilNode, Prism::LocalVariableReadNode, Prism::ItLocalVariableReadNode
        nil
      when Prism::StatementsNode then node.body.each { check(_1, ctx) }
      when Prism::LocalVariableWriteNode then check(node.value, ctx)
      when Prism::LocalVariableOperatorWriteNode
        error(node, "operator `#{node.binary_operator}=` is not supported") unless binary_op?(node.binary_operator)
        check(node.value, ctx)
      when Prism::MultiWriteNode
        unless node.rest.nil? && node.rights.empty? && node.lefts.all?(Prism::LocalVariableTargetNode)
          error(node, "only `a, b = tuple` (local variables, no splat) is supported")
        end
        check(node.value, ctx)
      when Prism::IfNode then check_each(ctx, node.predicate, node.statements, node.subsequent)
      when Prism::UnlessNode then check_each(ctx, node.predicate, node.statements, node.else_clause)
      when Prism::ElseNode then check(node.statements, ctx)
      when Prism::WhileNode, Prism::UntilNode
        error(node, "`begin ... end while` is not supported") if node.begin_modifier?
        check(node.predicate, ctx)
        check(node.statements, ctx.dup.tap { _1.in_loop = true })
      when Prism::AndNode, Prism::OrNode then check_each(ctx, node.left, node.right)
      when Prism::ParenthesesNode then check(node.body, ctx)
      when Prism::ArrayNode
        if node.opening_loc&.slice&.start_with?("%")
          error(node, "`#{node.opening_loc.slice}...]` is not supported yet (whether it is a Tuple or an Array is undecided)")
        end
        node.elements.each { _1.is_a?(Prism::SplatNode) ? error(_1, "splat is not supported") : check(_1, ctx) }
      when Prism::ReturnNode
        error(node, "`return` outside a function") unless ctx.fn
        check_args(node.arguments, ctx)
      when Prism::YieldNode
        error(node, "`yield` outside a function") unless ctx.fn
        check_args(node.arguments, ctx)
      when Prism::NextNode
        error(node, "`next` outside a block or loop") unless ctx.in_block || ctx.in_loop
        check_jump_args(node, ctx)
      when Prism::BreakNode
        error(node, "`break` is only supported directly inside `while`/`until`") unless ctx.in_loop
        check_jump_args(node, ctx)
      when Prism::CallNode then check_call(node, ctx)
      when Prism::InterpolatedStringNode
        error(node, "string interpolation is not supported yet (how values become strings is undecided); use String.+")
      when Prism::DefNode then error(node, "`def` must be at the top level or directly in a class/module body")
      when Prism::ClassNode, Prism::ModuleNode then error(node, "class/module must be at the top level")
      when Prism::ConstantWriteNode then error(node, "constant assignment must be at the top level")
      when Prism::ConstantReadNode then error(node, "type `#{node.name}` cannot be used as a value")
      when Prism::SelfNode then error(node, "Sake has no `self`")
      when Prism::InstanceVariableReadNode, Prism::InstanceVariableWriteNode, Prism::InstanceVariableOperatorWriteNode
        error(node, "Sake has no instance variables; use Data.define fields")
      when Prism::SymbolNode then error(node, "symbols are not supported (only as Data.define field names)")
      else
        error(node, "unsupported syntax: #{node.type.to_s.delete_suffix("_node").tr("_", " ")} `#{first_line(node.slice)}`")
      end
    end

    def check_each(ctx, *nodes) = nodes.each { check(_1, ctx) }

    def check_jump_args(node, ctx)
      args = node.arguments&.arguments || []
      error(node, "`#{node.keyword_loc.slice}` takes at most one value") if args.size > 1
      check_args(node.arguments, ctx)
    end

    def check_args(args_node, ctx)
      (args_node&.arguments || []).each do |a|
        case a
        when Prism::SplatNode then error(a, "splat arguments are not supported")
        when Prism::KeywordHashNode then error(a, "keyword arguments are not supported")
        when Prism::ForwardingArgumentsNode then error(a, "argument forwarding is not supported")
        else check(a, ctx)
        end
      end
    end

    def binary_op?(name) = !@registry.binary_ops[name.to_s].empty?

    def check_call(node, ctx)
      args = node.arguments&.arguments || []
      blk = node.block
      if blk.is_a?(Prism::BlockArgumentNode)
        error(blk, "`&block` arguments are not supported; pass a block `{ |x| ... }`")
        blk = nil
      end
      recv = node.receiver

      if recv.nil?
        return error(node, "`#{node.name}` is not allowed in Sake (it defeats static analysis)") if FORBIDDEN.include?(node.name.to_s)
        target = resolve_unqualified(node, ctx)
      elsif recv.is_a?(Prism::ConstantReadNode) && (node.call_operator_loc || node.name == :[])
        target = resolve_qualified(node, recv.name.to_s)
      elsif recv.is_a?(Prism::ConstantPathNode)
        return error(recv, "`#{recv.slice}` (nested constants) is not supported")
      elsif node.call_operator_loc.nil? && BINARY_OPS.include?(node.name) && args.size == 1
        error(node, "operator `#{node.name}` is not supported") unless binary_op?(node.name)
        @calls[node] = :binary_op
        check(recv, ctx)
        check_args(node.arguments, ctx)
        return
      elsif node.call_operator_loc.nil? && UNARY_OPS.include?(node.name)
        hint = node.name == :-@ ? ["write `0 - #{recv.slice}`"] : []
        error(node, "unary operator `#{node.slice}` is not supported yet (undecided)", hint)
        return check(recv, ctx)
      elsif node.call_operator_loc.nil? && %i[[] []=].include?(node.name)
        error(node, "indexing `#{first_line(node.slice)}` is not supported yet (out-of-range behavior is undecided)")
        check(recv, ctx)
        return check_args(node.arguments, ctx)
      else
        return lowercase_receiver_error(node, ctx)
      end

      check_args(node.arguments, ctx)
      check_block(blk, ctx) if blk
      return unless target

      @calls[node] = target
      check_arity(node, target, args.size, !blk.nil?)
      check_typed_array_literals(node, target, args) if target.is_a?(Builtin) && target.name == "[]" && target.namespace != "Array"
    end

    def check_arity(node, target, argc, has_block)
      case target
      when UserFunction
        if argc != target.params.size
          error(node, "wrong number of arguments for #{target.full_name} (given #{argc}, expected #{target.params.size})")
        end
        if target.yields && !has_block
          error(node, "#{target.full_name} uses `yield` but no block is given")
        elsif !target.yields && has_block
          error(node, "#{target.full_name} does not take a block (it has no `yield`)")
        end
      when Builtin
        unless (target.min_arity..target.max_arity).cover?(argc)
          expected = target.min_arity == target.max_arity ? target.min_arity : "#{target.min_arity}..#{target.max_arity == Float::INFINITY ? "" : target.max_arity}"
          error(node, "wrong number of arguments for #{target.full_name} (given #{argc}, expected #{expected})")
        end
        if target.block == :required && !has_block
          error(node, "#{target.full_name} requires a block")
        elsif target.block == :none && has_block
          error(node, "#{target.full_name} does not take a block")
        end
      end
    end

    # `Point[1, 2]` is a Ruby-ism for Point.new; in Sake it is an Array of Point, so literals are certain failures.
    def check_typed_array_literals(node, target, args)
      type = target.namespace
      i = args.index { (lit = literal_type(_1)) && lit != type }
      return unless i
      hints = @data_types[type] ? ["#{type}.new(#{args.map(&:slice).join(", ")}) creates one #{type}; #{type}[...] is an Array of #{type}"] : []
      error(args[i], "#{type}[]: element #{i + 1} must be #{type}, got #{literal_type(args[i])}", hints)
    end

    def check_block(blk, ctx)
      @blocks[blk] = block_params(blk)
      check(blk.body, ctx.dup.tap { _1.in_block = true; _1.in_loop = false })
    end

    def block_params(blk)
      pn = blk.parameters
      case pn
      when nil then []
      when Prism::BlockParametersNode
        ps = pn.parameters
        return [] unless ps
        if ps.optionals.any? || ps.posts.any? || ps.keywords.any? || ps.rest || ps.keyword_rest || ps.block
          error(ps, "only plain block parameters `|a, b|` are supported")
        end
        ps.requireds.map do |r|
          next r.name.to_s if r.is_a?(Prism::RequiredParameterNode)
          error(r, "nested destructuring `#{r.slice}` is not supported; `|a, b|` already destructures a Tuple")
          "_"
        end
      when Prism::ItParametersNode then ["it"]
      when Prism::NumberedParametersNode then (1..pn.maximum).map { "_#{_1}" }
      else
        error(pn, "unsupported block parameters `#{pn.slice}`")
        []
      end
    end

    # Inner scope wins: the current namespace, then top-level functions, then Kernel.
    def resolve_unqualified(node, ctx)
      name = node.name.to_s
      found = (ctx.ns && lookup(ctx.ns, name)) || @functions[nil][name] || @registry.lookup("Kernel", name)
      return found if found

      what = node.variable_call? ? "undefined local variable or function" : "undefined function"
      visible = (ctx.ns ? names_in(ctx.ns) : []) + @functions[nil].keys + @registry.names("Kernel")
      hints = spell(name, visible).map { "did you mean `#{_1}`?" }
      hints.concat(namespaces_defining(name).map { "#{_1}.#{name}(#{node.arguments&.slice})" })
      error(node, "#{what} `#{name}`", hints)
    end

    def resolve_qualified(node, ns)
      name = node.name.to_s
      if ns == "Data" && name == "define"
        return error(node, "Data.define must be assigned to a top-level constant: `Point = Data.define(:x, :y)`")
      end
      if name == "call"
        return error(node, "type scope `#{ns}.(...)` is not supported yet")
      end
      unless @registry.namespace?(ns)
        return error(node.receiver, "undefined type or module `#{ns}`", spell(ns, @registry.namespaces).map { "did you mean `#{_1}`?" })
      end
      found = lookup(ns, name)
      return found if found

      hints = spell(name, names_in(ns)).map { "did you mean `#{ns}.#{_1}`?" }
      others = namespaces_defining(name) - [ns]
      hints << "`#{name}` is defined in #{others.map { "`#{_1}.#{name}`" }.join(", ")}" unless others.empty?
      if (dt = @data_types[ns])
        field = name.delete_suffix("=")
        if dt.fields.include?(field)
          hints << (name.end_with?("=") ? "#{ns}.set_#{field}(obj, value)" : "#{ns}.get_#{field}(obj)")
        end
      end
      error(node, "undefined function `#{ns}.#{name}`", hints)
    end

    def lookup(ns, name) = @functions.fetch(ns, {})[name] || @registry.lookup(ns, name)
    def names_in(ns) = @functions.fetch(ns, {}).keys | @registry.names(ns)

    def namespaces_defining(name)
      (@registry.namespaces_defining(name) | @functions.select { |ns, fs| ns && fs.key?(name) }.keys) - ["BinaryOp"]
    end

    def spell(word, dict) = DidYouMean::SpellChecker.new(dictionary: dict.uniq).correct(word)

    # --- `x.y` on a lowercase receiver ---

    def lowercase_call?(n)
      n.is_a?(Prism::CallNode) && n.receiver && n.call_operator_loc &&
        !(n.receiver.is_a?(Prism::ConstantReadNode) || n.receiver.is_a?(Prism::ConstantPathNode))
    end

    # One diagnostic per chain: `s.strip.upcase` is reported once, with the whole chain rewritten.
    def lowercase_receiver_error(node, ctx)
      inner = node
      while lowercase_call?(inner)
        check_args(inner.arguments, ctx)
        check_block(inner.block, ctx) if inner.block.is_a?(Prism::BlockNode)
        inner = inner.receiver
      end
      check(inner, ctx)

      suggestions = node.name == :nil? ? ["#{node.receiver.slice} == nil"] : suggest(node)
      hints = suggestions.empty? ? ["Sake has no method calls on values; call an operation with its type: `Type.#{node.name}(#{node.receiver.slice}, ...)`"] : suggestions
      shown = node.attribute_write? ? "#{node.name.to_s.delete_suffix("=")} = ..." : node.name
      error(node, "method call on a value `#{first_line(node.receiver.slice)}.#{shown}` is not allowed", hints)
    end

    # Rewritten forms of a `x.y(...)` chain; empty if no type defines y.
    def suggest(node)
      return [first_line(node.slice)] unless lowercase_call?(node)

      name = node.name.to_s
      recvs = suggest(node.receiver)
      recv = recvs.size == 1 ? recvs.first : node.receiver.slice
      args = (node.arguments&.arguments || []).map(&:slice)
      blk = node.block ? " #{node.block.slice.include?("\n") ? "{ ... }" : node.block.slice}" : ""

      candidates =
        if node.attribute_write?
          field = name.delete_suffix("=")
          @data_types.values.select { _1.fields.include?(field) }.map { "#{_1.name}.set_#{field}" }
        else
          getters = @data_types.values.select { _1.fields.include?(name) }.map { "#{_1.name}.get_#{name}" }
          ops = namespaces_defining(name)
          if (lit = literal_type(node.receiver)) && ops.include?(lit)
            ops = [lit]
          end
          ops = ops.map { "#{_1}.#{name}" }
          if (getters + ops).empty?
            all = @registry.namespaces.flat_map { |ns| names_in(ns).map { "#{ns}.#{_1}" } }
            ops = all.select { |q| spell(name, [q.split(".", 2).last]).any? }
          end
          getters + ops
        end
      candidates.map { "#{_1}(#{[recv, *args].join(", ")})#{blk}" }
    end

    def literal_type(n)
      case n
      when Prism::StringNode then "String"
      when Prism::IntegerNode then "Integer"
      when Prism::FloatNode then "Float"
      when Prism::ArrayNode then "Tuple"
      when Prism::NilNode then "nil"
      when Prism::TrueNode then "true"
      when Prism::FalseNode then "false"
      end
    end

    def first_line(s) = s.lines.first.chomp
  end
end
