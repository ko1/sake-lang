# frozen_string_literal: true

require_relative 'values'

module SQL
  # Scalar functions (SPEC 1.11). Each entry has an argument count range and a lambda that
  # receives the evaluated arguments. Add new functions to REGISTRY.
  module Functions
    Function = Struct.new(:arity, :impl)

    REGISTRY = {}

    def self.define(name, arity, &impl)
      REGISTRY[name] = Function.new(arity, impl)
    end

    # Define a function whose result is NULL when its (single) argument is NULL.
    def self.define_unary(name, &impl)
      define(name, 1..1) { |(x)| x.nil? ? nil : impl.call(x) }
    end

    def self.lookup(name) = REGISTRY[name.downcase]

    define_unary('length') { |x| Values.text_form(x).length }
    define_unary('upper') { |x| Values.text_form(x).upcase(:ascii) }
    define_unary('lower') { |x| Values.text_form(x).downcase(:ascii) }
    define_unary('abs') do |x|
      x.is_a?(String) ? Values.numeric_prefix(x).abs.to_f : x.abs
    end
    define('typeof', 1..1) { |(x)| Values.type_name(x) }
    define('coalesce', 2..) { |args| args.find { |a| !a.nil? } }
    define('ifnull', 2..2) { |(x, y)| x.nil? ? y : x }
    define('nullif', 2..2) do |(x, y)|
      x.nil? || y.nil? || !Values.same?(x, nil, y, nil) ? x : nil
    end
  end
end
