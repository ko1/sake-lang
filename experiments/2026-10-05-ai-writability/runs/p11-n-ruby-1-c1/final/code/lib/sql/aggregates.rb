# frozen_string_literal: true

require_relative "ast"
require_relative "collation"
require_relative "errors"
require_relative "evaluator"
require_relative "identifier"
require_relative "ordering"
require_relative "values"

module Sql
  # Aggregate functions (3.2): which calls are aggregates, how the Binder records them while binding
  # (a Collector, or Forbidden where they are not allowed), and how one is computed over a group.
  module Aggregates
    # A bound aggregate call. Equal specs are computed once per group.
    Spec = Data.define(:name, :args, :distinct, :order_by, :star)

    # name => allowed argument counts (count(*) is `star`; count() is the same)
    ARITY = {
      "count" => 0..1, "sum" => 1..1, "total" => 1..1, "avg" => 1..1,
      "min" => 1..1, "max" => 1..1, "group_concat" => 1..2
    }.freeze

    # Collects the aggregates of a query as they are bound; each becomes an AggRef at `width + slot`,
    # i.e. after the table's columns in the group row built by Grouping.
    class Collector
      attr_reader :specs

      def initialize(width)
        @width = width
        @specs = []
      end

      def add(spec, written_name)
        slot = @specs.index(spec) || (@specs << spec).length - 1
        AggRef.new(@width + slot, written_name)
      end

      def check_alias(_expr); end
    end

    # Where an aggregate is an error. Formats take the aggregate's name as written.
    class Forbidden
      def initialize(call_message, alias_message = call_message)
        @call_message = call_message
        @alias_message = alias_message
      end

      def add(_spec, written_name)
        raise SqlError, format(@call_message, written_name)
      end

      # A result column's alias stands for its expression: an error if that holds an aggregate.
      def check_alias(expr)
        ref = Sql.find_node(expr) { |n| n.is_a?(AggRef) }
        raise SqlError, format(@alias_message, ref.name) if ref
      end
    end

    module_function

    # Is this unbound call an aggregate (3.2)? min/max with 2+ arguments are the scalar functions.
    def aggregate_call?(call)
      name = Sql.fold(call.name)
      return false unless ARITY.key?(name)
      return call.args.length == 1 if name == "min" || name == "max"
      true
    end

    # A window call (`over`) of an aggregate's name is not an aggregate itself, but its arguments may hold one.
    def contains_call?(node)
      !Sql.find_node(node) { |n| n.is_a?(Call) && n.over.nil? && aggregate_call?(n) }.nil?
    end

    # The Spec for an aggregate call whose arguments and ORDER BY keys are already bound.
    def spec_for(call, args, order_by)
      name = Sql.fold(call.name)
      unless call.star ? name == "count" : ARITY.fetch(name).cover?(args.length)
        raise SqlError, "wrong number of arguments to function #{call.name}()"
      end
      if call.distinct && args.length != 1
        raise SqlError, "DISTINCT aggregates must have exactly one argument"
      end
      Spec.new(name, args, call.distinct, order_by, call.star || args.empty?)
    end

    # Value of the aggregate over the rows (arrays of the table's values) of one group.
    def compute(spec, rows)
      rows = Ordering.sort_rows(rows, spec.order_by) unless spec.order_by.empty?
      return rows.length if spec.star
      tuples = rows.map { |row| spec.args.map { |a| Evaluator.evaluate(a, row) } }
      tuples.reject! { |t| t[0].nil? }
      collation = argument_collation(spec)
      tuples = tuples.uniq { |t| Values.group_key(t[0], collation) } if spec.distinct
      case spec.name
      when "count" then tuples.length
      when "sum" then sum(tuples)
      when "total" then real_sum(sum_terms(tuples))
      when "avg" then tuples.empty? ? nil : real_sum(sum_terms(tuples)) / tuples.length
      when "min" then extreme(tuples, -1, collation)
      when "max" then extreme(tuples, 1, collation)
      when "group_concat" then group_concat(tuples)
      end
    end

    # The collation x's TEXT values compare under in an aggregate over x (BINARY without an argument).
    def argument_collation(spec)
      spec.args.empty? ? :binary : Collation.of(spec.args[0])
    end

    # The index of the row that gives the min / max of a one-argument min/max spec, or nil when
    # no row has a non-NULL value.
    def extreme_row_index(spec, rows)
      best = nil
      best_index = nil
      collation = argument_collation(spec)
      rows.each_with_index do |row, i|
        v = Evaluator.evaluate(spec.args[0], row)
        next if v.nil?
        if best_index.nil? || Values.compare(v, best, collation) * (spec.name == "min" ? -1 : 1) > 0
          best = v
          best_index = i
        end
      end
      best_index
    end

    # The summands of sum / total / avg: Integer for an INTEGER, Float for anything else (3.2).
    def sum_terms(tuples)
      tuples.map do |(x)|
        case x
        when Integer, Float then x
        else Values.parse_numeric_literal(x) || Values.numeric_prefix(x).to_f
        end
      end
    end

    def sum(tuples)
      return nil if tuples.empty?
      terms = sum_terms(tuples)
      return real_sum(terms) if terms.any?(Float)
      total = terms.sum
      raise SqlError, "integer overflow" unless Values.integer_in_range?(total)
      total
    end

    # REAL sum: the exact integer sum up to the first REAL, then compensated summation (3.2).
    def real_sum(terms)
      first = terms.index { |t| t.is_a?(Float) }
      return terms.sum.to_f unless first
      s = terms[0...first].sum.to_f
      c = 0.0
      terms[first..].each do |term|
        v = term.to_f
        t = s + v
        c += s.abs > v.abs ? (s - t) + v : (v - t) + s
        s = t
      end
      s + c
    end

    def extreme(tuples, direction, collation)
      tuples.map(&:first).reduce { |best, v| Values.compare(v, best, collation) * direction > 0 ? v : best }
    end

    # Each value is preceded by its own separator (default ','; a NULL separator is nothing).
    def group_concat(tuples)
      return nil if tuples.empty?
      tuples.each_with_index.map do |(x, *rest), i|
        separator = rest.empty? ? "," : (rest[0].nil? ? "" : Values.text_form(rest[0]))
        (i.zero? ? "" : separator) + Values.text_form(x)
      end.join
    end
  end
end
