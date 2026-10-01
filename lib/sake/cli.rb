# frozen_string_literal: true

require "stringio"
require_relative "../sake"

module Sake
  module CLI
    USAGE = <<~TEXT
      usage: sake [--check | --strict | --types] FILE.sake

        --check   only run the static checks (name resolution, arity, syntax)
        --strict  also report, before running, every place where a value that may be nil
                  is used without a check (`if x`, `x != nil`, `return unless x`, ...)
        --types   experimental: infer types and classify each runtime type check as
                  proven / partial (union) / error (surely fails) / unknown

      exit status: 0 = ok, 1 = runtime error, 2 = static error (reported before running)
    TEXT

    module_function

    NIL_CHECK_HINT = "check the value first: `if x`, `while x`, `return unless x`, or `x != nil`"

    def strict_check(program)
      require_relative "typer"
      typer = Typer.new(program).run
      diags = typer.nil_risks.sort_by { [_1.line, _1.column] }.map do |c|
        what = c.arg == "pair" ? "an operand" : "argument #{c.arg}"
        wants = c.expected.split("|") unless c.arg == "pair"
        Diagnostic.new(program.path, c.line, c.column, "#{c.op}: #{what} may be nil (#{typer.show(c.actual)})",
                       [NIL_CHECK_HINT, *typer.nil_sources(wants)])
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
      check_only = !argv.delete("--check").nil?
      types = !argv.delete("--types").nil?
      strict = !argv.delete("--strict").nil?
      if argv.size != 1 || argv.first.start_with?("-")
        err.write(USAGE)
        return argv.include?("--help") || argv.include?("-h") ? 0 : 2
      end
      path = argv.first
      source = File.read(path)
      if types
        require_relative "typer"
        out.write(Typer.new(Sake.load(source, path, out:)).run.report)
      elsif check_only
        Sake.load(source, path, out:)
      else
        strict_check(Sake.load(source, path, out:)) if strict
        Sake.run(source, path, out:)
      end
      0
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
