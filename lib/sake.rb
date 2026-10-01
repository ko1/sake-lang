# frozen_string_literal: true

require "prism"
require_relative "sake/errors"
require_relative "sake/values"
require_relative "sake/registry"
require_relative "sake/stdlib"
require_relative "sake/stdlib_ext"
require_relative "sake/resolver"
require_relative "sake/interpreter"

module Sake
  module_function

  # Parses and resolves; raises StaticErrors with every problem found.
  def load(source, path, out: $stdout, input: $stdin)
    result = Prism.parse(source, filepath: path)
    unless result.errors.empty?
      diags = result.errors.map do |e|
        Diagnostic.new(path, e.location.start_line, e.location.start_column, "syntax error: #{e.message}", [])
      end
      raise StaticErrors.new(diags)
    end
    registry = Registry.new
    Stdlib.install(registry, out)
    Stdlib.install_ext(registry, out, input)
    Resolver.new(path, result.value, registry).resolve
  end

  # The program runs in its own thread: bin/sake sizes thread stacks (RUBY_THREAD_*_STACK_SIZE)
  # so that Sake's own depth limit, not Ruby's stack, bounds recursion.
  def run(source, path, out: $stdout)
    program = load(source, path, out:)
    th = Thread.new { Interpreter.new(program).run }
    th.report_on_exception = false
    th.value
  rescue RunError => e
    e.path = path
    raise
  end
end
