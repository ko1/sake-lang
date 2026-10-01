# frozen_string_literal: true

require "prism"
require "did_you_mean"

module Sake
  # origin / include_node: set on a copy of an included module's function; the copy's body is resolved
  # in the including namespace.
  # module_function: callable as M.f (static). Other functions of a module are mixin functions:
  # M.f(x) dispatches to the f of x's type, which must include M.
  UserFunction = Struct.new(:namespace, :name, :params, :body, :node, :yields, :origin, :include_node, :module_function) do
    def full_name = namespace ? "#{namespace}.#{name}" : name
  end

  # `@x` inside a function of a Struct type: field x of the function's first parameter.
  FieldAccess = Struct.new(:getter, :setter, :param)

  # `M.f(x, ...)` for a mixin function f of module M: table maps each type including M to its f.
  Dispatch = Struct.new(:module, :name, :table)


  # calls: node => {namespace (nil = top level) => target}, because a function body included into several
  # namespaces resolves once per namespace. blocks: node => parameter names.
  # includes: namespace => names of the modules it includes (for dispatch through modules and operators).
  Program = Struct.new(:path, :registry, :toplevel, :calls, :blocks, :functions, :struct_types, :includes, keyword_init: true)

  # Static pass: collects definitions, resolves every call, and reports all errors before running.
  class Resolver
    BINARY_OPS = %i[+ - * / % ** == != < <= > >= <=> & | ^ << >> =~ !~].freeze
    UNARY_OPS = %i[-@ +@ ! ~].freeze
    FORBIDDEN = %w[send __send__ public_send method_missing define_method eval instance_eval class_eval
                   module_eval instance_exec class_exec instance_variable_get instance_variable_set
                   const_get const_set binding].freeze
    # trait: checking a module's own function while the module is included somewhere; names it lacks
    # are requirements on the including namespace, not errors.
    Ctx = Struct.new(:ns, :fn, :in_block, :in_loop, :trait, :in_rescue)
    # Raised by operations, and rescuable by name. Program errors (NOT_RESCUABLE) are what the checks before
    # running report, so they cannot be rescued.
    BUILTIN_EXCEPTIONS = %w[RuntimeError ArgumentError KeyError IndexError ZeroDivisionError RangeError IOError
                            RegexpError FloatDomainError Math::DomainError].freeze
    NOT_RESCUABLE = %w[TypeError NoMatchingPatternError SystemStackError].freeze
    BUILTIN_TYPES = %w[Integer Float Rational Complex String Array Tuple Hash Set Range Symbol Regexp MatchData Time].freeze

    def initialize(path, root, registry)
      @path = path
      @root = root
      @registry = registry
      @functions = {} # namespace (nil = top level) => name => UserFunction
      @struct_types = {}
      @value_constants = {} # rejected `NAME = value` => suggested function name
      @modules = {}         # module name => ModuleNode
      @module_function_names = {} # module => names given to `module_function :name`
      @includes = {} # namespace => [[module name, include node]]
      @requirements = Hash.new { |h, k| h[k] = [] } # module's own function => names it needs from includers
      @direct_calls = []    # [node, function] calls that must not reach a function with requirements
      (BUILTIN_EXCEPTIONS + NOT_RESCUABLE).each { define_struct(_1, ["message"], exception: true) }
      @registry.define("Exception", :message, ["Any"]) do |e|
        raise Fail.new("TypeError", "Exception.message: argument 1 must be an exception, got #{Values.describe(e)}") unless e.is_a?(StructValue) && e.type.exception
        e.values[0]
      end
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
                  functions: @functions, struct_types: @struct_types,
                  includes: @linearized.transform_values { |l| l.map(&:first) })
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
      # Struct types first so that `class Point` bodies can see their accessors.
      stmts.grep(Prism::ConstantWriteNode).each { collect_constant(_1) }
      stmts.grep(Prism::ClassNode).select { _1.superclass.is_a?(Prism::HashNode) }.each { collect_class_config(_1) }
      stmts.each do |st|
        case st
        when Prism::ConstantWriteNode then nil
        when Prism::DefNode then collect_def(st, nil)
        when Prism::ClassNode, Prism::ModuleNode then collect_namespace(st)
        else @toplevel << st
        end
      end
      apply_module_function_names
      apply_includes
    end

    # Copies each included module's functions into the including namespace (own definitions win).
    def apply_module_function_names
      @module_function_names.each do |ns, names|
        names.each do |n|
          fn = @functions.dig(ns, n)
          fn ? fn.module_function = true : error(@modules[ns], "module_function :#{n}: #{ns} has no function #{n}")
        end
      end
    end

    def apply_includes
      @includes.each do |ns, list|
        list.each do |mod, node|
          next if Operators::MODULES.include?(mod)
          error(node, "`include #{mod}`: #{mod} is not a module", @struct_types[mod] || BUILTIN_TYPES.include?(mod) ? ["only a `module` can be included"] : []) unless @modules.key?(mod)
        end
      end
      @linearized = {}
      @includes.each_key do |ns|
        (@linearized[ns] = linearize(ns, [])).each do |mod, node|
          (@functions[mod] || {}).each do |name, fn|
            next if fn.origin || lookup(ns, name)
            (@functions[ns] ||= {})[name] = fn.dup.tap do |c|
              c.namespace = ns
              c.origin = mod
              c.include_node = node
            end
          end
        end
      end
    end

    # Modules included by ns in Ruby's ancestor order: the last `include` first, each module once.
    # Earlier entries win, so a later include wins over an earlier one. The include node is the one in ns.
    def linearize(ns, seen)
      return [] if seen.include?(ns)
      @includes.fetch(ns, []).reverse.flat_map do |mod, node|
        next [[mod, node]] if Operators::MODULES.include?(mod)
        next [] unless @modules.key?(mod)
        if seen.include?(mod) || mod == ns
          error(node, "`include #{mod}` makes a cycle")
          next []
        end
        [[mod, node], *linearize(mod, seen + [ns]).map { |m, _| [m, node] }]
      end.uniq(&:first)
    end

    def constant_call?(v, recv, name)
      v.is_a?(Prism::CallNode) && v.receiver.is_a?(Prism::ConstantReadNode) && v.receiver.name == recv && v.name == name
    end

    def struct_new?(v) = constant_call?(v, :Struct, :new)

    def collect_constant(node)
      v = node.value
      if constant_call?(v, :Data, :define)
        # Ruby's Data is immutable; Sake's named types are mutable, which is Ruby's Struct.
        return error(v, "Sake's named types are mutable, so they are made with Struct.new, not Data.define",
                     ["#{node.name} = Struct.new(#{v.arguments&.slice})"])
      end
      exception = constant_call?(v, :Exception, :new)
      unless struct_new?(v) || exception
        fn = node.name.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        @value_constants[node.name] = fn
        return error(node, "Sake has no value constants; only a Struct type can be assigned to a constant",
                     ["define a function instead: `def #{fn} = #{first_line(v.slice)}`"])
      end
      return error(v.block, "#{v.receiver.name}.new with a block is not supported; define functions in `class #{node.name}`") if v.block

      name = node.name.to_s
      fields = (v.arguments&.arguments || []).filter_map do |a|
        a.is_a?(Prism::SymbolNode) ? a.unescaped : error(a, "#{v.receiver.name}.new takes field names as symbols, like `#{v.receiver.name}.new(:x, :y)`")
      end
      fields.unshift("message") if exception && fields.first != "message"
      dup = fields.find { fields.count(_1) > 1 }
      return error(v, "duplicate field `#{dup}` in #{v.receiver.name}.new") if dup
      return error(node, "`#{name}` is already defined") if @struct_types[name] || @registry.namespace?(name)

      define_struct(name, fields, exception:)
    end

    # readers / writers: the fields with a public get_ / set_ (all of them by default).
    # defaults: field => default value (a value type); a non-nil default fixes the field's type.
    def define_struct(name, fields, exception: false, readers: fields, writers: fields, defaults: {})
      field_types = defaults.reject { |_, v| v.nil? }.transform_values { Values.type_of(_1) }
      dt = @struct_types[name] = StructType.new(name, fields, exception, field_types, {}, {})
      return if name.include?("::")
      check = lambda do |f, x|
        want = field_types[f]
        if want && Values.type_of(x) != want
          raise Fail.new("TypeError", "field #{f} of #{name} must be #{want} (fixed by its default), got #{Values.describe(x)}")
        end
      end
      required = fields.size - fields.reverse.take_while { defaults.key?(_1) }.size
      @registry.define(name, :new, fields.take(required).map { "Any" }, optional: fields.drop(required).map { "Any" }) do |*vs|
        vals = fields.each_with_index.map { |f, i| i < vs.size ? vs[i] : defaults[f] }
        fields.zip(vals) { |f, x| check.(f, x) }
        StructValue.new(dt, vals)
      end
      Stdlib.install_typed_array(@registry, name, struct: true)
      Stdlib.define_nil_equality(@registry, name)
      fields.each_with_index do |f, i|
        dt.getters[f] = Builtin.new(namespace: name, name: "get_#{f}", params: [name], optional: [], rest: nil, block: :none,
                                    impl: ->(r) { r.values[i] })
        dt.setters[f] = Builtin.new(namespace: name, name: "set_#{f}", params: [name, "Any"], optional: [], rest: nil, block: :none,
                                    impl: ->(r, x) { check.(f, x); r.values[i] = x })
        @registry.define(name, "get_#{f}", [name], &dt.getters[f].impl) if readers.include?(f)
        @registry.define(name, "set_#{f}", [name, "Any"], &dt.setters[f].impl) if writers.include?(f)
      end
    end

    CONFIG_KEYS = %w[accessor reader writer default exception].freeze
    DEFAULT_LITERALS = [Prism::IntegerNode, Prism::FloatNode, Prism::RationalNode, Prism::StringNode, Prism::SymbolNode,
                        Prism::TrueNode, Prism::FalseNode, Prism::NilNode].freeze

    # `class C < {accessor: [x], reader: [y], writer: [z], default: {y: 0}, exception: true}`
    def collect_class_config(node)
      cp = node.constant_path
      return unless cp.is_a?(Prism::ConstantReadNode)
      name = cp.name.to_s
      return error(cp, "`#{name}` is already defined") if @struct_types[name] || @registry.namespace?(name)

      fields = []
      readers = []
      writers = []
      defaults = {}
      exception = false
      node.superclass.elements.each do |el|
        key = el.is_a?(Prism::AssocNode) && el.key.is_a?(Prism::SymbolNode) ? el.key.unescaped : nil
        unless CONFIG_KEYS.include?(key)
          hints = spell(key.to_s, CONFIG_KEYS).map { "did you mean `#{_1}`?" }
          error(el, "unknown class setting `#{key || el.slice}`", hints + ["settings: #{CONFIG_KEYS.join(", ")}"])
          next
        end
        case key
        when "accessor", "reader", "writer"
          names = config_field_names(el.value) or next
          fields |= names
          readers |= names if key != "writer"
          writers |= names if key != "reader"
        when "default"
          next error(el.value, "default: takes a Record, like `default: {port: 80}`") unless el.value.is_a?(Prism::HashNode)
          el.value.elements.each do |d|
            next error(d, "write a default as `field: value`") unless d.is_a?(Prism::AssocNode) && d.key.is_a?(Prism::SymbolNode)
            next error(d.value, "a default must be a literal number, String, Symbol, true, false, or nil") unless DEFAULT_LITERALS.any? { d.value.is_a?(_1) }
            defaults[d.key.unescaped] = literal_value(d.value)
          end
        when "exception"
          exception = el.value.is_a?(Prism::TrueNode)
          error(el.value, "exception: takes true or false") unless exception || el.value.is_a?(Prism::FalseNode)
        end
      end
      (defaults.keys - fields).each { error(node.superclass, "default for `#{_1}`, which is not a field") }
      if exception && fields.first != "message"
        fields.unshift("message")
        readers |= ["message"]
        writers |= ["message"]
      end
      define_struct(name, fields, exception:, readers:, writers:, defaults:)
    end

    def literal_value(n)
      case n
      when Prism::NilNode then nil
      when Prism::TrueNode then true
      when Prism::FalseNode then false
      when Prism::StringNode then n.unescaped.dup.freeze
      when Prism::SymbolNode then n.unescaped.to_sym
      else n.value
      end
    end

    def config_field_names(list)
      unless list.is_a?(Prism::ArrayNode)
        error(list, "list the fields, like `[x, y]`")
        return nil
      end
      list.elements.filter_map do |e|
        case e
        when Prism::SymbolNode then e.unescaped
        when Prism::CallNode then e.receiver.nil? && e.arguments.nil? ? e.name.to_s : error(e, "a field name, like `x`")
        when Prism::LocalVariableReadNode then e.name.to_s
        else error(e, "a field name, like `x`")
        end
      end
    end

    def collect_namespace(node)
      cp = node.constant_path
      return error(cp, "nested namespace `#{cp.slice}` is not supported") unless cp.is_a?(Prism::ConstantReadNode)

      ns = cp.name.to_s
      if node.is_a?(Prism::ClassNode) && node.superclass && !node.superclass.is_a?(Prism::HashNode)
        child = node.constant_path.slice
        parent = node.superclass.slice
        field = parent.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        error(node.superclass, "Sake has no class inheritance; reuse a type by composition",
              ["#{child} = Struct.new(:#{field}, ...), then #{parent}.f(#{child}.get_#{field}(x))"])
      end
      type = @struct_types.key?(ns) || BUILTIN_TYPES.include?(ns)
      if node.is_a?(Prism::ClassNode) && !type
        error(cp, "`class #{ns}`: #{ns} is not a type; a namespace of functions is a module", ["module #{ns}"])
      elsif node.is_a?(Prism::ModuleNode) && type
        error(cp, "`module #{ns}`: #{ns} is a type; add operations to a type with class", ["class #{ns}"])
      end
      @modules[ns] = node if node.is_a?(Prism::ModuleNode)
      @registry.add_namespace(ns)
      body = node.body
      return if body.nil?
      return error(body, "unsupported syntax in class body") unless body.is_a?(Prism::StatementsNode)

      module_function_all = false
      body.body.each do |st|
        if st.is_a?(Prism::CallNode) && st.receiver.nil? && st.name == :module_function
          next error(st, "module_function is only for modules") unless node.is_a?(Prism::ModuleNode)
          if st.arguments.nil?
            module_function_all = true
          else
            st.arguments.arguments.each do |a|
              next error(a, "module_function takes function names as symbols") unless a.is_a?(Prism::SymbolNode)
              (@module_function_names[ns] ||= []) << a.unescaped
            end
          end
        elsif include_call?(st)
          st.arguments.arguments.each do |a|
            next error(a, "include takes module names") unless a.is_a?(Prism::ConstantReadNode)
            (@includes[ns] ||= []) << [a.name.to_s, st]
          end
        elsif !st.is_a?(Prism::DefNode)
          error(st, "only `def` and `include` are allowed in a class/module body")
        elsif st.receiver
          error(st, "`def #{st.receiver.slice}.#{st.name}` inside `#{cp.slice}`: write `def #{st.name}` (it defines #{ns}.#{st.name})")
        else
          collect_def(st, ns)
          @functions.dig(ns, st.name.to_s)&.module_function = true if module_function_all
        end
      end
    end

    def lookup_unqualified?(ctx, name) = (ctx.ns && lookup(ctx.ns, name)) || @functions.dig(nil, name)

    def include_call?(st)
      st.is_a?(Prism::CallNode) && st.receiver.nil? && st.name == :include && st.arguments && !st.block
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
      # `def M.f` outside the module is like Ruby's `def self.f`: callable as M.f.
      fn.module_function = true if node.receiver.is_a?(Prism::ConstantReadNode)
      if (prev = @functions.dig(ns, name))
        error(node, "`#{fn.full_name}` is already defined at line #{prev.node.location.start_line}")
      elsif ns && @registry.lookup(ns, name)
        error(node, "`#{fn.full_name}` is a built-in operation and cannot be redefined")
      else
        (@functions[ns] ||= {})[name] = fn
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
      # to_s / inspect defined for a type are used by interpolation, puts, p, join, and format.
      @struct_types.each_key do |type|
        %w[to_s inspect].each do |name|
          fn = @functions.dig(type, name) or next
          error(fn.node, "#{type}.#{name} takes exactly one argument (the value to show)") if fn.params.size != 1
          error(fn.node, "#{type}.#{name} cannot take a block") if fn.yields
        end
      end
      traits = @includes.values.flatten(1).map(&:first).to_set
      @functions.each_value do |fs|
        fs.each_value { |f| check(f.body, Ctx.new(f.namespace, f, false, false, !f.origin && traits.include?(f.namespace))) }
      end
      @toplevel.each { check(_1, Ctx.new(nil, nil, false, false, false)) }
      @direct_calls.each do |node, fn|
        next if @requirements[fn].empty?
        includers = @includes.select { |_, l| l.any? { _1[0] == fn.namespace } }.keys
                              .select { |ns| @requirements[fn].all? { lookup(ns, _1) } }
        error(node, "#{fn.full_name} needs #{@requirements[fn].uniq.map { "`#{_1}`" }.join(", ")} from a namespace that includes #{fn.namespace}",
              includers.map { "#{_1}.#{fn.name}(...)" })
      end
    end

    def check(node, ctx)
      case node
      when nil, Prism::IntegerNode, Prism::FloatNode, Prism::RationalNode, Prism::ImaginaryNode, Prism::StringNode, Prism::TrueNode,
           Prism::FalseNode, Prism::NilNode, Prism::LocalVariableReadNode, Prism::ItLocalVariableReadNode
        nil
      when Prism::StatementsNode then node.body.each { check(_1, ctx) }
      when Prism::LocalVariableWriteNode then check(node.value, ctx)
      when Prism::LocalVariableOrWriteNode then check(node.value, ctx)
      when Prism::IndexOperatorWriteNode, Prism::IndexOrWriteNode
        if (node.arguments&.arguments || []).size != 1 || node.block
          error(node, "`#{first_line(node.slice)}` takes one index")
        elsif node.is_a?(Prism::IndexOperatorWriteNode) && !binary_op?(node.binary_operator)
          error(node, "operator `#{node.binary_operator}=` is not supported")
        end
        check(node.receiver, ctx)
        check_args(node.arguments, ctx)
        check(node.value, ctx)
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
      when Prism::HashNode then check_record_literal(node, ctx)
      when Prism::MatchRequiredNode then check_record_pattern(node, ctx)
      when Prism::BeginNode then check_begin(node, ctx)
      when Prism::RescueModifierNode then check_each(ctx, node.expression, node.rescue_expression)
      when Prism::RetryNode then error(node, "`retry` is only allowed in a rescue clause") unless ctx.in_rescue
      when Prism::MatchPredicateNode
        check(node.value, ctx)
        check_pattern(node.pattern, ctx)
      when Prism::CaseMatchNode
        check(node.predicate, ctx)
        node.conditions.each do |c|
          check_pattern(c.pattern, ctx)
          check(c.statements, ctx)
        end
        check(node.else_clause, ctx)
      when Prism::ForNode
        coll = node.collection.slice
        type = literal_type(node.collection) || "Array"
        error(node, "`for` is not supported; iterate with an operation",
              ["#{type}.each(#{coll}) { |#{node.index.slice}| ... }"])
      when Prism::CaseNode
        error(node, "`case`/`when` is not supported (Ruby's `===` dispatches on the receiver); match with `case x` / `in Type`")
      when Prism::InterpolatedStringNode, Prism::InterpolatedSymbolNode, Prism::InterpolatedRegularExpressionNode
        node.parts.each do |part|
          case part
          when Prism::StringNode then nil
          when Prism::EmbeddedStatementsNode then check(part.statements, ctx)
          when Prism::EmbeddedVariableNode then check(part.variable, ctx)
          else error(part, "unsupported part of an interpolated literal")
          end
        end
      when Prism::DefNode then error(node, "`def` must be at the top level or directly in a class/module body")
      when Prism::ClassNode, Prism::ModuleNode then error(node, "class/module must be at the top level")
      when Prism::ConstantWriteNode then error(node, "constant assignment must be at the top level")
      when Prism::ConstantReadNode
        if (fn = @value_constants[node.name])
          error(node, "`#{node.name}` is not defined (Sake has no value constants)", ["call the function instead: `#{fn}`"])
        else
          error(node, "type `#{node.name}` cannot be used as a value")
        end
      when Prism::SelfNode then error(node, "Sake has no `self`")
      when Prism::InstanceVariableReadNode, Prism::InstanceVariableWriteNode, Prism::InstanceVariableOperatorWriteNode
        check_field_shorthand(node, ctx)
      when Prism::SymbolNode, Prism::RegularExpressionNode then nil
      when Prism::RangeNode
        error(node, "a Range needs at least one end") if node.left.nil? && node.right.nil?
        check_each(ctx, node.left, node.right)
      when Prism::NumberedReferenceReadNode, Prism::BackReferenceReadNode, Prism::GlobalVariableReadNode, Prism::GlobalVariableWriteNode
        error(node, "Sake has no global variables (`#{node.slice}`)",
              node.is_a?(Prism::NumberedReferenceReadNode) ? ["keep the match: `m = String.match(s, re)`, then `m[#{node.number}]`"] : [])
      when Prism::MatchWriteNode
        error(node, "named captures do not create local variables in Sake", ["keep the match: `m = Regexp.match(re, s)`, then `m[\"name\"]`"])
      else
        error(node, "unsupported syntax: #{node.type.to_s.delete_suffix("_node").tr("_", " ")} `#{first_line(node.slice)}`")
      end
    end

    def check_field_shorthand(node, ctx)
      check(node.value, ctx) if node.respond_to?(:value)
      field = node.name.to_s.delete_prefix("@")
      dt = ctx.ns && @struct_types[ctx.ns]
      return if ctx.trait # a field of the including Struct type; checked in each includer
      if ctx.fn&.origin && !(dt && dt.fields.include?(field))
        return error(ctx.fn.include_node, "`include #{ctx.fn.origin}` in #{ctx.ns}: #{ctx.fn.origin}.#{ctx.fn.name} uses `#{node.name}`, " \
                                          "but #{ctx.ns} is not a Struct type with field `#{field}` (line #{node.location.start_line})")
      end
      unless ctx.fn && dt
        return error(node, "`#{node.name}` means a field of the first argument, so it is only available in a function of a Struct type",
                     ["outside one, write the accessor: `Type.get_#{field}(obj)`"])
      end
      return error(node, "`#{node.name}` needs a first argument (the #{dt.name}) in #{ctx.fn.full_name}") if ctx.fn.params.empty?
      unless dt.fields.include?(field)
        return error(node, "#{dt.name} has no field `#{field}`", spell(field, dt.fields).map { "did you mean `@#{_1}`?" })
      end
      if node.is_a?(Prism::InstanceVariableOperatorWriteNode) && !binary_op?(node.binary_operator)
        return error(node, "operator `#{node.binary_operator}=` is not supported")
      end
      set_call(node, ctx, FieldAccess.new(dt.getters[field], dt.setters[field], ctx.fn.params.first.to_sym))
    end

    def check_record_literal(node, ctx)
      if node.elements.empty?
        return error(node, "`{}` is an empty Record, not a Hash", ["for a Hash, write `Hash[]`; for a growable list, `Array[]`"])
      end
      seen = []
      node.elements.each do |el|
        unless el.is_a?(Prism::AssocNode)
          error(el, "`#{el.slice}` is not supported in a Record literal")
          next
        end
        key = el.key
        if !key.is_a?(Prism::SymbolNode)
          error(el, "`{#{key.slice} => ...}` is not a Hash in Sake: `{name: value}` makes a Record",
                ["for a Hash, write `Hash[#{key.slice} => ...]`"])
        elsif key.closing_loc&.slice != ":"
          error(el, "write a Record field as `#{key.unescaped}: value`")
        elsif seen.include?(key.unescaped)
          error(el, "duplicate field `#{key.unescaped}` in a Record")
        else
          seen << key.unescaped
        end
        check(el.value, ctx)
      end
    end

    def check_record_pattern(node, ctx)
      check(node.value, ctx)
      pat = node.pattern
      ok = pat.is_a?(Prism::HashPatternNode) && pat.constant.nil? && pat.rest.nil? && !pat.elements.empty? &&
           pat.elements.all? do |el|
             el.is_a?(Prism::AssocNode) && el.key.is_a?(Prism::SymbolNode) &&
               pattern_target(el.value).is_a?(Prism::LocalVariableTargetNode)
           end
      error(node, "only Record patterns that bind fields are supported: `value => {x:, y: name}`") unless ok
    end

    def pattern_target(v) = v.is_a?(Prism::ImplicitNode) ? v.value : v

    PATTERN_TYPES = (BUILTIN_TYPES + %w[Record]).freeze

    # Patterns of `x in P` and `case x in P`: a type name, a literal, `P | Q`, or a Record pattern.
    def check_pattern(pat, ctx)
      case pat
      when Prism::ConstantReadNode
        name = pat.name.to_s
        return if @struct_types.key?(name) || PATTERN_TYPES.include?(name)
        error(pat, "`#{name}` is not a type", spell(name, PATTERN_TYPES + @struct_types.keys).map { "did you mean `#{_1}`?" })
      when Prism::NilNode, Prism::TrueNode, Prism::FalseNode, Prism::IntegerNode, Prism::FloatNode, Prism::StringNode, Prism::SymbolNode
        nil
      when Prism::AlternationPatternNode
        check_pattern(pat.left, ctx)
        check_pattern(pat.right, ctx)
      when Prism::HashPatternNode
        ok = pat.constant.nil? && pat.rest.nil? && !pat.elements.empty? &&
             pat.elements.all? { |el| el.is_a?(Prism::AssocNode) && el.key.is_a?(Prism::SymbolNode) && pattern_target(el.value).is_a?(Prism::LocalVariableTargetNode) }
        error(pat, "only Record patterns that bind fields are supported: `in {x:, y: name}`") unless ok
      else
        error(pat, "unsupported pattern `#{first_line(pat.slice)}`; use a type (`in Integer`), a literal, `A | B`, or `{x:}`")
      end
    end

    def set_call(node, ctx, target) = (@calls[node] ||= {})[ctx.ns] = target

    def check_begin(node, ctx)
      check(node.statements, ctx)
      clause = node.rescue_clause
      while clause
        clause.exceptions.each { check_rescued_type(_1) }
        unless clause.reference.nil? || clause.reference.is_a?(Prism::LocalVariableTargetNode)
          error(clause.reference, "rescue binds a local variable: `rescue T => e`")
        end
        check(clause.statements, ctx.dup.tap { _1.in_rescue = true })
        clause = clause.subsequent
      end
      check(node.else_clause, ctx)
      check(node.ensure_clause&.statements, ctx)
    end

    def exception_name(n)
      case n
      when Prism::ConstantReadNode then n.name.to_s
      when Prism::ConstantPathNode then n.slice
      end
    end

    def check_rescued_type(n)
      name = exception_name(n)
      if NOT_RESCUABLE.include?(name)
        error(n, "#{name} cannot be rescued: it is a program error, which the checks before running report")
      elsif !(name && @struct_types[name]&.exception)
        hint = @struct_types[name.to_s] ? ["declare it with `#{name} = Exception.new(...)`"] : []
        error(n, "`#{n.slice}` is not an exception type", hint)
      end
    end

    # raise; raise "message"; raise exception_value; raise ExceptionType, "message"
    def check_raise(node, ctx)
      args = node.arguments&.arguments || []
      args.each_with_index { |a, i| check(a, ctx) unless i.zero? && args.size == 2 }
      case args.size
      when 0 then error(node, "a bare `raise` re-raises, so it is only allowed in a rescue clause") unless ctx.in_rescue
      when 1 then nil
      when 2
        name = exception_name(args[0])
        dt = name && @struct_types[name]
        if !dt&.exception
          error(args[0], "`raise T, message` needs an exception type, got `#{args[0].slice}`")
        elsif dt.fields.size > 1
          error(args[0], "#{name} has fields besides message; raise it with `raise #{name}.new(...)`")
        end
      else error(node, "raise takes at most an exception type and a message")
      end
      set_call(node, ctx, :raise)
    end

    def check_each(ctx, *nodes) = nodes.each { check(_1, ctx) }

    def check_jump_args(node, ctx)
      args = node.arguments&.arguments || []
      error(node, "`#{node.keyword_loc.slice}` takes at most one value") if args.size > 1
      check_args(node.arguments, ctx)
    end

    def check_args(args_node, ctx, hash_pairs: false)
      (args_node&.arguments || []).each do |a|
        case a
        when Prism::SplatNode then error(a, "splat arguments are not supported")
        when Prism::KeywordHashNode
          if hash_pairs
            a.elements.each do |el|
              next error(el, "`**` is not supported") unless el.is_a?(Prism::AssocNode)
              check(el.key, ctx)
              check(el.value, ctx)
            end
          else
            error(a, "keyword arguments are not supported")
          end
        when Prism::ForwardingArgumentsNode then error(a, "argument forwarding is not supported")
        else check(a, ctx)
        end
      end
    end

    def binary_op?(name) = Operators::MODULE_OF.key?(name.to_s)

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
        return check_raise(node, ctx) if node.name == :raise && !lookup_unqualified?(ctx, "raise")
        target = resolve_unqualified(node, ctx)
      elsif recv.is_a?(Prism::ConstantReadNode) && (node.call_operator_loc || node.name == :[])
        # `T[...]` is the constructor syntax; `T.[](x, k)` is T's index operation.
        target = resolve_qualified(node, recv.name.to_s, node.call_operator_loc ? node.name.to_s : CTOR)
      elsif recv.is_a?(Prism::ConstantPathNode)
        return error(recv, "`#{recv.slice}` (nested constants) is not supported")
      elsif node.call_operator_loc.nil? && BINARY_OPS.include?(node.name) && args.size == 1
        error(node, "operator `#{node.name}` is not supported") unless binary_op?(node.name)
        set_call(node, ctx, Operators::Call.new(Operators::MODULE_OF[node.name.to_s], node.name.to_s))
        check(recv, ctx)
        check_args(node.arguments, ctx)
        return
      elsif node.call_operator_loc.nil? && UNARY_OPS.include?(node.name)
        hint = node.name == :-@ ? ["write `0 - #{recv.slice}`"] : []
        error(node, "unary operator `#{node.slice}` is not supported yet (undecided)", hint)
        return check(recv, ctx)
      elsif node.call_operator_loc.nil? && %i[[] []=].include?(node.name)
        want = node.name == :[] ? 1 : 2
        if args.size != want
          error(node, "`#{first_line(node.slice)}` takes #{want == 1 ? "one index" : "one index and a value"}")
        else
          set_call(node, ctx, Operators::Call.new("Indexable", node.name.to_s))
        end
        check(recv, ctx)
        return check_args(node.arguments, ctx)
      else
        return lowercase_receiver_error(node, ctx)
      end

      hash_ctor = recv.is_a?(Prism::ConstantReadNode) && recv.name == :Hash && node.name == :[]
      if hash_ctor && !(args.empty? || (args.size == 1 && args[0].is_a?(Prism::KeywordHashNode)))
        error(node, "Hash[...] takes `key => value` pairs, like `Hash[\"a\" => 1]`")
      end
      check_args(node.arguments, ctx, hash_pairs: hash_ctor)
      check_block(blk, ctx) if blk
      return unless target

      set_call(node, ctx, target)
      check_arity(node, target, args.size, !blk.nil?)
      check_typed_array_literals(node, target, args) if target.is_a?(Builtin) && target.name == CTOR && !%w[Array Hash Set].include?(target.namespace)
    end

    def check_arity(node, target, argc, has_block)
      case target
      when Operators::Call
        want = target.op == "[]=" ? 3 : 2
        error(node, "#{target.module}.#{target.op} takes #{want} arguments (given #{argc})") if argc != want
      when Dispatch
        fn = @functions.dig(target.module, target.name)
        check_arity(node, fn, argc, has_block) if fn
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
        if target.block == :optional
          nil
        elsif target.block == :required && !has_block
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
      hints = @struct_types[type] ? ["#{type}.new(#{args.map(&:slice).join(", ")}) creates one #{type}; #{type}[...] is an Array of #{type}"] : []
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
      found = (ctx.ns && lookup(ctx.ns, name)) || @functions.dig(nil, name) || @registry.lookup("Kernel", name)
      if found
        @direct_calls << [node, found] if found.is_a?(UserFunction) && !ctx.trait
        return found
      end
      if ctx.trait
        @requirements[ctx.fn] << name
        return nil
      end
      if ctx.fn&.origin
        return error(ctx.fn.include_node, "`include #{ctx.fn.origin}` in #{ctx.ns}: #{ctx.fn.origin}.#{ctx.fn.name} needs `#{name}`, " \
                                          "which #{ctx.ns} does not define (used at line #{node.location.start_line})")
      end

      what = node.variable_call? ? "undefined local variable or function" : "undefined function"
      visible = (ctx.ns ? names_in(ctx.ns) : []) + @functions.fetch(nil, {}).keys + @registry.names("Kernel")
      hints = spell(name, visible).map { "did you mean `#{_1}`?" }
      hints.concat(namespaces_defining(name).map { "#{_1}.#{name}(#{node.arguments&.slice})" })
      error(node, "#{what} `#{name}`", hints)
    end

    def resolve_qualified(node, ns, name = node.name.to_s)
      if (ns == "Struct" && name == "new") || (ns == "Data" && name == "define")
        return error(node, "Struct.new must be assigned to a top-level constant: `Point = Struct.new(:x, :y)`")
      end
      if name == "call"
        return error(node, "type scope `#{ns}.(...)` is not supported yet")
      end
      if (old = { "BinaryOp" => "Arithmetic", "Index" => "Indexable" }[ns])
        return error(node.receiver, "`#{ns}` is now `#{Operators::MODULE_OF[name] || old}`")
      end
      if (Operators::MODULES.include?(ns) || ns == "Kernel") && Operators::MODULE_OF[name] == ns
        return error(node, "#{ns}.#{name} dispatches on its first argument, so it needs one") if (node.arguments&.arguments || []).empty?
        return Operators::Call.new(ns, name)
      end
      unless @registry.namespace?(ns)
        return error(node.receiver, "undefined type or module `#{ns}`", spell(ns, @registry.namespaces).map { "did you mean `#{_1}`?" })
      end
      found = lookup(ns, name)
      return mixin_call(node, ns, name, found) if found.is_a?(UserFunction) && @modules.key?(ns) && !found.module_function
      if found
        @direct_calls << [node, found] if found.is_a?(UserFunction)
        return found
      end

      hints = spell(name, names_in(ns)).map { "did you mean `#{ns}.#{_1}`?" }
      others = namespaces_defining(name) - [ns]
      hints << "`#{name}` is defined in #{others.map { "`#{_1}.#{name}`" }.join(", ")}" unless others.empty?
      if (dt = @struct_types[ns]) && name =~ /\A(get|set)_(.+)\z/ && dt.fields.include?($2)
        kind = $1 == "set" ? "read-only (reader)" : "write-only (writer)"
        return error(node, "field `#{$2}` of #{ns} is #{kind}",
                     ["inside `class #{ns}`, use `@#{$2}#{$1 == "set" ? " = value" : ""}`; or list it under `accessor:`"])
      end
      if (dt = @struct_types[ns])
        field = name.delete_suffix("=")
        if dt.fields.include?(field)
          hints << (name.end_with?("=") ? "#{ns}.set_#{field}(obj, value)" : "#{ns}.get_#{field}(obj)")
        end
      end
      error(node, "undefined function `#{ns}.#{name}`", hints)
    end

    # M.f(x) for a mixin function: dispatch on the type of x among the types that include M.
    def mixin_call(node, mod, name, fn)
      if (node.arguments&.arguments || []).empty?
        return error(node, "#{mod}.#{name} is a mixin function: it has no subject to dispatch on",
                     ["call it on a type that includes #{mod}, or mark it with `module_function`"])
      end
      types = @linearized.select { |t, mods| (@struct_types.key?(t) || BUILTIN_TYPES.include?(t)) && mods.any? { _1[0] == mod } }.keys
      if types.empty?
        return error(node, "#{mod}.#{name} is a mixin function, and no type includes #{mod}",
                     ["to call it as #{mod}.#{name}(...), mark it with `module_function`"])
      end
      table = types.to_h { |t| [t, lookup(t, name)] }
      table.each do |t, impl|
        next if impl.is_a?(UserFunction) && impl.params.size == fn.params.size && impl.yields == fn.yields
        error(node, "#{mod}.#{name} dispatches to #{t}.#{name}, whose arguments or block differ from #{mod}.#{name}")
      end
      Dispatch.new(mod, name, table)
    end

    def lookup(ns, name) = @functions.fetch(ns, {})[name] || @registry.lookup(ns, name)
    def names_in(ns) = @functions.fetch(ns, {}).keys | @registry.names(ns)

    def namespaces_defining(name)
      (@registry.namespaces_defining(name) | @functions.select { |ns, fs| ns && fs.key?(name) }.keys) - Operators::MODULES
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
          @struct_types.values.select { _1.fields.include?(field) }.map { "#{_1.name}.set_#{field}" }
        else
          getters = @struct_types.values.select { _1.fields.include?(name) }.map { "#{_1.name}.get_#{name}" }
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
      when Prism::RationalNode then "Rational"
      when Prism::ImaginaryNode then "Complex"
      when Prism::ArrayNode then "Tuple"
      when Prism::SymbolNode then "Symbol"
      when Prism::RangeNode then "Range"
      when Prism::RegularExpressionNode then "Regexp"
      when Prism::ParenthesesNode then n.body.is_a?(Prism::StatementsNode) && n.body.body.size == 1 ? literal_type(n.body.body.first) : nil
      when Prism::NilNode then "nil"
      when Prism::TrueNode then "true"
      when Prism::FalseNode then "false"
      end
    end

    def first_line(s) = s.lines.first.chomp
  end
end
