# frozen_string_literal: true

require "prism"
require "did_you_mean"

module Sake
  # origin / include_node: set on a copy of an included module's function; the copy's body is resolved
  # in the including namespace.
  # module_function: callable as M.f (static). Other functions of a module are mixin functions:
  # M.f(x) dispatches to the f of x's type, which must include M.
  # abstract: the body is only `raise NotImplementedError`: each type that includes the module defines it.
  # params: every parameter's name, positional ones first; defaults: the default expressions of the
  # trailing optional positional ones; keywords: keyword parameter name => default expression (nil: required).
  UserFunction = Struct.new(:namespace, :name, :params, :body, :node, :yields, :origin, :include_node, :module_function, :abstract, :defaults, :keywords, :block_optional, :block_param) do
    def full_name = namespace ? "#{namespace}.#{name}" : name
    def positional = params.size - (keywords || {}).size
    def min_arity = positional - (defaults || []).size
    def keyword_shape = (keywords || {}).transform_values(&:nil?)
  end

  # `@x` inside a function of a Struct type: field x of the function's first parameter.
  FieldAccess = Struct.new(:getter, :setter, :param)

  # `M.f(x, ...)` for a mixin function f of module M: table maps each type including M to its f.
  Dispatch = Struct.new(:module, :name, :table)
  # `|a, *rest|`: the rest parameter among a block's parameters (name nil for a bare `*`).
  RestParam = Struct.new(:name)

  # `(A|B).f(x, ...)`: table maps each listed type to its f; x's type picks one.
  UnionCall = Struct.new(:types, :name, :table) do
    def full_name = "(#{types.join("|")}).#{name}"
  end


  # calls: node => {namespace (nil = top level) => target}, because a function body included into several
  # namespaces resolves once per namespace. blocks: node => parameter names.
  # includes: namespace => names of the modules it includes (for dispatch through modules and operators).
  # path: the main file; sources: Prism source => file (for the file of a node, see Sake.file_of).
  Program = Struct.new(:path, :registry, :toplevel, :calls, :blocks, :functions, :struct_types, :includes, :sources, keyword_init: true)

  # Static pass: collects definitions, resolves every call, and reports all errors before running.
  class Resolver
    BINARY_OPS = %i[+ - * / % ** == != < <= > >= <=> & | ^ << >> =~ !~].freeze
    UNARY_OPS = %i[-@ +@ ! ~].freeze
    FORBIDDEN = %w[send __send__ public_send method_missing define_method eval instance_eval class_eval
                   module_eval instance_exec class_exec instance_variable_get instance_variable_set
                   const_get const_set binding].freeze
    # trait: checking a module's own function while the module is included somewhere; names it lacks
    # are requirements on the including namespace, not errors.
    # prev: a statement precedes this one in its list, so `_` (its value) can be read.
    Ctx = Struct.new(:ns, :fn, :in_block, :in_loop, :trait, :in_rescue, :prev)
    # Raised by operations, and rescuable by name. Program errors (NOT_RESCUABLE) are what the checks before
    # running report, so they cannot be rescued.
    BUILTIN_EXCEPTIONS = %w[RuntimeError ArgumentError KeyError IndexError ZeroDivisionError RangeError IOError EncodingError
                            RegexpError FloatDomainError Math::DomainError].freeze
    NOT_RESCUABLE = %w[TypeError NoMatchingPatternError SystemStackError NotImplementedError LocalJumpError].freeze
    BUILTIN_TYPES = %w[Integer Float Rational Complex String Array Tuple Hash Set Range Symbol Regexp MatchData Time].freeze

    # `require "x"`: a call with no receiver, read by Sake.load before resolving.
    def self.require_call?(node) = node.is_a?(Prism::CallNode) && node.name == :require && node.receiver.nil?

    # files: [path, ProgramNode], in the order their top-level statements run.
    def initialize(path, files, registry, sources = {}.compare_by_identity)
      @path = path
      @files = files
      @sources = sources
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
      # A function included into several namespaces is checked once per namespace; report each problem once.
      order = @files.each_with_index.to_h { |(f, _), i| [f, i] }
      diags = @diags.uniq { [_1.path, _1.line, _1.column, _1.message] }.sort_by { [order.fetch(_1.path, 0), _1.line, _1.column] }
      raise StaticErrors.new(diags) unless @diags.empty?
      Program.new(path: @path, registry: @registry, toplevel: @toplevel, calls: @calls, blocks: @blocks, sources: @sources,
                  functions: @functions, struct_types: @struct_types,
                  includes: @linearized.transform_values { |l| l.map(&:first) })
    end

    private

    def error(node, message, hints = [])
      loc = node.respond_to?(:message_loc) && node.message_loc ? node.message_loc : node.location
      @diags << Diagnostic.new(@sources[node.location.send(:source)] || @path, loc.start_line, loc.start_column, message, hints)
      nil
    end

    # --- collect definitions ---

    def collect
      stmts = @files.flat_map { |_, root| root.statements.body }.reject { Resolver.require_call?(_1) }
      # Struct types first so that `class Point` bodies can see their accessors.
      stmts.grep(Prism::ConstantWriteNode).each { collect_constant(_1) }
      @class_nodes = stmts.grep(Prism::ClassNode).select { _1.constant_path.is_a?(Prism::ConstantReadNode) }.group_by { _1.constant_path.name.to_s }
      @class_specs = {}
      @module_names = stmts.grep(Prism::ModuleNode).map { _1.constant_path.slice }.to_set | Operators::MODULES
      @class_nodes.each_key { class_spec(_1, []) }
      stmts.each do |st|
        case st
        when Prism::ConstantWriteNode then nil
        when Prism::DefNode then collect_def(st, nil)
        when Prism::ClassNode, Prism::ModuleNode then collect_namespace(st)
        else @toplevel << st
        end
      end
      apply_pastes
      apply_module_function_names
      apply_includes
    end

    # `class B < A`: A's definitions written again in B (its fields first, its functions, its includes).
    # Nothing relates A and B afterwards. B's own definitions win over the pasted ones.
    def apply_pastes
      done = {}
      paste = lambda do |name|
        next if done[name]
        done[name] = true
        parent = @class_specs.dig(name, :parent) or next
        paste.(parent)
        (@functions[parent] || {}).each do |fname, fn|
          next if fn.origin || @functions.dig(name, fname)
          (@functions[name] ||= {})[fname] = fn.dup.tap { _1.namespace = name }
        end
        @includes[name] = [*@includes.fetch(parent, []), *@includes.fetch(name, [])] if @includes.key?(parent)
      end
      @class_specs.each_key { paste.(_1) }
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
    # defaults: field => default value (a literal): only the value `new` stores when the argument is left
    # out. It does not fix the field's type: types come from operations, as for every other variable.
    def define_struct(name, fields, exception: false, readers: fields, writers: fields, defaults: {})
      literal = defaults.reject { |_, v| v.is_a?(ExprDefault) }
      dt = @struct_types[name] = StructType.new(name, fields, exception, literal.transform_values { Values.type_of(_1) }, {}, {})
      defaults = defaults.transform_values { _1.is_a?(ExprDefault) ? DEFAULT_PENDING : _1 }
      return if name.include?("::")
      required = fields.size - fields.reverse.take_while { defaults.key?(_1) }.size
      @registry.define(name, :new, fields.take(required).map { "Any" }, optional: fields.drop(required).map { "Any" }) do |*vs|
        StructValue.new(dt, fields.each_with_index.map { |f, i| i < vs.size ? vs[i] : defaults[f] })
      end
      Stdlib.install_typed_array(@registry, name, struct: true)
      Stdlib.define_nil_equality(@registry, name)
      fields.each_with_index do |f, i|
        dt.getters[f] = Builtin.new(namespace: name, name: "get_#{f}", params: [name], optional: [], rest: nil, block: :none,
                                    impl: ->(r) { r.values[i] })
        dt.setters[f] = Builtin.new(namespace: name, name: "set_#{f}", params: [name, "Any"], optional: [], rest: nil, block: :none,
                                    impl: ->(r, x) { r.values[i] = x })
        @registry.define(name, "get_#{f}", [name], &dt.getters[f].impl) if readers.include?(f)
        @registry.define(name, "set_#{f}", [name, "Any"], &dt.setters[f].impl) if writers.include?(f)
      end
    end

    # `attr_reader items = Array[]`: an expression default, evaluated by `new` each time (as Ruby's
    # `@items = []` in initialize), by the function DEFAULT_PREFIX + field of the type.
    ExprDefault = Struct.new(:expr)
    DEFAULT_PREFIX = "(default) "

    DEFAULT_LITERALS = [Prism::IntegerNode, Prism::FloatNode, Prism::RationalNode, Prism::StringNode, Prism::SymbolNode,
                        Prism::TrueNode, Prism::FalseNode, Prism::NilNode].freeze
    ATTRS = { attr_reader: [true, false], attr_accessor: [true, true], attr_writer: [false, true] }.freeze
    EXCEPTION_PARENTS = %w[Exception StandardError].freeze

    def attr_call?(st) = st.is_a?(Prism::CallNode) && st.receiver.nil? && (ATTRS.key?(st.name) || private_attr?(st))

    # `private attr_reader pos`: a field with no get_/set_ outside its class (`@pos` inside); new still takes it.
    def private_attr?(st)
      st.name == :private && st.arguments&.arguments&.size == 1 && (a = st.arguments.arguments[0]).is_a?(Prism::CallNode) &&
        a.receiver.nil? && ATTRS.key?(a.name)
    end

    # The type a `class C` declares: `< A` pastes A's fields (or makes an exception type), then the
    # `attr_reader x, y` / `attr_accessor n = 0` / `attr_writer w` lines of C's first class body.
    def class_spec(name, seen)
      return @class_specs[name] if @class_specs.key?(name)
      nodes = @class_nodes[name]
      first = nodes.first
      if BUILTIN_TYPES.include?(name) || @struct_types.key?(name) || @registry.namespace?(name)
        nodes.each do |n|
          error(n.superclass, "`class #{name}` adds functions to #{name}; `<` goes on a new class") if n.superclass
          attr_lines(n).each { error(_1, "#{name}'s fields are already declared#{@struct_types.key?(name) ? " by Struct.new" : ""}") }
        end
        return @class_specs[name] = nil
      end
      nodes.drop(1).each do |n|
        error(n.superclass, "`<` goes on the first `class #{name}` (line #{first.location.start_line})") if n.superclass
        attr_lines(n).each { error(_1, "the fields of #{name} are declared in its first `class #{name}` (line #{first.location.start_line})") }
      end
      spec = { fields: [], readers: [], writers: [], defaults: {}, exception: false, parent: nil }
      if (sup = first.superclass)
        if sup.is_a?(Prism::HashNode)
          error(sup, "`class #{name} < {...}` is the old form of declaring fields", ["write them in the body: #{old_settings_hint(sup)}"])
        elsif !sup.is_a?(Prism::ConstantReadNode)
          error(sup, "`class #{name} < X` takes a class name: B < A writes A's definitions into B")
        elsif EXCEPTION_PARENTS.include?(pname = sup.name.to_s)
          spec[:exception] = true
          spec.merge!(fields: ["message"], readers: ["message"], writers: ["message"])
        elsif seen.include?(pname) || pname == name
          error(sup, "`class #{name} < #{pname}` makes a cycle")
        elsif @class_nodes.key?(pname) && (ps = class_spec(pname, seen + [name]))
          spec = ps.transform_values { _1.dup }.merge(parent: pname)
        elsif (dt = @struct_types[pname]) && !@class_nodes.key?(pname)
          spec.merge!(fields: dt.fields.dup, readers: dt.fields.dup, writers: dt.fields.dup, exception: dt.exception, parent: pname)
        else
          error(sup, "`class #{name} < #{pname}`: #{pname} is not a class of this program",
                @module_names.include?(pname) ? ["to borrow a module's functions, write `include #{pname}` in the body"] : [])
        end
      end
      attr_lines(first).each do |st|
        priv = st.name == :private
        st = st.arguments.arguments[0] if priv
        reader, writer = ATTRS.fetch(st.name)
        reader = writer = false if priv
        (st.arguments&.arguments || []).each do |a|
          fname, default = attr_field(a)
          next unless fname
          next error(a, "field `#{fname}` is declared twice in #{name}") if spec[:fields].include?(fname)
          spec[:fields] << fname
          spec[:readers] << fname if reader
          spec[:writers] << fname if writer
          spec[:defaults][fname] = default if a.is_a?(Prism::LocalVariableWriteNode)
        end
      end
      d = spec[:fields].reverse.take_while { spec[:defaults].key?(_1) }.size
      (spec[:defaults].keys - spec[:fields].last(d)).each do |f|
        error(first, "field `#{f}` has a default, so the fields after it need defaults too (they may be left out of #{name}.new)")
      end
      define_struct(name, spec[:fields], exception: spec[:exception], readers: spec[:readers], writers: spec[:writers], defaults: spec[:defaults])
      spec[:defaults].each do |f, d|
        next unless d.is_a?(ExprDefault)
        fn = UserFunction.new(name, "#{DEFAULT_PREFIX}#{f}", [], d.expr, d.expr, yields?(d.expr))
        fn.defaults = []
        fn.keywords = {}
        (@functions[name] ||= {})["#{DEFAULT_PREFIX}#{f}"] = fn
      end
      @class_specs[name] = spec
    end

    def attr_lines(node)
      node.body.is_a?(Prism::StatementsNode) ? node.body.body.select { attr_call?(_1) } : []
    end

    # `x` (a field) or `n = 0` (a field with a default, a literal): [name, default].
    def attr_field(a)
      case a
      when Prism::CallNode then return [a.name.to_s, nil] if a.receiver.nil? && a.arguments.nil? && a.block.nil?
      when Prism::LocalVariableReadNode then return [a.name.to_s, nil]
      when Prism::LocalVariableWriteNode
        return [a.name.to_s, literal_value(a.value)] if DEFAULT_LITERALS.any? { a.value.is_a?(_1) }
        return [a.name.to_s, ExprDefault.new(a.value)] # evaluated at each new that leaves the field out
      when Prism::SymbolNode
        error(a, "write the field's name without `:`: `#{a.unescaped}`")
        return [a.unescaped, nil]
      end
      error(a, "a field name, like `x`, or a field with a default, like `n = 0`")
      nil
    end

    # The body lines for an old `< {reader: [...], ...}` (for the error's hint).
    def old_settings_hint(hash)
      hash.elements.filter_map do |el|
        next unless el.is_a?(Prism::AssocNode) && el.key.is_a?(Prism::SymbolNode) && el.value.is_a?(Prism::ArrayNode)
        "attr_#{el.key.unescaped} #{el.value.elements.map { _1.slice.delete_prefix(":") }.join(", ")}"
      end.join("; ")
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

    def collect_namespace(node)
      cp = node.constant_path
      return error(cp, "nested namespace `#{cp.slice}` is not supported") unless cp.is_a?(Prism::ConstantReadNode)

      ns = cp.name.to_s
      type = @struct_types.key?(ns) || BUILTIN_TYPES.include?(ns)
      if node.is_a?(Prism::ModuleNode) && type
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
        elsif attr_call?(st)
          error(st, "a module has no fields; `#{st.name}` is for a class") if node.is_a?(Prism::ModuleNode)
        elsif !st.is_a?(Prism::DefNode)
          hint = st.is_a?(Prism::CallNode) && st.name.start_with?("attr") ? spell(st.name.to_s, ATTRS.keys.map(&:to_s)).map { "did you mean `#{_1}`?" } : []
          error(st, "only `def`, `include`, and (in a class) `attr_reader`/`attr_accessor`/`attr_writer` are allowed in a class/module body", hint)
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
      # `&b` (or `&`): the function's block, which it may pass on as `&b`; it then takes a block too.
      if (bp = node.parameters&.block)
        fn.block_param = bp.name&.to_s || "&"
        fn.yields = true
      end
      fn.defaults = node.parameters ? node.parameters.optionals.map(&:value) : []
      # `&b` only passed on is optional, as in Ruby: passing none to a call that needs one is caught there.
      fn.block_optional = fn.yields && (calls_block_given?(node.body) || !yields?(node.body))
      fn.keywords = (node.parameters&.keywords || []).to_h { [_1.name.to_s, _1.is_a?(Prism::OptionalKeywordParameterNode) ? _1.value : nil] }
      # `def M.f` outside the module is like Ruby's `def self.f`: callable as M.f.
      fn.module_function = true if node.receiver.is_a?(Prism::ConstantReadNode)
      fn.abstract = abstract_body?(node.body)
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
      if pn.posts.any? || pn.rest || pn.keyword_rest
        error(pn, "only required, optional (`b = 1`) and keyword (`c:`, `d: 2`) parameters, in that order, are supported (got `#{pn.slice}`)")
      end
      pn.requireds.map do |r|
        r.is_a?(Prism::RequiredParameterNode) ? r.name.to_s : (error(r, "parameter destructuring is not supported"); "_")
      end + pn.optionals.map { _1.name.to_s } + pn.keywords.map { _1.name.to_s }
    end

    def calls_block_given?(node)
      return false if node.nil?
      return true if node.is_a?(Prism::CallNode) && node.name == :block_given? && node.receiver.nil?
      node.compact_child_nodes.any? { calls_block_given?(_1) }
    end

    def yields?(node)
      return false if node.nil?
      node.is_a?(Prism::YieldNode) || node.compact_child_nodes.any? { yields?(_1) }
    end

    # --- check bodies ---

    def check_all
      # initialize(c) runs after T.new has stored the fields: checks and conversions on every construction.
      @struct_types.each_key do |type|
        fn = @functions.dig(type, "initialize") or next
        error(fn.node, "#{type}.initialize takes exactly one parameter, the new instance (T.new stores the fields first)") if fn.params.size != 1
        error(fn.node, "#{type}.initialize cannot take a block") if fn.yields
      end
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
        # A module's mixin function is checked as a trait even before any type includes the module (a library
        # module its program does not use yet): the names it lacks are what includers must define.
        fs.each_value do |f|
          trait = !f.origin && (traits.include?(f.namespace) || (f.namespace && !@struct_types.key?(f.namespace) && !f.module_function))
          ctx = Ctx.new(f.namespace, f, false, false, trait)
          [*f.defaults, *(f.keywords || {}).values].compact.each { check(_1, ctx) }
          check(f.body, ctx)
        end
      end
      # `_` after a definition has no value to read: only an expression statement counts as previous.
      @toplevel.each do |st|
        body = @files.map { |_, root| root.statements.body }.find { |b| b.any? { _1.equal?(st) } }
        i = body.index { _1.equal?(st) }
        prev = i.positive? && !definition?(body[i - 1]) && !Resolver.require_call?(body[i - 1])
        check(st, Ctx.new(nil, nil, false, false, false, false, prev))
      end
      @direct_calls.each do |node, fn|
        next if @requirements[fn].empty?
        includers = @includes.select { |_, l| l.any? { _1[0] == fn.namespace } }.keys
                              .select { |ns| @requirements[fn].all? { lookup(ns, _1) } }
        error(node, "#{fn.full_name} needs #{@requirements[fn].uniq.map { "`#{_1}`" }.join(", ")} from a namespace that includes #{fn.namespace}",
              includers.map { "#{_1}.#{fn.name}(...)" })
      end
    end

    def definition?(n) = n.is_a?(Prism::DefNode) || n.is_a?(Prism::ClassNode) || n.is_a?(Prism::ModuleNode) || n.is_a?(Prism::ConstantWriteNode)

    # Each statement after the first can read the previous one's value as `_`. In parentheses and
    # interpolation the first statement sees what the enclosing statement sees.
    def check_statements(list, ctx, inherit: false)
      list.body.each_with_index do |st, i|
        check(st, ctx.dup.tap { _1.prev = i.positive? || (inherit && ctx.prev) })
      end
    end

    def check(node, ctx)
      case node
      when Prism::ImplicitNode then check(node.value, ctx) # `k:` in `f(k:)` or `{k:}`: the variable (or function) k
      when Prism::LocalVariableReadNode
        if ctx.fn&.block_param == node.name.to_s
          error(node, "the block parameter `#{node.name}` can only be passed on as `&#{node.name}`",
                ["call the block with `yield`; Sake has no block values"])
        end
        if node.name == :_
          error(node, "`_` is the previous statement's value, but here it names a local variable", ["give the variable another name"])
        end
      when nil, Prism::IntegerNode, Prism::FloatNode, Prism::RationalNode, Prism::ImaginaryNode, Prism::StringNode, Prism::TrueNode,
           Prism::FalseNode, Prism::NilNode, Prism::ItLocalVariableReadNode
        nil
      when Prism::StatementsNode then check_statements(node, ctx)
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
        case (r = node.rest)
        when nil, Prism::ImplicitRestNode then nil
        when Prism::SplatNode
          unless r.expression.nil? || r.expression.is_a?(Prism::LocalVariableTargetNode)
            error(r, "`#{r.slice}`: only a local variable can take the rest (`first, *rest = xs`)")
          end
        end
        (node.lefts + node.rights).each do |t|
          case t
          when Prism::LocalVariableTargetNode then nil
          when Prism::InstanceVariableTargetNode then check_field_shorthand(t, ctx)
          when Prism::IndexTargetNode
            if (t.arguments&.arguments || []).size != 1 || t.block
              error(t, "`#{first_line(t.slice)}` takes one index")
            else
              set_call(t, ctx, Operators::Call.new("Indexable", "[]="))
            end
            check(t.receiver, ctx)
            check_args(t.arguments, ctx)
          else error(t, "`#{first_line(t.slice)}` cannot be assigned here; use local variables, `x[i]`, or `@field`")
          end
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
      when Prism::ParenthesesNode
        node.body.is_a?(Prism::StatementsNode) ? check_statements(node.body, ctx, inherit: true) : check(node.body, ctx)
      when Prism::ArrayNode
        if node.opening_loc&.slice&.start_with?("%")
          error(node, "`#{node.opening_loc.slice}...]` is not supported yet (whether it is a Tuple or an Array is undecided)")
        end
        node.elements.each do |el|
          next check(el, ctx) unless el.is_a?(Prism::SplatNode)
          error(el, "splat in `[...]` is not supported (a Tuple's size must be known)", ["Array[#{node.elements.map(&:slice).join(", ")}] makes an Array"])
        end
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
        error(node, "`break` outside a loop or block") unless ctx.in_loop || ctx.in_block
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
          when Prism::EmbeddedStatementsNode then part.statements && check_statements(part.statements, ctx, inherit: true)
          when Prism::EmbeddedVariableNode then check(part.variable, ctx)
          else error(part, "unsupported part of an interpolated literal")
          end
        end
      when Prism::DefNode then error(node, "`def` must be at the top level or directly in a class/module body")
      when Prism::ClassNode, Prism::ModuleNode then error(node, "class/module must be at the top level")
      when Prism::ConstantWriteNode then error(node, "constant assignment must be at the top level")
      when Prism::ConstantPathNode
        # Math::PI, Float::INFINITY: read as operations (Math.PI), as ARGV is; no other nested names.
        par = node.parent
        fn = par.is_a?(Prism::ConstantReadNode) && BUILTIN_CONSTANTS.fetch(par.name.to_s, []).include?(node.name.to_s) && @registry.lookup(par.name.to_s, node.name.to_s)
        return set_call(node, ctx, fn) if fn
        error(node, "`#{node.slice}` (nested constants) is not supported", ["built-in constants: #{BUILTIN_CONSTANTS.flat_map { |ns, cs| cs.map { "#{ns}::#{_1}" } }.join(", ")}"])
      when Prism::ConstantReadNode
        # ARGV: the program's arguments (an operation, Kernel.ARGV; Sake has no value constants).
        return set_call(node, ctx, @registry.lookup("Kernel", "ARGV")) if node.name == :ARGV
        if (fn = @value_constants[node.name])
          error(node, "`#{node.name}` is not defined (Sake has no value constants)", ["call the function instead: `#{fn}`"])
        else
          error(node, "type `#{node.name}` cannot be used as a value")
        end
      when Prism::SelfNode then error(node, "Sake has no `self`")
      when Prism::InstanceVariableReadNode, Prism::InstanceVariableWriteNode, Prism::InstanceVariableOperatorWriteNode,
           Prism::InstanceVariableOrWriteNode
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
      return check_pattern(pat, ctx) unless pat.is_a?(Prism::HashPatternNode) # `x => Integer`, `x => A | B`
      ok = pat.is_a?(Prism::HashPatternNode) && pat.constant.nil? && pat.rest.nil? && !pat.elements.empty? &&
           pat.elements.all? do |el|
             el.is_a?(Prism::AssocNode) && el.key.is_a?(Prism::SymbolNode) &&
               pattern_target(el.value).is_a?(Prism::LocalVariableTargetNode)
           end
      error(node, "only Record patterns that bind fields are supported: `value => {x:, y: name}`") unless ok
    end

    def pattern_target(v) = v.is_a?(Prism::ImplicitNode) ? v.value : v

    PATTERN_TYPES = (BUILTIN_TYPES + %w[Record IO]).freeze
    BUILTIN_CONSTANTS = { "Math" => %w[PI E], "Float" => %w[INFINITY NAN EPSILON MAX MIN] }.freeze

    def builtin_constant?(n)
      n.is_a?(Prism::ConstantPathNode) && n.parent.is_a?(Prism::ConstantReadNode) &&
        BUILTIN_CONSTANTS.fetch(n.parent.name.to_s, []).include?(n.name.to_s)
    end

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
      type_only = args.size == 1 && args[0].is_a?(Prism::ConstantReadNode) # `raise T`, as Ruby: the message is T's name
      args.each_with_index { |a, i| check(a, ctx) unless i.zero? && (args.size == 2 || type_only) }
      case args.size
      when 0 then error(node, "a bare `raise` re-raises, so it is only allowed in a rescue clause") unless ctx.in_rescue
      when 1
        if type_only && !@struct_types[args[0].name.to_s]&.exception
          error(args[0], "`raise T` needs an exception type, got `#{args[0].slice}`")
        end
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

    # keywords: the callee's keyword parameters (name => default or nil), when `k: v` arguments are its.
    def check_args(args_node, ctx, hash_pairs: false, splat: false, keywords: nil)
      (args_node&.arguments || []).each do |a|
        case a
        when Prism::SplatNode
          next error(a, "splat arguments are not supported here") unless splat
          next error(a, "`*` without a value is not supported") unless a.expression
          check(a.expression, ctx)
        when Prism::KeywordHashNode
          if hash_pairs
            a.elements.each do |el|
              next error(el, "`**` is not supported") unless el.is_a?(Prism::AssocNode)
              check(el.key, ctx)
              check(el.value, ctx)
            end
          elsif keywords
            a.elements.each do |el|
              next error(el, "`**` is not supported") unless el.is_a?(Prism::AssocNode)
              check(el.value, ctx)
            end
          else
            error(a, "keyword arguments go only to functions with keyword parameters (`def f(x, k: 1)`)")
          end
        when Prism::ForwardingArgumentsNode then error(a, "argument forwarding is not supported")
        else check(a, ctx)
        end
      end
    end

    def binary_op?(name) = Operators::MODULE_OF.key?(name.to_s)

    def check_call(node, ctx)
      if Resolver.require_call?(node)
        return error(node, "require must be a statement at the top level of a file",
                     ["the files of a program are decided before running; put `require \"...\"` at the top"])
      end
      args = node.arguments&.arguments || []
      blk = node.block
      if blk.is_a?(Prism::BlockArgumentNode)
        e = blk.expression
        name = e.nil? ? "&" : (e.name.to_s if e.is_a?(Prism::LocalVariableReadNode))
        unless ctx.fn&.block_param && name == ctx.fn.block_param
          error(blk, "`#{blk.slice}`: only the function's own block parameter can be passed on (`def f(x, &b) = g(x, &b)`)",
                ["or pass a block `{ |x| ... }`"]) # blk still counts as a block for the arity check
        end
      end
      recv = node.receiver

      if recv.nil? && node.name == :_ && node.variable_call?
        return if ctx.prev
        return error(node, "`_` is the previous statement's value, and no statement precedes it here",
                     ["`_` reads the statement just before, in the same body (a function, block, or branch)"])
      end
      if (types = union_receiver(recv))
        return check_union_call(node, types, args, blk, ctx)
      end
      if (subject = chain_subject(node))
        # `x.T.f(args)` is `T.f(x, args)`.
        target = resolve_qualified(node, recv.name.to_s, node.name.to_s, argc: args.size + 1)
        check(subject, ctx)
        kws = target_keywords(target)
        check_args(node.arguments, ctx, splat: true, keywords: kws)
        check_block(blk, ctx) if blk.is_a?(Prism::BlockNode)
        return unless target
        set_call(node, ctx, target)
        return if check_splat(node, target, args, 1)
        return check_arity(node, target, check_keywords(node, target, args, kws) + 1, !blk.nil?)
      end
      if recv.nil?
        return error(node, "`#{node.name}` is not allowed in Sake (it defeats static analysis)") if FORBIDDEN.include?(node.name.to_s)
        return check_raise(node, ctx) if node.name == :raise && !lookup_unqualified?(ctx, "raise")
        target = resolve_unqualified(node, ctx)
      elsif recv.is_a?(Prism::ConstantReadNode) && (node.call_operator_loc || node.name == :[])
        # `T[...]` is the constructor syntax; `T.[](x, k)` is T's index operation.
        target = resolve_qualified(node, recv.name.to_s, node.call_operator_loc ? node.name.to_s : CTOR)
      elsif recv.is_a?(Prism::ConstantPathNode) && !builtin_constant?(recv)
        return error(recv, "`#{recv.slice}` (nested constants) is not supported")
      elsif node.call_operator_loc.nil? && BINARY_OPS.include?(node.name) && args.size == 1
        error(node, "operator `#{node.name}` is not supported") unless binary_op?(node.name)
        set_call(node, ctx, Operators::Call.new(Operators::MODULE_OF[node.name.to_s], node.name.to_s))
        check(recv, ctx)
        check_args(node.arguments, ctx)
        return
      elsif node.call_operator_loc.nil? && UNARY_OPS.include?(node.name)
        # `!x` is `x ? false : true`; `-x`, `+x`, `~x` dispatch on x's type, like binary operators.
        set_call(node, ctx, Operators::Call.new(Operators::MODULE_OF[node.name.to_s], node.name.to_s)) unless node.name == :!
        return check(recv, ctx)
      elsif node.call_operator_loc.nil? && %i[[] []=].include?(node.name)
        want = node.name == :[] ? [1, 2] : [2, 3]
        unless want.include?(args.size)
          error(node, "`#{first_line(node.slice)}` takes #{node.name == :[] ? "one or two indexes" : "one or two indexes and a value"}")
        else
          set_call(node, ctx, Operators::Call.new("Indexable", node.name.to_s))
        end
        check(recv, ctx)
        return check_args(node.arguments, ctx)
      else
        if node.name.to_s.match?(/\A[A-Z]/) && node.arguments.nil? && blk.nil?
          check(recv, ctx)
          return error(node, "`#{first_line(node.slice)}` needs an operation after the type: `#{first_line(recv.slice)}.#{node.name}.op(...)`")
        end
        return lowercase_receiver_error(node, ctx)
      end

      hash_ctor = recv.is_a?(Prism::ConstantReadNode) && recv.name == :Hash && node.name == :[]
      if hash_ctor && !(args.empty? || (args.size == 1 && args[0].is_a?(Prism::KeywordHashNode)))
        error(node, "Hash[...] takes `key => value` pairs, like `Hash[\"a\" => 1]`")
      end
      kws = target_keywords(target)
      check_args(node.arguments, ctx, hash_pairs: hash_ctor, splat: true, keywords: kws)
      check_block(blk, ctx) if blk.is_a?(Prism::BlockNode)
      return unless target

      if target.is_a?(Dispatch) && target.table.empty? && ctx.fn.nil? # reached for sure: the top level runs
        return error(node, "#{target.module}.#{target.name} is a mixin function, and no type includes #{target.module}",
                     ["to call it as #{target.module}.#{target.name}(...), mark it with `module_function`"])
      end
      set_call(node, ctx, target)
      return if check_splat(node, target, args, 0)
      check_arity(node, target, check_keywords(node, target, args, kws), !blk.nil?)
      check_typed_array_literals(node, target, args) if target.is_a?(Builtin) && target.name == CTOR && !%w[Array Hash Set].include?(target.namespace)
    end

    # The built-ins whose result depends on how many rest arguments there are (zip makes Tuples that long).
    NO_SPLAT = %w[Array.zip Range.zip Hash[]].freeze

    # `*xs` may fill only a built-in's rest parameter: the arguments before it are then counted statically.
    # Returns true when the call has a splat (its arity is checked here).
    def check_splat(node, target, args, offset)
      i = args.index { _1.is_a?(Prism::SplatNode) }
      return false unless i
      if target.is_a?(Builtin) && NO_SPLAT.include?(target.full_name)
        error(args[i], "`#{args[i].slice}`: #{target.full_name} takes its arguments written out (#{target.full_name == "Hash[]" ? "`key => value` pairs" : "it makes Tuples as long as the number of arguments"})")
        return true
      end
      unless target.is_a?(Builtin) && target.rest
        error(args[i], "`#{args[i].slice}`: splat arguments go only to built-ins that take any number of arguments " \
                       "(puts, format, Array[...], Set[...], Array.push, ...)",
              target.is_a?(Builtin) || target.is_a?(Operators::Call) ? [] : ["#{target_name(target)} takes a fixed number of arguments; pass them one by one"])
        return true
      end
      fixed = target.params.size + target.optional.size
      if i + offset < fixed
        error(args[i], "`#{args[i].slice}`: the first #{fixed} argument(s) of #{target.full_name} are written out; a splat fills only the rest")
      else
        check_arity(node, target, args.size + offset, !node.block.nil?)
      end
      true
    end

    # The keyword parameters of a call's target: a user function's, or (a dispatch) the module function's.
    def target_keywords(target)
      fn = target.is_a?(Dispatch) ? @functions.dig(target.module, target.name) : target
      fn.is_a?(UserFunction) && fn.keywords&.any? ? fn.keywords : nil
    end

    # `k: v` arguments go to keyword parameters by name, decided here since the callee is known.
    # Returns the number of positional arguments.
    def check_keywords(node, target, args, kws)
      kw = kws && args.last.is_a?(Prism::KeywordHashNode) ? args.last : nil
      return args.size unless kws
      seen = {}
      (kw&.elements || []).each do |el|
        next unless el.is_a?(Prism::AssocNode)
        name = el.key.is_a?(Prism::SymbolNode) && el.key.value ? el.key.unescaped : nil
        next error(el.key, "a keyword argument is written `name: value`") unless name
        if !kws.key?(name)
          error(el.key, "#{target_name(target)} has no keyword parameter `#{name}`", spell(name, kws.keys).map { "did you mean `#{_1}:`?" })
        elsif seen[name]
          error(el.key, "keyword argument `#{name}` is given twice")
        end
        seen[name] = true
      end
      missing = kws.select { |k, d| d.nil? && !seen[k] }.keys
      error(node, "#{target_name(target)} needs keyword argument#{"s" if missing.size > 1} #{missing.map { "`#{_1}:`" }.join(", ")}") if missing.any?
      args.size - (kw ? 1 : 0)
    end

    def target_name(t) = t.respond_to?(:full_name) ? t.full_name : "#{t.module}.#{t.name}"

    def check_arity(node, target, argc, has_block)
      case target
      when Operators::Call
        want = { "[]=" => [3, 4], "[]" => [2, 3] }.fetch(target.op) { [Operators::UNARY.include?(target.op) ? 1 : 2] }
        error(node, "#{target.module}.#{target.op} takes #{want.join(" or ")} arguments (given #{argc})") unless want.include?(argc)
      when Dispatch
        fn = @functions.dig(target.module, target.name)
        fn = target.table.values.find { _1.is_a?(UserFunction) && !_1.abstract } || fn if fn&.abstract
        check_arity(node, fn, argc, has_block) if fn
      when UserFunction
        unless (target.min_arity..target.positional).cover?(argc)
          expected = target.min_arity == target.positional ? target.positional : "#{target.min_arity}..#{target.positional}"
          error(node, "wrong number of arguments for #{target.full_name} (given #{argc}, expected #{expected})")
        end
        return if target.abstract # a required function: its includers' definitions say whether it takes a block
        if target.yields && !has_block && !target.block_optional
          error(node, "#{target.full_name} uses `yield` but no block is given",
                target.block_param ? [] : ["a function that checks `block_given?` may be called without a block"])
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

    # A block parameter: its name, or for `(a, (b, c))` the nested names, taken apart like `a, b = x`.
    def nested_param(r)
      return r.name.to_s if r.is_a?(Prism::RequiredParameterNode)
      if r.is_a?(Prism::MultiTargetNode) && r.rest.nil? && r.rights.empty?
        return r.lefts.map { nested_param(_1) }
      end
      error(r, "unsupported block parameter `#{r.slice}` (only names and `(a, b)` are supported)")
      "_"
    end

    def block_params(blk)
      pn = blk.parameters
      case pn
      when nil then []
      when Prism::BlockParametersNode
        ps = pn.parameters
        return [] unless ps
        rest = ps.rest.is_a?(Prism::RestParameterNode) ? ps.rest : nil
        if ps.optionals.any? || ps.keywords.any? || (ps.rest && !rest) || ps.keyword_rest || ps.block
          error(ps, "only plain block parameters `|a, b|` and `|a, *rest|` are supported")
        end
        [*ps.requireds.map { nested_param(_1) }, *(rest ? [RestParam.new(rest.name&.to_s)] : []), *ps.posts.map { nested_param(_1) }]
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

    # `(A|B|C)`: the listed names (Constant | Constant | ...), or nil when recv is not that form.
    def union_receiver(recv)
      return nil unless recv.is_a?(Prism::ParenthesesNode) && recv.body.is_a?(Prism::StatementsNode) && recv.body.body.size == 1
      flat = lambda do |n|
        case n
        when Prism::ConstantReadNode then [n]
        when Prism::NilNode then [n]
        when Prism::CallNode
          return nil unless n.name == :| && n.call_operator_loc.nil? && n.receiver && n.arguments&.arguments&.size == 1
          (l = flat.(n.receiver)) && (r = flat.(n.arguments.arguments[0])) ? l + r : nil
        end
      end
      top = recv.body.body[0]
      return nil unless top.is_a?(Prism::CallNode) && top.name == :|
      flat.(top)
    end

    # `(A|B).f(x, ...)`: f of each listed type; at run time x's type picks one.
    def check_union_call(node, type_nodes, args, blk, ctx)
      check_args(node.arguments, ctx)
      check_block(blk, ctx) if blk.is_a?(Prism::BlockNode)
      if (n = type_nodes.find { _1.is_a?(Prism::NilNode) })
        return error(n, "nil cannot be listed in `(...)`: check for nil first (`if x`), then call the operation")
      end
      types = type_nodes.map { _1.name.to_s }
      return error(node.receiver, "list a type at most once in `(#{types.join("|")})`") if types.uniq.size != types.size
      if args.empty?
        return error(node, "(#{types.join("|")}).#{node.name} needs an argument to dispatch on")
      end
      table = {}
      type_nodes.zip(types) do |tn, t|
        unless @struct_types.key?(t) || BUILTIN_TYPES.include?(t)
          error(tn, "`#{t}` is not a type; `(...)` lists types (Struct types or built-in types)")
          next
        end
        found = lookup(t, node.name.to_s)
        unless found
          error(tn, "#{t} has no `#{node.name}`, so `(#{types.join("|")}).#{node.name}` cannot dispatch to it",
                spell(node.name.to_s, names_in(t)).map { "did you mean `#{t}.#{_1}`?" })
          next
        end
        check_arity(node, found, args.size, !blk.nil?)
        table[t] = found
      end
      set_call(node, ctx, UnionCall.new(types, node.name.to_s, table)) if table.size == types.size
    end

    # `x.T.f(...)`: the subject x of a chain whose step `.T` names a type or module.
    def chain_subject(node)
      r = node.receiver
      return nil unless node.call_operator_loc && r.is_a?(Prism::CallNode) && r.receiver && r.call_operator_loc
      return nil unless r.name.to_s.match?(/\A[A-Z]/) && r.arguments.nil? && r.block.nil?
      r.receiver
    end

    # argc: the number of arguments when node's own count is not it (a chain adds its subject).
    def resolve_qualified(node, ns, name = node.name.to_s, argc: nil)
      if (ns == "Struct" && name == "new") || (ns == "Data" && name == "define")
        return error(node, "Struct.new must be assigned to a top-level constant: `Point = Struct.new(:x, :y)`")
      end
      if name == "initialize" && @struct_types.key?(ns)
        return error(node, "#{ns}.initialize is called by #{ns}.new; call #{ns}.new instead")
      end
      if name == "call" && node.respond_to?(:message_loc) && node.message_loc.nil? # `T.(...)`, not a function named call
        return error(node, "type scope `#{ns}.(...)` is not supported yet")
      end
      if (old = { "BinaryOp" => "Arithmetic", "Index" => "Indexable" }[ns])
        return error(node.receiver, "`#{ns}` is now `#{Operators::MODULE_OF[name] || old}`")
      end
      if (Operators::MODULES.include?(ns) || ns == "Kernel") && Operators::MODULE_OF[name] == ns
        return error(node, "#{ns}.#{name} dispatches on its first argument, so it needs one") if (argc || (node.arguments&.arguments || []).size).zero?
        return Operators::Call.new(ns, name)
      end
      unless @registry.namespace?(ns)
        return error(node.receiver, "undefined type or module `#{ns}`", spell(ns, @registry.namespaces).map { "did you mean `#{_1}`?" })
      end
      found = lookup(ns, name)
      return mixin_call(node, ns, name, found, argc) if found.is_a?(UserFunction) && @modules.key?(ns) && !found.module_function
      if found
        @direct_calls << [node, found] if found.is_a?(UserFunction)
        return found
      end

      if name == CTOR # `T[...]` for a T without a typed Array
        typed = @registry.namespaces.select { |t| @registry.lookup(t, CTOR) && !@struct_types.key?(t) && !%w[Array Hash Set].include?(t) }
        return error(node, "`#{ns}[...]`: #{ns} has no typed Array", ["Array[...] holds any values; typed Arrays: #{typed.sort.map { "#{_1}[]" }.join(", ")}, and T[] for your own types"])
      end
      hints = spell(name, names_in(ns)).map { "did you mean `#{ns}.#{_1}`?" }
      others = namespaces_defining(name) - [ns]
      hints << "`#{name}` is defined in #{others.map { "`#{_1}.#{name}`" }.join(", ")}" unless others.empty?
      if (dt = @struct_types[ns]) && name =~ /\A(get|set)_(.+)\z/ && dt.fields.include?($2)
        priv = !@registry.lookup(ns, "get_#{$2}") && !@registry.lookup(ns, "set_#{$2}")
        kind = priv ? "private (private attr_*)" : ($1 == "set" ? "read-only (attr_reader)" : "write-only (attr_writer)")
        return error(node, "field `#{$2}` of #{ns} is #{kind}",
                     ["inside `class #{ns}`, use `@#{$2}#{$1 == "set" ? " = value" : ""}`#{priv ? "" : "; or declare it with `attr_accessor #{$2}`"}"])
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
    # `raise NotImplementedError` or `raise NotImplementedError, "..."`, alone.
    def abstract_body?(body)
      st = body.is_a?(Prism::StatementsNode) && body.body.size == 1 ? body.body[0] : body
      st.is_a?(Prism::CallNode) && st.name == :raise && st.receiver.nil? &&
        st.arguments&.arguments&.first.is_a?(Prism::ConstantReadNode) && st.arguments.arguments.first.name == :NotImplementedError
    end

    def mixin_call(node, mod, name, fn, argc = nil)
      if (argc || (node.arguments&.arguments || []).size).zero?
        return error(node, "#{mod}.#{name} is a mixin function: it has no subject to dispatch on",
                     ["call it on a type that includes #{mod}, or mark it with `module_function`"])
      end
      types = @linearized.select { |t, mods| (@struct_types.key?(t) || BUILTIN_TYPES.include?(t)) && mods.any? { _1[0] == mod } }.keys
      # No type includes mod (yet): a call that is reached is reported by the type checker.
      return Dispatch.new(mod, name, {}) if types.empty?
      table = types.to_h { |t| [t, lookup(t, name)] }
      # A required function's block comes from the types' definitions, which must agree.
      defined = table.values.select { _1.is_a?(UserFunction) && !_1.abstract }
      yields = fn.abstract && defined.any? ? defined.first.yields : fn.yields
      table.each do |t, impl|
        next if impl.is_a?(UserFunction) && impl.params.size == fn.params.size && impl.min_arity == fn.min_arity && impl.keyword_shape == fn.keyword_shape && (impl.abstract || impl.yields == yields)
        error(node, "#{mod}.#{name} dispatches to #{t}.#{name}, whose arguments or block differ from #{mod}.#{name}")
      end
      Dispatch.new(mod, name, table)
    end

    def lookup(ns, name) = @functions.fetch(ns, {})[name] || @registry.lookup(ns, name)
    def names_in(ns) = (@functions.fetch(ns, {}).keys | @registry.names(ns)) - [CTOR] # `T[...]` is syntax, not a name

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
      generic =
        if node.name.end_with?("=") # `x.pos = v`: a setter is an operation named set_pos
          "Sake has no method calls on values; a setter is an operation named set_x: `Type.set_#{node.name.to_s.delete_suffix("=")}(#{node.receiver.slice}, value)`"
        else
          "Sake has no method calls on values; call an operation with its type: `Type.#{node.name}(#{node.receiver.slice}, ...)`"
        end
      hints = suggestions.empty? ? [generic] : suggestions
      # The chain form of the first suggestion, for a single step: `x.T.f(args)`.
      if suggestions.any? && !lowercase_call?(node.receiver) && !node.attribute_write? && (op = suggestions.first[/\A[A-Z][\w:]*\.[^(\s]+/])
        args = (node.arguments&.arguments || []).map(&:slice)
        blk = node.block.is_a?(Prism::BlockNode) ? " #{node.block.slice.include?("\n") ? "{ ... }" : node.block.slice}" : ""
        hints << "#{first_line(node.receiver.slice)}.#{op}#{args.empty? ? "" : "(#{args.join(", ")})"}#{blk}"
      end
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
