# frozen_string_literal: true

require_relative "errors"
require_relative "identifier"
require_relative "values"

module Sql
  # A scalar function. max is nil for "any number >= min". With null_propagating, a NULL
  # argument gives NULL without calling impl.
  Function = Data.define(:name, :min, :max, :null_propagating, :impl)

  module Functions
    REGISTRY = {}

    def self.define(name, min, max = min, null_propagating: true, &impl)
      REGISTRY[name] = Function.new(name, min, max, null_propagating, impl)
    end

    define("length", 1) { |x| Values.text_form(x).length }
    define("upper", 1) { |x| Values.text_form(x).upcase(:ascii) }
    define("lower", 1) { |x| Values.text_form(x).downcase(:ascii) }
    define("abs", 1) do |x|
      x.is_a?(String) ? Values.numeric_prefix(x).to_f.abs : x.abs
    end
    define("typeof", 1, null_propagating: false) { |x| Values.type_name(x).downcase }
    define("coalesce", 2, nil, null_propagating: false) { |*xs| xs.find { |x| !x.nil? } }
    define("ifnull", 2, null_propagating: false) { |x, y| x.nil? ? y : x }
    define("nullif", 2, null_propagating: false) { |x, y| !x.nil? && !y.nil? && Values.compare(x, y) == 0 ? nil : x }

    # Finds the function for a call as written, checking the argument count.
    def self.lookup(name, argc)
      fn = REGISTRY[Sql.fold(name)] or raise SqlError, "no such function: #{name}"
      if argc < fn.min || (fn.max && argc > fn.max)
        raise SqlError, "wrong number of arguments to function #{name}()"
      end
      fn
    end

    def self.call(fn, args)
      return nil if fn.null_propagating && args.any?(&:nil?)
      fn.impl.call(*args)
    end
  end
end
