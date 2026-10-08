# frozen_string_literal: true

require_relative 'ast'

module SQL
  # Which calls are aggregates (SPEC 3.2) and where they occur in an expression. This only reads the
  # AST; computing aggregates is in aggregate_functions.rb.
  module Aggregates
    # Accepted argument counts (`count(*)` has the one argument Star).
    ARITY = {
      'count' => 1..1, 'sum' => 1..1, 'total' => 1..1, 'avg' => 1..1,
      'min' => 1..1, 'max' => 1..1, 'group_concat' => 1..2
    }.freeze

    module_function

    # `max`/`min` with two or more arguments stay scalar (2.4).
    def aggregate?(call)
      name = call.name.downcase
      ARITY.key?(name) && !(%w[min max].include?(name) && call.args.size >= 2)
    end

    # Calls written identically (up to the case of the name) are one aggregate.
    def key(call) = call.with(name: call.name.downcase)

    # The aggregate calls in `node`, each distinct one once, in order of appearance.
    def find_calls(node, found = {})
      case node
      when Call
        if aggregate?(node) then found[key(node)] ||= node
        else node.args.each { |a| find_calls(a, found) }
        end
      when Subquery, Exists then nil # their aggregates belong to the subquery
      when InSelect then find_calls(node.expr, found)
      when Data then node.to_h.each_value { |v| find_calls(v, found) }
      when Array then node.each { |v| find_calls(v, found) }
      end
      found.values
    end
  end
end
