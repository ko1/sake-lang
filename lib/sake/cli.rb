# frozen_string_literal: true

require "stringio"
require_relative "../sake"

module Sake
  module CLI
    USAGE = <<~TEXT
      usage: sake [-c] [--strict[=SPEC]] [--types] [--dump=ast] FILE.sake [ARGS...]

        -c               check only: report problems, do not run
        --strict[=SPEC]  how strictly to check before running (default: level 1)
                         --strict       the recommended level (2)
                         --strict=N     level N:
                                          0  syntax, names, arguments, calls on values, ...
                                          1  + type       a type that is not nil does not fit
                                             + rescue     a rescue clause for an exception never raised
                                          2  + nil        a value that may be nil is used unchecked
                                          3  + index-nil  the result of x[k] is used unchecked
                                             + exhaustive a case/in may get a value no branch takes
                                          4  + unrescued  a raise that may reach the top level
                         --strict=type,nil          exactly these items
                         --strict=2,index-nil       level 2 plus an item; `-item` removes one
        --types          experimental: print the inferred types instead of running
        --dump=ast       print the SakeAST (the resolved program the interpreter runs)

      exit status: 0 = ok, 1 = runtime error, 2 = problem found before running
    TEXT

    # mixed: a type report whose value came through a field (or a container in a field) that holds
    # both fitting and non-fitting types: likely instances of one type used for different values.
    STRICT_ITEMS = %w[type rescue nil mixed index-nil exhaustive unrescued].freeze
    STRICT_LEVELS = [[], %w[type rescue], %w[type rescue nil mixed], %w[type rescue nil mixed index-nil exhaustive],
                     %w[type rescue nil mixed index-nil exhaustive unrescued]].freeze
    WARN_ITEMS = %w[mixed].freeze # shown as warnings at the levels where they do not stop the program
    DEFAULT_LEVEL = 1
    RECOMMENDED_LEVEL = 2

    class UsageError < StandardError; end

    module_function

    NIL_CHECK_HINT = "check the value first: `if x`, `while x`, `return unless x`, or `x != nil`"

    def parse_strict(spec)
      spec.split(",").inject([]) do |items, word|
        case word
        when /\A\d+\z/ then items | STRICT_LEVELS.fetch(word.to_i) { raise UsageError, "strict levels are 0..#{STRICT_LEVELS.size - 1}" }
        when /\A-(.+)\z/ then items - [strict_item($1)]
        else items | [strict_item(word.delete_prefix("+"))]
        end
      end
    end

    def strict_item(name)
      return name if STRICT_ITEMS.include?(name)
      raise UsageError, "unknown strict item `#{name}` (items: #{STRICT_ITEMS.join(", ")})"
    end

    # Reports the type checker's findings for the chosen items as static errors.
    def type_message(c, what, typer, program)
      if c.arg == "subject" && c.op.start_with?("(")
        return ["#{c.op}: argument 1 must be #{c.expected.split("|").join(" or ")}, but #{c.verdict == :error ? "is" : "can be"} #{typer.show_failing(c)}", []]
      end
      if c.arg == "subject" && c.expected.empty?
        mod = c.op.split(".").first
        return ["#{c.op} is a mixin function, and no type includes #{mod}", ["to call it as #{c.op}(...), mark it with `module_function`"]]
      end
      if c.arg == "subject"
        mod = c.op.split(".").first
        return ["#{c.op} dispatches on its first argument, which #{c.verdict == :error ? "is" : "can be"} #{typer.show_failing(c)}; " \
                "the types that include #{mod} are #{c.expected.split("|").join(", ")}", []]
      end
      if c.arg == "result"
        return ["#{c.op} must return a String, but #{c.verdict == :error ? "returns" : "may return"} #{typer.show_failing(c)}", []]
      end
      maybe = c.verdict == :error ? "are " : "may be "
      case c.op
      # Operand pairs only: `Kernel.Rational` and other built-ins of these modules check single arguments.
      when ->(op) { c.arg == "pair" && op.match?(/\A(Arithmetic|Comparable|Bitwise|Kernel)\./) }
        mod = c.op.split(".", 2)[0]
        op = c.op.split(".", 2)[1]
        lefts = c.failing.map(&:first).select { _1.is_a?(String) && program.struct_types.key?(_1) }.uniq
        unless lefts.empty?
          t = lefts.first
          if !Operators.includes?(program.includes, t, mod)
            return ["#{c.op}: #{t} does not include #{mod}", ["add `include #{mod}` and `def #{op}(a, b)` to class #{t}"]]
          end
          need = mod == "Comparable" && op != "<=>" ? "neither #{op} nor <=>" : op
          return ["#{c.op}: #{t} includes #{mod} but defines #{need}", ["define `def #{mod == "Comparable" ? "<=>" : op}(a, b)` in class #{t}"]]
        end
        ["#{c.op}: the operands #{maybe}#{typer.show_failing(c)}, which the left operand's type does not support", []]
      when ->(op) { c.arg == "pair" && %w[Indexable.[] Indexable.[]=].include?(op) }
        tuples, others = c.failing.partition { _1.is_a?(Array) && _1[0] == :tuple }
        return ["#{c.op}: the index is outside the Tuple #{typer.show(tuples)}", []] if others.empty?
        ["#{c.op}: the receiver #{maybe.sub("are", "is")}#{typer.show(others)}, which cannot be indexed; defined for #{Stdlib::INDEX_ROWS}", []]
      when ->(_) { c.arg == "required" }
        mod, f = c.op.split(".", 2)
        t = typer.show_failing(c)
        ["#{c.op}: #{t} includes #{mod} but does not define #{f}, which #{mod} requires (`raise NotImplementedError`)", ["define `def #{f}(...)` in class #{t}"]]
      when ->(_) { c.arg == "operand" }
        mod, op = c.op.split(".", 2)
        if (t = c.failing.find { _1.is_a?(String) && program.struct_types.key?(_1) })
          return ["#{c.op}: #{t} does not include #{mod}", ["add `include #{mod}` and `def #{op}(a)` to class #{t}"]] unless Operators.includes?(program.includes, t, mod)
          return ["#{c.op}: #{t} includes #{mod} but does not define #{op}", ["define `def #{op}(a)` in class #{t}"]]
        end
        ["#{c.op}: the operand #{maybe.sub("are", "is")}#{typer.show_failing(c)}, which has no #{op}; defined for #{c.expected.split("|").join(", ")}", []]
      when ->(_) { c.arg == "elements" }
        ["#{c.op}: elements compared in order #{maybe}#{typer.show_failing(c)}, which cannot be compared", []]
      when ->(op) { op == "case/in" && c.arg == "value" }
        ["case/in: no `in` branch matches some values of #{typer.show_failing(c)}", ["add an `else`, or `in` branches for the other values"]]
      when "=>"
        pat = c.node.respond_to?(:pattern) ? c.node.pattern.slice : "the pattern"
        ["`=> #{pat}`: the value #{maybe.sub("are", "is")}#{typer.show_failing(c)}, which does not match", []]
      when "case/in"
        ["case/in: no `in` branch matches #{typer.show_failing(c)}", ["add an `in` branch for it, or an `else`"]]
      when "pattern"
        ["the pattern needs field `#{c.arg}`, but the value #{maybe.sub("are", "is")}#{typer.show_failing(c)}", []]
      else
        hint = c.verdict == :error ? [] : ["the value has several types here; make each of them fit"]
        got = typer.show_failing(c)
        if c.expected.split("|").include?("Array") && c.failing.any? { _1.is_a?(Array) && _1[0] == :tuple }
          hint = ["`[...]` is a Tuple with a fixed length; for a growable Array, write `Array[...]`"]
        end
        if (m = c.op.match(/\A(?:Integer|Float|Rational)\.(round|floor|ceil|truncate|abs|to_f|to_i)\z/)) &&
           c.failing.all? { %w[Integer Float Rational].include?(_1) }
          hint += ["for any of Integer, Float, Rational, write `Arithmetic.#{m[1]}(x)`, as Ruby's `x.#{m[1]}`"]
        end
        if c.failing == ["Integer"] && c.actual.include?("Float") && c.expected.split("|").include?("Float")
          hint += ["if the value comes from `sum`, an empty collection sums to the Integer 0; give the start: `Array.sum(xs, 0.0)`"]
        end
        subject = c.arg == "elem" ? "an element" : what
        ["#{c.op}: #{subject} must be #{c.expected}, but #{c.verdict == :error ? "is" : "can be"} #{got}", hint]
      end
    end

    def strict_check(program, items, err)
      require_relative "typer"
      typer =
        begin
          Typer.new(program).run
        rescue StandardError => e
          err.puts "warning: type checks skipped (internal error in the type checker: #{e.class}: #{e.message})"
          return
        end
      strict_diagnostics(program, WARN_ITEMS - items, typer).each { err.puts(_1.to_s.sub(": error: ", ": warning: ")) }
      diags = strict_diagnostics(program, items, typer)
      raise StaticErrors.new(diags) unless diags.empty?
    end

    # The typer's findings for the chosen items, as diagnostics.
    def strict_diagnostics(program, items, typer)
      typer.findings.map { |c, item| [c, mixed?(program, typer, c, item) ? "mixed" : item] }.select { |_, item| items.include?(item) }.sort_by { |c, _| [c.file ? 0 : 1, c.file.to_s, c.line, c.column] }.map do |c, item|
        what = { "pair" => "the operands", "index" => "the index", "value" => "the value" }.fetch(c.arg) { "argument #{c.arg}" }
        wants = c.expected.split("|") unless c.arg == "pair"
        msg, hints =
          case item
          when "type", "exhaustive", "mixed"
            next_msg = ["yield: no block is given on this call", ["check `block_given?` before `yield`"]] if c.op == "yield"
            next_msg = ["the block passed on is missing here, and this call needs one", ["check `block_given?` first"]] if c.op == "&block"
            msg, hints = next_msg || type_message(c, what, typer, program)
            # Where a field got the wrong type, when the function around the operation reads a field.
            if %w[type mixed].include?(item) && c.node && reads_field?(program, c.node)
              hints += typer.field_sources(typer.operand_pair?(c) ? c.failing.map(&:first) : c.failing)
            end
            [msg, hints]
          when "rescue"
            ["rescue #{c.arg}: the begin body never raises #{c.arg}", ["remove this rescue, or raise #{c.arg} in the body"]]
          when "unrescued"
            ["raise: #{c.arg} may reach the top level without being rescued", ["rescue it, or check with a level below 4"]]
          when "nil"
            # Fields that may hold nil are named only when the function around the operation reads a field.
            reads_field = c.node && reads_field?(program, c.node)
            ["#{c.op}: #{what} may be nil (#{typer.show(c.actual)})", [NIL_CHECK_HINT, *(reads_field ? typer.nil_sources(wants) : [])]]
          else
            ["#{c.op}: #{what} may be nil, because x[k] (or `a, b = array`) gives nil when the element is missing",
             [NIL_CHECK_HINT, "or use Array.fetch / Hash.fetch, which raise instead"]]
          end
        hints += ["reached by the call at #{c.via.map { _1.is_a?(Integer) ? "line #{_1}" : _1 }.join(" → ")}"] if c.via&.any?
        Diagnostic.new(c.file || program.path, c.line, c.column, "#{msg} [#{item}]", hints)
      end
    end

    # A type report fed by a field that holds both the fitting and the failing types (see STRICT_ITEMS).
    def mixed?(program, typer, c, item)
      return false unless item == "type" && !c.failing.empty?
      fails = typer.type_names(typer.operand_pair?(c) ? c.failing.map(&:first) : c.failing) - ["Nil"]
      return false if fails.empty?
      typer.mixing_fields.any? { |names| (fails - names).empty? && !(names - fails).empty? }
    end

    # Whether the function around node reads a field: `@x`, or a reader `T.x(...)` / `v.T.x` of a Struct type.
    def reads_field?(program, node)
      readers = (@readers ||= {}.compare_by_identity)[program] ||= begin
        names = program.struct_types.flat_map { |t, dt| dt.fields.map { |f| "#{Regexp.escape(t)}\\.#{Regexp.escape(f)}\\b" } }
        names.empty? ? /@\w/ : Regexp.new("@\\w|#{names.join("|")}")
      end
      field_reading_region(program, node).match?(readers)
    end

    # The source of the function whose body holds node (the node itself at the top level).
    def field_reading_region(program, node)
      line = node.location.start_line
      fns = program.functions.values.flat_map(&:values).map(&:node).compact
      fn = fns.select { |d| d.location.send(:source).equal?(node.location.send(:source)) && d.location.start_line <= line && line <= d.location.end_line }
              .min_by { _1.location.end_line - _1.location.start_line }
      (fn || node).slice
    end

    # Runs only on the error path: static analysis tells where the nil may have come from.
    def add_nil_hints(error, source, path)
      require_relative "typer"
      typer = Typer.new(Sake.load(source, path, out: StringIO.new)).run
      error.hints = [*typer.nil_sources(error.expected), NIL_CHECK_HINT]
    rescue StandardError
      error.hints = [NIL_CHECK_HINT]
    end

    def main(argv, out: $stdout, err: $stderr)
      check_only = false
      types = false
      ast = false
      items = STRICT_LEVELS[DEFAULT_LEVEL]
      files = []
      args = argv.dup
      until args.empty?
        arg = args.shift
        unless files.empty? # after FILE: the program's own arguments (ARGV)
          args.unshift(arg)
          break
        end
        case arg
        when "-c" then check_only = true
        when "--types" then types = true
        when "--dump=ast" then ast = true
        when "--strict" then items = STRICT_LEVELS[RECOMMENDED_LEVEL]
        when /\A--strict=(.*)\z/ then items = parse_strict($1)
        when "-h", "--help"
          out.write(USAGE)
          return 0
        when /\A-/ then raise UsageError, "unknown option #{arg}"
        else files << arg
        end
      end
      raise UsageError, "give one FILE.sake" unless files.size == 1

      Sake.argv = args
      path = files.first
      run_source(File.read(path), path, check_only:, types:, ast:, items:, out:, err:)
    rescue UsageError => e
      err.puts "sake: #{e.message}"
      err.write(USAGE)
      2
    end

    # What `sake` does with a program's source; returns the exit status. thread: false runs the
    # program on the current thread (where threads are not available, as in ruby.wasm).
    def run_source(source, path, items:, check_only: false, types: false, ast: false, out: $stdout, err: $stderr, thread: true)
      program = Sake.load(source, path, out:)
      if ast
        code = Lower.program(program)
        out.puts AST.dump(code.main)
        code.functions.each_value { out.puts AST.dump(_1) }
        return 0
      end
      if types
        require_relative "typer"
        out.write(Typer.new(program).run.report)
        return 0
      end
      strict_check(program, items, err) unless items.empty?
      if check_only
        out.puts "#{path}: OK"
      else
        begin
          saved = $stderr
          $stderr = err # Kernel.warn writes to the program's error stream
          Sake.execute(program, thread:)
        ensure
          $stderr = saved
        end
      end
      0
    rescue StaticErrors => e
      out.flush
      err.puts e.message
      2
    rescue Exit => e # Kernel.exit
      out.flush
      e.status
    rescue RunError => e
      out.flush
      add_nil_hints(e, source, path) if e.nil_value?
      err.puts e.report
      1
    end
  end
end
