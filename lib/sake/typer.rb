# frozen_string_literal: true

module Sake
  # Experimental whole-program type inference (forward abstract interpretation).
  #
  # A type is a canonical union: a sorted, frozen Array of atoms; [] is bottom (no value reaches here).
  # Atoms: "Integer" "Float" "String" "Boolean" "Nil" "<Struct name>",
  #        [:tuple, [type, ...]], [:record, [[field, type], ...]], [:array, site_id], [:unknown, reason].
  # A record atom has one atom per field (the type fixed at creation), sorted by field.
  # "IndexNil" is a nil that came from x[k] (a miss); at run time it is an ordinary nil.
  # User functions are instantiated per argument types (Crystal style); functions that yield are
  # analyzed per call site. Arrays carry an allocation site whose element type is the union of every
  # write; Struct fields are the union of every write per type. The whole program is re-analyzed until
  # these tables stop changing, and only the last pass's observations are reported.
  class Typer
    NUM = %w[Integer Float].freeze
    COMPARE_OPS = %w[< <= > >= == !=].freeze
    MAX_PASSES = 30
    MAX_YIELD_DEPTH = 3
    MAX_LOOP_ITER = 10
    MAX_TUPLE_DEPTH = 3

    Site = Struct.new(:id, :node, :label, :declared, :init, :elem)
    Frame = Struct.new(:fn, :ret, :block)
    # breaks: the types of the block's `break` values, which become results of the call it was given to.
    BlockCtx = Struct.new(:node, :params, :env, :breaks)
    # via: lines of the calls that led to the first failing instantiation, outermost first.
    # file: the check's file (nil for the main file); via: the call sites leading to it, each a line
    # in the main file or "file:line".
    # node: the Prism node of the operation (for messages).
    Check = Struct.new(:line, :column, :op, :arg, :expected, :actual, :verdict, :failing, :via, :file, :node)

    attr_reader :checks, :sites, :fields, :dead_functions, :passes

    # Inferred result type of each built-in call node (last pass), for validating result types.
    def results = @results || {}

    # narrow: inside `if x` / `while x` on a local variable, drop nil from x's type.
    # ast: the program's SakeAST, when the caller already has it.
    def initialize(program, narrow: true, ast: nil)
      @program = program
      @ast = ast || Lower.program(program)
      @narrow = narrow
      @registry = program.registry
      @site_ids = {}.compare_by_identity
      @sites = {}
      @fields = Hash.new { |h, k| h[k] = {} }
      @nil_writes = Hash.new { |h, k| h[k] = Hash.new { |h2, f| h2[f] = [] } } # dt => field => [line]
      @returns = {}
    end

    def run
      @passes = 0
      loop do
        @passes += 1
        before = snapshot
        @checks = {}
        @check_ctx = {}
        @results = {}.compare_by_identity
        @done = {}
        @in_progress = {}
        @yield_depth = Hash.new(0)
        @instantiated = {}
        @callers = []
        @raised = [{}]   # stack of {exception type name => [raise nodes]} for the code being analyzed
        @handled = []    # exception type names of the rescue clauses being analyzed (for a bare raise)
        ev(@ast.main.body, Env.new(nil, Frame.new(nil, [], nil)))
        @raised.last.each { |name, nodes| nodes.uniq.each { add_check(_1, "raise", name, "a rescue", t(name), :error, [name]) } }
        break if snapshot == before || @passes >= MAX_PASSES
      end
      all_fns = @program.functions.values.flat_map(&:values)
      @dead_functions = all_fns.reject { @instantiated[_1] }
      self
    end

    # --- types ---

    def self.union(*tys)
      atoms = tys.flatten(1).uniq
      tuples, rest = atoms.partition { _1.is_a?(Array) && _1[0] == :tuple }
      # Tuples of one length merge position by position, except that a position holding a single Symbol
      # literal tags its variant (`[:copy, Integer]` and `[:literal, Array]` stay apart).
      merged = tuples.group_by { |tp| [tp[1].size, tp[1].each_with_index.filter_map { |e, i| [i, e[0]] if e.size == 1 && e[0].is_a?(Array) && e[0][0] == :sym }] }.map do |_, ts|
        [:tuple, ts.map { _1[1] }.transpose.map { |es| union(*es) }]
      end
      (normalize_symbols(rest) + merged).uniq.sort_by(&:inspect).freeze
    end

    MAX_SYMBOLS = 32

    # A Symbol literal is the atom [:sym, name]; "Symbol" (any Symbol) covers them, and too many become it.
    def self.normalize_symbols(atoms)
      syms = atoms.select { _1.is_a?(Array) && _1[0] == :sym }
      return atoms if syms.empty?
      return atoms - syms if atoms.include?("Symbol")
      syms.size > MAX_SYMBOLS ? atoms - syms + ["Symbol"] : atoms
    end

    def u(*tys) = Typer.union(*tys)
    def t(name) = [name].freeze
    def unknown(reason) = [[:unknown, reason]].freeze
    def unknown?(ty) = ty.any? { _1.is_a?(Array) && _1[0] == :unknown }

    def tuple(elems, depth = 0)
      return unknown("tuple depth") if elems.any? { tuple_depth(_1) >= MAX_TUPLE_DEPTH }
      [[:tuple, elems]].freeze
    end

    def tuple_depth(ty)
      ty.map do |a|
        next 0 unless a.is_a?(Array)
        case a[0]
        when :tuple then 1 + (a[1].map { tuple_depth(_1) }.max || 0)
        when :record then 1 + (a[1].map { tuple_depth(_1[1]) }.max || 0)
        else 0
        end
      end.max || 0
    end

    MAX_RECORD_VARIANTS = 16

    # One record atom per combination of field atoms: a record's field types are fixed per value.
    def record_type(pairs)
      sorted = pairs.sort_by(&:first)
      return [] if sorted.any? { _1[1].empty? }
      return unknown("record depth") if sorted.any? { tuple_depth(_1[1]) >= MAX_TUPLE_DEPTH }
      combos = sorted.map { |_, ty| ty }.inject([[]]) { |acc, ty| acc.product(ty).map { |c, a| c + [[a].freeze] } }
      return unknown("record variants") if combos.size > MAX_RECORD_VARIANTS
      u(*combos.map { |c| [[:record, sorted.map(&:first).zip(c)]] })
    end

    # The runtime type name of an atom (Values.type_of).
    NILS = %w[Nil IndexNil].freeze

    def nil_atom?(a) = NILS.include?(a)
    def without_nil(ty) = u(*(ty - NILS).map { [_1] })

    def atom_type_name(a)
      return (a == "IndexNil" ? "Nil" : a) if a.is_a?(String)
      case a[0]
      when :tuple then "Tuple"
      when :array then "Array"
      when :record then "{#{a[1].map { |f, ty| "#{f}: #{atom_type_name(ty.first)}" }.join(", ")}}"
      when :range then "Range"
      when :hash then "Hash"
      when :set then "Set"
      when :thread then "Thread"
      when :queue then "Queue"
      when :sym then "Symbol"
      else "?"
      end
    end

    # seen: the sites being shown; a site inside itself (a recursive structure) is shown by its label only.
    SHOW_LIMIT = 400

    # seen: the sites already shown in this text; each is spelled out once, then named by its label,
    # so a type that refers to the same sites many times stays short. Long types are cut.
    def show(ty, seen = nil)
      return "(none)" if ty.empty?
      top = seen.nil?
      s = ty.map { show_atom(_1, seen ||= {}) }.uniq.join(" | ")
      top && s.size > SHOW_LIMIT ? "#{s[0, SHOW_LIMIT]}…" : s
    end

    def show_atom(a, seen = {})
      case a
      when "Boolean" then "true|false"
      when "Nil", "IndexNil" then "nil"
      when String then a
      else
        case a[0]
        when :tuple then "[#{a[1].map { show(_1, seen) }.join(", ")}]"
        when :record then "{#{a[1].map { |f, ty| "#{f}: #{show(ty, seen)}" }.join(", ")}}"
        when :array
          s = @sites[a[1]]
          return "#{s.declared}[]@#{s.label}" if s.declared
          return "Array@#{s.label}" if seen[a]
          "Array@#{s.label}[#{show(s.elem, seen.tap { _1[a] = true })}]"
        when :unknown then "?(#{a[1]})"
        when :range then "Range[#{show(a[1], seen)}]"
        when :hash
          s = hash_sites[a[1]]
          return "Hash@#{s.label}" if seen[a]
          inner = seen.tap { _1[a] = true }
          "Hash@#{s.label}[#{show(s.key, inner)} => #{show(s.val, inner)}]"
        when :set
          s = set_sites[a[1]]
          seen[a] ? "Set@#{s.label}" : "Set@#{s.label}[#{show(s.elem, seen.tap { _1[a] = true })}]"
        when :thread then "Thread@#{thread_sites[a[1]].label}"
        when :queue
          s = queue_sites[a[1]]
          seen[a] ? "Queue@#{s.label}" : "Queue@#{s.label}[#{show(s.elem, seen.tap { _1[a] = true })}]"
        when :pairs then "pairs"
        when :sym then ":#{a[1]}"
        end
      end
    end

    def snapshot

      [(@raises ||= {}).transform_values(&:dup), @sites.transform_values { [_1.elem] }, @fields.transform_values(&:dup), @returns.dup,
       hash_sites.transform_values { [_1.key, _1.val] }, set_sites.transform_values { [_1.elem] },
       thread_sites.transform_values { [_1.elem] }, queue_sites.transform_values { [_1.elem] }, (@once_types || {}).dup]
    end

    # --- array sites and fields ---

    # Declared element types whose atoms carry structure (Tuple[...] of [Float, Float]): the site keeps
    # the written atoms of that type, not just the name.
    STRUCTURED = %w[Tuple Range].freeze

    def site_for(node, label_extra = nil, declared: nil, init: [])
      id = (@site_ids[node] ||= @site_ids.size + 1)
      elem = declared && !STRUCTURED.include?(declared) ? t(declared) : init
      @sites[id] ||= Site.new(id, node, "L#{node.location.start_line}#{label_extra}", declared, init, elem)
      [[:array, id]].freeze
    end

    def array_sites(ty) = ty.select { _1.is_a?(Array) && _1[0] == :array }.map { @sites[_1[1]] }
    def elem_of(ty) = u(*array_sites(ty).map(&:elem))

    def write_elems(ty, xs, node, op)
      array_sites(ty).each do |s|
        if s.declared
          xs.each { |x| record(node, op, "elem", s.declared, x) }
          if STRUCTURED.include?(s.declared)
            s.elem = u(s.elem, *xs.map { |x| x.select { atom_type_name(_1) == s.declared } })
          end
        else
          s.elem = u(s.elem, *xs)
        end
      end
    end

    # A field whose default fixed its type keeps that type; other writes are checks.
    def field_write(dt, field, ty, node)
      if (fixed = @program.struct_types[dt]&.field_types&.[](field))
        record(node, "#{dt}.#{field}", "field", fixed, ty)
        @fields[dt][field] = t(fixed)
        return
      end
      @nil_writes[dt][field] << node.location.start_line if ty.any? { nil_atom?(_1) }
      @fields[dt][field] = u(@fields[dt][field] || [], ty)
    end

    # --- checks ---

    def atom_matches?(atom, want) = atom_type_name(atom) == want

    def record(node, op, arg, want, actual)
      return if want == "Any" || actual.empty?
      wants = Array(want)
      failing = actual.reject { |a| wants.any? { atom_matches?(a, _1) } }
      verdict =
        if unknown?(actual) then :unknown
        elsif failing.empty? then :proven
        elsif failing.size == actual.size then :error
        else :partial
        end
      add_check(node, op, arg, wants.join("|"), actual, verdict, failing)
    end

    def add_check(node, op, arg, expected, actual, verdict, failing = [])
      key = [node.location.start_line, node.location.start_column, op, arg, other_file(node)]
      prev = @checks[key]
      if prev
        return if op == "rescue" && prev.verdict == :proven
        prev.actual = u(prev.actual, actual)
        # Evaluations along the same calls are loop iterations and passes towards the fixpoint: a check that
        # fails in some and passes in others may fail. Different call paths keep the worse verdict.
        return prev.verdict = :proven if op == "rescue" && verdict == :proven
        ctx = (@check_ctx[key] ||= {})
        ctx[@callers] = (c = ctx[@callers]).nil? || c == verdict ? verdict : (([c, verdict] & %i[unknown]).empty? ? :partial : :unknown)
        prev.verdict = ctx.values.reduce { worse(_1, _2) }
        prev.failing = (prev.failing + failing).uniq
        prev.via ||= @callers.dup unless failing.empty?
      else
        (@check_ctx[key] = {})[@callers.dup] = verdict
        @checks[key] = Check.new(node.location.start_line, node.location.start_column, op, arg, expected, actual, verdict, failing,
                                 failing.empty? ? nil : @callers.dup, other_file(node), node)
      end
    end

    # The file of a node when it is not the main file (the checks of required files say where they are).
    def other_file(node)
      f = @program.sources&.[](node.location.send(:source))
      f == @program.path ? nil : f
    end

    # A call site for `via`: its line, or "file:line" in a required file.
    def call_site(node) = (f = other_file(node)) ? "#{f}:#{node.location.start_line}" : node.location.start_line

    # [check, item] for every check that may fail, where item is a strict item name:
    # "type" (surely fails, or may fail for a non-nil type), "nil", or "index-nil" (a nil from x[k]).
    def findings
      @checks.values.filter_map do |c|
        next if %i[proven unknown].include?(c.verdict)
        next [c, "rescue"] if c.op == "rescue"
        next [c, "unrescued"] if c.op == "raise"
        next [c, "exhaustive"] if c.op == "case/in" && c.arg == "value"
        next [c, "type"] if c.verdict == :error
        parts = c.failing.map { |f| operand_pair?(c) ? f : [f] }
        next [c, "type"] unless parts.all? { |p| p.any? { nil_atom?(_1) } }
        [c, parts.any? { |p| p.include?("Nil") } ? "nil" : "index-nil"]
      end
    end

    # A check of an operator's two operands, whose failing entries are [left, right] pairs.
    def operand_pair?(c) = c.arg == "pair" && !c.op.start_with?("Indexable.")

    def show_failing(c)
      seen = {}
      s = if operand_pair?(c) || c.arg == "elements"
            c.failing.map { |x, y| "(#{show([x], seen)}, #{show([y], seen)})" }.uniq.join(", ")
          else
            c.failing.map { show([_1], seen) }.uniq.join(" | ")
          end
      s.size > SHOW_LIMIT ? "#{s[0, SHOW_LIMIT]}…" : s
    end

    # "Struct.field (nil written at line N)" for fields that may hold nil next to a type in `wants`.
    def nil_sources(wants = nil)
      @fields.flat_map do |dt, fs|
        fs.filter_map do |f, ty|
          next unless ty.any? { nil_atom?(_1) }
          next if wants && (ty - NILS).none? { |a| Array(wants).any? { |w| atom_matches?(a, w) } }
          lines = @nil_writes[dt][f].uniq.sort
          "#{dt}.#{f} may be nil (nil is stored at line #{lines.join(", ")})"
        end
      end
    end

    # An instantiation that surely fails makes the site an error even if other instantiations pass.
    def worse(a, b) = %i[error unknown partial proven].find { [a, b].include?(_1) }

    # --- evaluation ---

    def call_user(fn, args, blk)
      @instantiated[fn] = true
      if fn.yields
        return unknown("recursive yield") if @yield_depth[fn] >= MAX_YIELD_DEPTH
        @yield_depth[fn] += 1
        begin
          return run_body(fn, args, blk)
        ensure
          @yield_depth[fn] -= 1
        end
      end

      key = [fn, args]
      if @in_progress[key] || @done[key]
        merge_raised(@raises[key] || {})
        return @returns[key] || []
      end
      @in_progress[key] = true
      @raised.push({})
      r = run_body(fn, args, nil)
      @raises[key] = merge_into(@raises[key] || {}, @raised.pop)
      merge_raised(@raises[key])
      @in_progress.delete(key)
      @done[key] = true
      @returns[key] = u(@returns[key] || [], r)
    end

    # --- exceptions: which user-raised exception types may leave each piece of code ---

    def merge_into(a, b) = a.merge(b) { |_, x, y| (x + y).uniq }
    def merge_raised(h) = @raised[-1] = merge_into(@raised[-1], h)
    def struct_type(name) = @program.struct_types[name]

    # Exception types that only `raise` produces; built-in operations may raise the other kinds anywhere.
    def user_raised?(name) = name == "RuntimeError" || !Resolver::BUILTIN_EXCEPTIONS.include?(name)

    # Index.[]: a miss gives nil for Array and String; a Tuple has a fixed length, so a literal index
    # selects one position and any other index gives the union of all positions.
    # lit: the index when it is an Integer literal.
    # extra: the type of a second index (`s[i, n]`, `m[r, c]`), or nil.
    def index_get(node, recv, key, lit, extra = nil)
      return [] if recv.empty? || key.empty? || extra&.empty?
      return unknown("index") if unknown?(recv) || unknown?(key) || (extra && unknown?(extra))
      results = []
      failing = []
      recv.each do |a|
        if struct_atom?(a)
          fn = Operators.includes?(@program.includes || {}, a, "Indexable") && @program.functions.dig(a, "[]")
          fn ? results << call_user(fn, [[a].freeze, key, *[extra].compact], nil) : failing << a
          next
        end
        if extra # `s[start, length]` on a String or an Array: a slice, or nil
          if a == "String" then results << t("String") << t("IndexNil")
          elsif a.is_a?(Array) && a[0] == :array then results << [a].freeze << t("IndexNil")
          else failing << a
          end
          record(node, "Indexable.[]", "length", "Integer", extra) unless struct_atom?(a)
          next
        end
        if (ext = index_get_ext(node, a, key))
          results << ext
          next
        end
        unless a == "String" || (a.is_a?(Array) && %i[array tuple].include?(a[0]))
          failing << a
          next
        end
        next unless key.include?("Integer") # other index types are reported below
        case a
        when "String" then results << t("String") << t("IndexNil")
        else
          if a[0] == :array
            results << elem_of([a]) << t("IndexNil")
          elsif lit && (-a[1].size...a[1].size).cover?(lit)
            results << a[1][lit]
          elsif lit
            failing << a
          else
            results.concat(a[1])
          end
        end
      end
      verdict = failing.empty? ? :proven : (failing.size == recv.size ? :error : :partial)
      add_check(node, "Indexable.[]", "pair", "(Array|String|Tuple, Integer)", recv, verdict, failing)
      if recv.any? { _1 == "String" || (_1.is_a?(Array) && %i[array tuple].include?(_1[0])) }
        bad = key.reject { _1 == "Integer" || (_1.is_a?(Array) && _1[0] == :range) }
        add_check(node, "Indexable.[]", "index", "Integer", key, bad.empty? ? :proven : (bad.size == key.size ? :error : :partial), bad)
      end
      u(*results)
    end

    def index_set(node, recv, key, lit, val, extra = nil)
      return [] if recv.empty? || key.empty? || val.empty? || extra&.empty?
      recv.each do |a|
        if struct_atom?(a) && Operators.includes?(@program.includes || {}, a, "Indexable") && (fn = @program.functions.dig(a, "[]="))
          call_user(fn, [[a].freeze, key, *[extra].compact, val], nil)
          next
        end
        next if extra # built-in types take one index when writing
        next unless a.is_a?(Array)
        if a[0] == :hash
          s = hash_sites[a[1]]
          s.key = u(s.key, key)
          s.val = u(s.val, val)
        elsif a[0] == :array
          write_elems([a], [val], node, "Indexable.[]=")
        elsif a[0] == :tuple
          want = lit && (-a[1].size...a[1].size).cover?(lit) ? a[1][lit] : u(*a[1])
          record(node, "Indexable.[]=", "value", want.map { atom_type_name(_1) }, val)
        end
      end
      bad = recv.reject do |a|
        (a.is_a?(Array) && %i[array tuple hash].include?(a[0])) ||
          (struct_atom?(a) && Operators.includes?(@program.includes || {}, a, "Indexable") && @program.functions.dig(a, "[]="))
      end
      verdict = unknown?(recv) ? :unknown : (bad.empty? ? :proven : (bad.size == recv.size ? :error : :partial))
      add_check(node, "Indexable.[]=", "pair", "(Array|Tuple, Integer)", recv, verdict, bad)
      val
    end

    def op_name(op) = "#{Operators::MODULE_OF.fetch(op)}.#{op}"

    def struct_atom?(a) = a.is_a?(String) && @program.struct_types.key?(a)

    # The result of a Struct type's own operator (or nil when the type cannot do op).
    def user_op_result(op, x, b)
      if %w[== !=].include?(op)
        fn = @program.functions.dig(x, "==")
        fn ||= Operators.includes?(@program.includes || {}, x, "Comparable") && @program.functions.dig(x, "<=>")
        call_user(fn, [[x].freeze, b.include?(x) ? [x].freeze : b], nil) if fn && (b.include?(x) || @program.functions.dig(x, "=="))
        return t("Boolean")
      end
      mod = Operators::MODULE_OF.fetch(op)
      return nil unless Operators.includes?(@program.includes || {}, x, mod)
      if (fn = @program.functions.dig(x, op))
        return call_user(fn, [[x].freeze, b], nil)
      end
      if mod == "Comparable" && (cmp = @program.functions.dig(x, "<=>"))
        call_user(cmp, [[x].freeze, b], nil)
        return t("Boolean")
      end
      nil
    end

    def binop(node, op, a, b)
      op = op.to_s
      return [] if a.empty? || b.empty?
      if unknown?(a) || unknown?(b)
        add_check(node, op_name(op), "pair", "table row", u(a, b), :unknown)
        return unknown("operand")
      end
      rows = @registry.binary_ops[op]
      results = []
      hits = 0
      pairs = a.product(b)
      failing = []
      a.select { struct_atom?(_1) }.each do |x|
        if (r = user_op_result(op, x, b))
          hits += b.size
          results << r
        else
          b.each { |y| failing << [x, y] }
        end
      end
      pairs.reject { |x, _| struct_atom?(x) }.each do |x, y|
        if %w[== !=].include?(op) # any two values can be compared for equality
          hits += 1
          results << t("Boolean")
          next
        end
        key = [x, y].map { atom_type_name(_1) }
        unless rows.key?(key)
          failing << [x, y]
          next
        end
        hits += 1
        # Set | & - give a new Set: its elements come from the operands (a plain "Set" would have none).
        if key[0] == "Array" && %w[+ - *].include?(op)
          elems = op == "+" ? u(elem_of([x]), elem_of([y])) : elem_of([x])
          results << site_for(node, " Array#{op}").tap { |ty| write_elems(ty, [elems], node, "") }
          next
        end
        results << (key == %w[Set Set] ? set_site(node, " #{op}").tap { |r| set_sites[r[0][1]].elem = u(set_sites[r[0][1]].elem, set_elem([x]), *(op == "|" ? [set_elem([y])] : [])) } : binop_result(op, *key))
      end
      verdict = hits == pairs.size ? :proven : (hits.zero? ? :error : :partial)
      actual = pairs.map { |x, y| tuple([[x].freeze, [y].freeze]) }
      add_check(node, op_name(op), "pair", "table row", u(*actual), verdict, failing)
      check_ordered_elements(node, op, pairs) if op == "<=>" || COMPARE_OPS.take(4).include?(op)
      u(*results)
    end

    # Tuples and Arrays are ordered by their elements: each pair of element types must be comparable.
    def check_ordered_elements(node, op, pairs)
      elem_pairs = []
      pairs.each do |x, y|
        if [x, y].all? { _1.is_a?(Array) && _1[0] == :tuple }
          x[1].zip(y[1]).each { |ex, ey| elem_pairs.concat(ex.product(ey)) if ey }
        elsif [x, y].all? { _1.is_a?(Array) && _1[0] == :array }
          elem_pairs.concat(elem_of([x]).product(elem_of([y])))
        end
      end
      return if elem_pairs.empty?
      failing = elem_pairs.reject { |ex, ey| comparable_atoms?(ex, ey) }
      verdict = failing.empty? ? :proven : (failing.size == elem_pairs.size ? :error : :partial)
      add_check(node, op_name(op), "elements", "comparable elements", u(*elem_pairs.map { |ex, ey| tuple([[ex].freeze, [ey].freeze]) }),
                verdict, failing)
    end

    def comparable_atoms?(x, y, depth = 0)
      return true if [x, y].any? { _1.is_a?(Array) && _1[0] == :unknown }
      if struct_atom?(x)
        return Operators.includes?(@program.includes || {}, x, "Comparable") && !!@program.functions.dig(x, "<=>")
      end
      if depth < 3 && [x, y].all? { _1.is_a?(Array) && _1[0] == :tuple }
        return x[1].zip(y[1]).all? { |ex, ey| ey.nil? || ex.product(ey).all? { |a, b| comparable_atoms?(a, b, depth + 1) } }
      end
      if depth < 3 && [x, y].all? { _1.is_a?(Array) && _1[0] == :array }
        return elem_of([x]).product(elem_of([y])).all? { |a, b| comparable_atoms?(a, b, depth + 1) }
      end
      @registry.binary_ops["<=>"].key?([x, y].map { atom_type_name(_1) })
    end

    # `-x` / `+x` / `~x`: a built-in type keeps its type; a Struct type runs its own operator.
    def unop(node, op, a)
      return [] if a.empty?
      if unknown?(a)
        add_check(node, op_name(op), "operand", "a type with #{op}", a, :unknown)
        return unknown("operand")
      end
      results = []
      failing = []
      a.each do |x|
        if struct_atom?(x)
          fn = Operators.includes?(@program.includes || {}, x, Operators::MODULE_OF.fetch(op)) && @program.functions.dig(x, op)
          fn ? results << call_user(fn, [[x].freeze], nil) : failing << x
        elsif @registry.unary_ops[op].key?(atom_type_name(x))
          results << [x].freeze
        else
          failing << x
        end
      end
      verdict = failing.empty? ? :proven : (failing.size == a.size ? :error : :partial)
      add_check(node, op_name(op), "operand", @registry.unary_ops[op].keys.join("|"), a, verdict, failing)
      u(*results)
    end

    # `sum(xs[, init])`: an empty collection gives init (default 0, an Integer); otherwise init + the elements.
    def sum_type(init, elems)
      init ||= t("Integer")
      nums = elems.select { Stdlib::NUMERIC.include?(_1) }
      u(init, *init.product(nums).map { |a, b| binop_result("+", a, b) })
    end

    # Result types of the BinaryOp rows (Ruby's numeric tower).
    def binop_result(op, t1, t2)
      return u(t("Integer"), t("Nil")) if op == "<=>"
      return t("Boolean") if COMPARE_OPS.include?(op) || op == "!~"
      return u(t("Integer"), t("Nil")) if op == "=~"
      return t("String") if t1 == "String"
      return t("Set") if t1 == "Set"
      return (t2 == "Time" ? t("Float") : t("Time")) if t1 == "Time"
      types = [t1, t2]
      return t("Complex") if types.include?("Complex")
      return t("Float") if types.include?("Float")
      return t("Rational") if types.include?("Rational")
      t("Integer")
    end

    def call_builtin(fn, args, blk, node)
      args.each_with_index { |a, i| record(node, fn.full_name, i + 1, fn.param_type(i), a) }
      return [] if args.any?(&:empty?)

      ns = fn.namespace
      name = fn.name
      if (dt = @program.struct_types[ns]) && name != CTOR
        return data_op(dt, name, args, node)
      end
      if (r = constructor_ext(ns, name, args, node))
        return r
      end
      if name == CTOR
        if ns == "Array"
          # Every instantiation adds its element types (the site is made once, by the first).
          return site_for(node, init: u(*args)).tap { |ty| write_elems(ty, args, node, "") }
        end
        return site_for(node, declared: ns).tap { |ty| write_elems(ty, args, node, "#{ns}[]") }
      end
      # `Integer.+(a, b)`: the operator rows whose left operand is the type.
      return binop(node, name, args[0], args[1]) if @registry.binary_ops.key?(name) && fn.params.size == 2 && fn.params[1] == "Any"
      struct_hooks(args, name)
      builtin_result(fn.full_name, args, blk, node)
    end

    # The Ruby methods behind a built-in (sort, max, include?, uniq, Hash keys, ...) call a Struct
    # type's own <=> and ==. Each is analyzed with the values it can be compared with: the arguments and
    # their elements with each other, then, level by level, values at the same place (the same field,
    # Tuple position, Record key, or element of nested collections).
    def struct_hooks(tys, name)
      tops = tys.map { |ty| u(ty, elem_of(ty), set_elem(ty), *hash_kv(ty)) }
      tops = [u(*tops)] if MEETS_ARGUMENTS.include?(name) # an argument against a collection's elements or keys
      groups = []
      seen = {}
      tops.each { compared_groups(_1, groups, seen) }
      groups.each do |g|
        other = u(*g.map { [_1] })
        g.each do |x|
          %w[<=> ==].each { |op| (fn = @program.functions.dig(x, op)) and call_user(fn, [[x].freeze, other], nil) }
        end
      end
    end

    # Built-ins that compare one argument with another's elements or keys (`Array.include?(xs, x)`).
    MEETS_ARGUMENTS = %w[include? member? index find_index rindex count delete delete? key? has_key? value? has_value? key
                         fetch fetch_values values_at dig [] []= store add add? union difference intersection intersect?
                         subset? superset? disjoint? - + & | ==].freeze

    def compared_groups(ty, out, seen)
      return if ty.empty? || seen[ty]
      seen[ty] = true
      structs = ty.select { struct_atom?(_1) }
      out << structs unless structs.empty?
      structs.each { |a| @fields[a].each_value { compared_groups(_1, out, seen) } } # the default == compares fields
      tuples = atoms_of(ty, :tuple).map { _1[1] }
      (0...(tuples.map(&:size).max || 0)).each { |i| compared_groups(u(*tuples.filter_map { _1[i] }), out, seen) }
      records = atoms_of(ty, :record).flat_map { _1[1] }
      records.map(&:first).uniq.each { |k| compared_groups(u(*records.select { _1[0] == k }.map(&:last)), out, seen) }
      compared_groups(u(elem_of(ty), set_elem(ty)), out, seen)
      hash_kv(ty).each { compared_groups(_1, out, seen) }
    end

    def data_op(dt, name, args, node)
      case name
      when "new"
        dt.fields.each_with_index do |f, i|
          ty = args[i] || (dt.field_types[f] ? t(dt.field_types[f]) : t("Nil"))
          field_write(dt.name, f, ty, node)
        end
        t(dt.name)
      when /\Aget_(.+)\z/ then @fields[dt.name][$1] || []
      when /\Aset_(.+)\z/
        field_write(dt.name, $1, args[1], node)
        args[1]
      end
    end

    def new_site(node, label, elem) = site_for(node, label, init: elem).tap { |ty| write_elems(ty, [elem], node, "") }

    def builtin_result(name, args, blk, node)
      ext = builtin_result_ext(name, args, blk, node)
      return ext unless ext == :none
      a0 = args[0]
      case name
      when "Kernel.puts", "Kernel.print" then t("Nil")
      when "Kernel.p" then a0
      when "Integer.to_s", "Float.to_s", "String.to_s" then t("String")
      when "Integer.to_f", "String.to_f" then t("Float")
      when "Float.to_i", "Float.floor", "Float.ceil", "String.to_i", "String.length", "String.size",
           "String.count", "Array.length", "Array.size", "Tuple.length", "Tuple.size"
        t("Integer")
      when "Float.round" then args.size > 1 ? t("Float") : t("Integer")
      when "Integer.abs", "Integer.succ", "Integer.pred" then t("Integer")
      when "Float.abs" then t("Float")
      when "Integer.even?", "Integer.odd?", "Integer.zero?", "Float.nan?", "String.empty?", "String.include?",
           "String.start_with?", "String.end_with?", "Array.empty?", "Array.include?"
        t("Boolean")
      when /\AString\./
        if %w[String.chars String.lines String.split].include?(name)
          new_site(node, " #{name}", t("String"))
        elsif name == "String.each_char"
          call_block(blk, [t("String")])
          t("String")
        else
          t("String")
        end
      when /\AMath\./ then t("Float")
      when "Integer.times", "Integer.upto", "Integer.downto"
        call_block(blk, [t("Integer")])
        t("Integer")
      when "Array.push", "Array.append"
        write_elems(a0, args.drop(1), node, name)
        a0
      when "Array.concat"
        write_elems(a0, [elem_of(args[1])], node, name)
        a0
      when "Array.join" then t("String")
      when "Array.at", "Array.first", "Array.last", "Array.pop", "Array.shift", "Array.min", "Array.max"
        u(elem_of(a0), t("Nil"))
      when "Array.fetch" then elem_of(a0)
      when "Array.unshift"
        write_elems(a0, args.drop(1), node, name)
        a0
      when "Array.find", "Array.detect", "Array.min_by", "Array.max_by"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        u(e, t("Nil"))
      when "Array.index", "String.index" then u(t("Integer"), t("Nil"))
      when "Array.find_index"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        u(t("Integer"), t("Nil"))
      when "Range.sum"
        e = range_elem(a0)
        e = call_block(blk, [e]) if blk && !e.empty?
        record(node, "Range.sum", "elem", Stdlib::NUMERIC, e) if blk
        sum_type(args[1], e)
      when "Array.sum"
        e = elem_of(a0)
        e = call_block(blk, [e]) if blk && !e.empty?
        record(node, "Array.sum", "elem", Stdlib::NUMERIC, e)
        sum_type(args[1], e)
      when "Array.new"
        elem = blk ? call_block(blk, [t("Integer")]) : (args[1] || t("Nil"))
        new_site(node, " #{name}", elem)
      when "Array.reverse", "Array.sort", "Array.take", "Array.drop"
        new_site(node, " #{name}", elem_of(a0))
      when "Array.select", "Array.filter", "Array.reject", "Array.sort_by"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        new_site(node, " #{name}", e)
      when "Array.map"
        e = elem_of(a0)
        r = e.empty? ? [] : call_block(blk, [e])
        new_site(node, " #{name}", r)
      when "Array.each"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        a0
      when "Array.each_with_index"
        e = elem_of(a0)
        call_block(blk, [e, t("Integer")]) unless e.empty?
        a0
      when "Array.any?", "Array.all?", "Array.none?"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        t("Boolean")
      when "Array.count"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        t("Integer")
      when "Array.reduce", "Array.inject"
        e = elem_of(a0)
        acc = args[1]
        return acc if e.empty?
        MAX_LOOP_ITER.times do
          nxt = u(acc, call_block(blk, [acc, e]))
          break if nxt == acc
          acc = nxt
        end
        acc
      when "Exception.message" then t("String")
      else unknown("no signature for #{name}")
      end
    end
  end
