# frozen_string_literal: true

require "prism"
require_relative "sake/errors"
require_relative "sake/values"
require_relative "sake/registry"
require_relative "sake/stdlib"
require_relative "sake/resolver"
require_relative "sake/interpreter"

module Sake
  module_function

  # Parses and resolves; raises StaticErrors with every problem found.
  def load(source, path, out: $stdout)
    result = Prism.parse(source, filepath: path)
    unless result.errors.empty?
      diags = result.errors.map do |e|
        Diagnostic.new(path, e.location.start_line, e.location.start_column, "syntax error: #{e.message}", [])
      end
      raise StaticErrors.new(diags)
    end
    registry = Registry.new
    Stdlib.install(registry, out)
    Resolver.new(path, result.value, registry).resolve
  end

  def run(source, path, out: $stdout)
    program = load(source, path, out:)
    Interpreter.new(program).run
  rescue RunError => e
    e.path = path
    raise
  rescue ::SystemStackError
    raise RunError.new("SystemStackError", "stack level too deep", 0).tap { _1.path = path }
  end
end
