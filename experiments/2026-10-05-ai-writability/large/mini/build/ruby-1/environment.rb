# frozen_string_literal: true

require_relative "errors"

module Mini
  # A run-time scope. Run-time scopes correspond one to one with the static
  # scopes of the checker, so a name is found by going `hops` scopes out (as
  # the checker computed) and looking it up there. A name missing from that
  # scope is declared there but its declaration has not run yet (SPEC 6.4).
  class Environment
    attr_reader :parent

    def initialize(parent)
      @parent = parent
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def lookup(name, hops, position)
      values = ancestor(hops).values
      values.fetch(name) { raise not_yet_declared(name, position) }
    end

    def assign(name, hops, value, position)
      values = ancestor(hops).values
      raise not_yet_declared(name, position) unless values.key?(name)

      values[name] = value
    end

    protected

    attr_reader :values

    private

    def ancestor(hops)
      env = self
      hops.times { env = env.parent }
      env
    end

    def not_yet_declared(name, position)
      EvalError.new(:name, "'#{name}' is used before its declaration", position)
    end
  end
end