end

module Sake
  class Typer
    # Verdicts of the run-time checks; rescue clauses and unrescued raises are not checks of a value.
    def summary
      counts = Hash.new(0)
      @checks.each_value { counts[_1.verdict] += 1 unless %w[raise rescue].include?(_1.op) }
      counts
    end

    def report
      out = +""
      out << "passes: #{@passes}\n"
      out << "checks: #{%i[proven partial error unknown].map { "#{_1}=#{summary[_1]}" }.join(" ")}\n"
      @checks.values.sort_by { [_1.line, _1.op] }.each do |c|
        next if c.verdict == :proven
        if c.op == "raise" # not a failing check: an exception nothing rescues (the `unrescued` item, level 4)
          out << "  unrescued L#{c.line} raise #{c.arg}\n"
          next
        end
        out << "  #{c.verdict.to_s.ljust(7)} L#{c.line} #{c.op} arg #{c.arg}: want #{c.expected}, got #{show(c.actual)}\n"
      end
      out << "arrays:\n"
      @sites.each_value do |s|
        kind = s.declared ? "declared #{s.declared}" : "init #{show(s.init)} -> #{show(s.elem)}#{s.init != s.elem ? " (widened)" : ""}"
        out << "  #{s.label}: #{kind}\n"
      end
      out << "fields:\n"
      @fields.each { |dt, fs| fs.each { |f, ty| out << "  #{dt}.#{f}: #{show(ty)}\n" } }
      out << "dead functions: #{@dead_functions.map(&:full_name).join(", ")}\n" unless @dead_functions.empty?
      out
    end
  end
end
require_relative "typer_ext"
require_relative "typer_eval"
