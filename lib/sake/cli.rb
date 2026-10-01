# frozen_string_literal: true

require "stringio"
require_relative "../sake"

module Sake
  module CLI
    USAGE = <<~TEXT
      usage: sake [-c] [--strict[=SPEC]] [--types] FILE.sake

        -c               check only: report problems, do not run
        --strict[=SPEC]  how strictly to check before running (default: level 1)
                         --strict       the recommended level (2)
                         --strict=N     level N:
                                          0  syntax, names, arguments, calls on values, ...
                                          1  + type       a type that is not nil does not fit
                                             + rescue     a rescue clause for an exception never raised
                                          2  + nil        a value that may be nil is used unchecked
                                          3  + index-nil  the result of x[k] is used unchecked
                                          4  + unrescued  a raise that may reach the top level
                         --strict=type,nil          exactly these items
                         --strict=2,index-nil       level 2 plus an item; `-item` removes one
        --types          experimental: print the inferred types instead of running

      exit status: 0 = ok, 1 = runtime error, 2 = problem found before running
    TEXT

    STRICT_ITEMS = %w[type rescue nil index-nil unrescued].freeze
    STRICT_LEVELS = [[], %w[type rescue], %w[type rescue nil], %w[type rescue nil index-nil],
                     %w[type rescue nil index-nil unrescued]].freeze
    DEFAULT_LEVEL = 1
    RECOMMENDED_LEVEL = 2

    module_function

    NIL_CHECK_HINT = "check the value first: `if x`, `while x`, `return unless x`, or `x != nil`"

    def parse_strict(spec)
      spec.split(",").inject([]) do |items, word|
        case word
        when /\A\d+\z/ then items | STRICT_LEVELS.fetch(word.to_i) { raise ArgumentError, "strict levels are 0..#{STRICT_LEVELS.size - 1}" }
        when /\A-(.+)\z/ then items - [strict_item($1)]
        else items | [strict_item(word.delete_prefix("+"))]
        end
      end
    end

    def strict_item(name)
      return name if STRICT_ITEMS.include?(name)
      raise ArgumentError, "unknown strict item `#{name}` (items: #{STRICT_ITEMS.join(", ")})"
    end

    # Reports the type checker's findings for the chosen items as static errors.
    def type_message(c, what, typer, program)
      if c.arg == "subject"
        mod = c.op.split(".").first
        return ["#{c.op} dispatches on its first argument, which #{c.verdict == :error ? "is" : "can be"} #{typer.show_failing(c)}; " \
                "the types that include #{mod} are #{c.expected.split("|").join(", ")}", []]
      end
      if c.arg == "result"
        return ["#{c.op} must return a String, but #{c.verdict == :error ? "returns" : "may return"} #{typer.show_failing(c)}", []]
      end
      if c.arg == "field"
        type, field = c.op.split(".", 2)
        verb = c.verdict == :error ? "is" : "can be"
        return ["field #{field} of #{type} must be #{c.expected} (fixed by its default), but #{verb} #{typer.show_failing(c)}", []]
      end
      maybe = c.verdict == :error ? "are " : "may be "
      case c.op
      when /\A(Arithmetic|Comparable|Bitwise|Kernel)\./
        mod = $1
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
      when "Indexable.[]", "Indexable.[]="
        tuples, others = c.failing.partition { _1.is_a?(Array) && _1[0] == :tuple }
        return ["#{c.op}: the index is outside the Tuple #{typer.show(tuples)}", []] if others.empty?
        ["#{c.op}: the receiver #{maybe.sub("are", "is")}#{typer.show(others)}, which cannot be indexed; defined for #{Stdlib::INDEX_ROWS}", []]
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
      diags = typer.findings.select { |_, item| items.include?(item) }.sort_by { |c, _| [c.line, c.column] }.map do |c, item|
        what = c.arg == "pair" ? "the operands" : "argument #{c.arg}"
        wants = c.expected.split("|") unless c.arg == "pair"
        msg, hints =
          case item
          when "type" then type_message(c, what, typer, program)
          when "rescue"
            ["rescue #{c.arg}: the begin body never raises #{c.arg}", ["remove this rescue, or raise #{c.arg} in the body"]]
          when "unrescued"
            ["raise: #{c.arg} may reach the top level without being rescued", ["rescue it, or check with a level below 4"]]
          when "nil" then ["#{c.op}: #{what} may be nil (#{typer.show(c.actual)})", [NIL_CHECK_HINT, *typer.nil_sources(wants)]]
          else
            ["#{c.op}: #{what} may be nil, because x[k] gives nil when the index or key is missing",
             [NIL_CHECK_HINT, "or use Array.fetch / Hash.fetch, which raise instead"]]
          end
        hints += ["reached by the call at line #{c.via.join(" → line ")}"] if c.via&.any?
        Diagnostic.new(program.path, c.line, c.column, "#{msg} [#{item}]", hints)
      end
      raise StaticErrors.new(diags) unless diags.empty?
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
      items = STRICT_LEVELS[DEFAULT_LEVEL]
      files = []
      argv.each do |arg|
        case arg
        when "-c" then check_only = true
        when "--types" then types = true
        when "--strict" then items = STRICT_LEVELS[RECOMMENDED_LEVEL]
        when /\A--strict=(.*)\z/ then items = parse_strict($1)
        when "-h", "--help"
          out.write(USAGE)
          return 0
        when /\A-/ then raise ArgumentError, "unknown option #{arg}"
        else files << arg
        end
      end
      raise ArgumentError, "give one FILE.sake" unless files.size == 1

      path = files.first
      source = File.read(path)
      program = Sake.load(source, path, out:)
      if types
        require_relative "typer"
        out.write(Typer.new(program).run.report)
        return 0
      end
      strict_check(program, items, err) unless items.empty?
      if check_only
        out.puts "#{path}: OK"
      else
        Sake.execute(program)
      end
      0
    rescue ArgumentError => e
      err.puts "sake: #{e.message}"
      err.write(USAGE)
      2
    rescue StaticErrors => e
      out.flush
      err.puts e.message
      2
    rescue RunError => e
      out.flush
      add_nil_hints(e, source, path) if e.nil_value?
      err.puts e.report
      1
    end
  end
end
