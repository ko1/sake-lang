# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "errors"
require_relative "identifier"

module Sql
  # Window calls (6.1, 6.2) at bind time: which names are window functions, how the Binder records a
  # call while binding (a Collector, or Forbidden where it is an error), how named windows resolve, and
  # that a frame is legal. Computing the values is WindowFunctions.
  module Windows
    # A bound window call. `function` is the folded name; `aggregate` is the Aggregates::Spec when it is
    # an aggregate over a frame (else nil); partition_by are bound exprs, order_by SortKeys, frame a
    # Frame (unbound offsets: literals) or nil for the default one.
    BoundCall = Data.define(:function, :args, :aggregate, :partition_by, :order_by, :frame)

    # Functions that exist only as window functions: name => allowed argument counts.
    ARITY = {
      "row_number" => 0..0, "rank" => 0..0, "dense_rank" => 0..0, "percent_rank" => 0..0, "cume_dist" => 0..0,
      "ntile" => 1..1, "lag" => 1..3, "lead" => 1..3,
      "first_value" => 1..1, "last_value" => 1..1, "nth_value" => 2..2
    }.freeze

    # Collects the window calls of a query as they are bound. Each becomes a WindowRef at `width + slot`
    # of the row the Query builds (the window values come right after the sources' values).
    class Collector
      attr_reader :calls

      def initialize(width, definitions)
        @width = width
        @definitions = definitions
        @calls = []
      end

      def resolve(over) = @definitions.resolve(over)

      def check_call(_name); end

      def check_alias(_expr, _alias_name); end

      def add(call, written_name)
        @calls << call
        WindowRef.new(@width + @calls.length - 1, written_name)
      end
    end

    # Where a window call is an error.
    class Forbidden
      def check_call(name)
        raise SqlError, "misuse of window function #{name}()"
      end

      # A result column's alias stands for its expression: an error if that holds a window call.
      def check_alias(expr, alias_name)
        raise SqlError, "misuse of aliased window function #{alias_name}" if Sql.find_node(expr) { |n| n.is_a?(WindowRef) }
      end
    end

    FORBIDDEN = Forbidden.new

    # The WINDOW clause of one simple select: name => WindowSpec, with bases merged in.
    class Definitions
      def initialize(defs)
        @specs = {}
        defs.each do |d|
          key = Sql.fold(d.name)
          raise SqlError, "duplicate WINDOW name: #{d.name}" if @specs.key?(key)
          @specs[key] = d.spec
        end
        @resolved = {}
        @specs.each_key { |key| named(key, key, []) }
      end

      # The spec an OVER stands for (a name, or a WindowSpec that may name a base), without a base.
      def resolve(over)
        return named(Sql.fold(over), over, []) if over.is_a?(String)
        over.base ? merge(over, []) : over
      end

      private

      def named(key, written, seen)
        spec = @specs[key] or raise SqlError, "no such window: #{written}"
        raise SqlError, "circular reference: #{written}" if seen.include?(key)
        @resolved[key] ||= spec.base ? merge(spec, seen + [key]) : spec
      end

      # `spec` adds its own parts to those of its base (it may not replace any).
      def merge(spec, seen)
        base = named(Sql.fold(spec.base), spec.base, seen)
        conflict = if !spec.partition_by.empty? && !base.partition_by.empty? then "PARTITION BY"
                   elsif !spec.order_by.empty? && !base.order_by.empty? then "ORDER BY"
                   elsif spec.frame && base.frame then "frame specification"
                   end
        raise SqlError, "cannot override #{conflict} of window: #{spec.base}" if conflict
        WindowSpec.new(nil, spec.partition_by.empty? ? base.partition_by : spec.partition_by,
                       spec.order_by.empty? ? base.order_by : spec.order_by, spec.frame || base.frame)
      end
    end

    module_function

    # Does this name only work as a window function (it needs OVER)?
    def window_only?(name)
      ARITY.key?(Sql.fold(name))
    end

    # Every window call (Call with `over`) in the expressions, outermost first.
    def calls_in(exprs)
      found = []
      exprs.each { |expr| collect_calls(expr, found) }
      found
    end

    def collect_calls(node, found)
      found << node if node.is_a?(Call) && node.over
      Sql.children(node).each { |child| collect_calls(child, found) }
    end

    # The bound call for `call` (an unbound Call with `over`) whose arguments and spec parts are bound.
    def bound_call(call, args, spec, partition_by, order_by)
      name = Sql.fold(call.name)
      aggregate = nil
      if ARITY.key?(name)
        raise SqlError, "wrong number of arguments to function #{call.name}()" if call.star || !ARITY[name].cover?(args.length)
      elsif Aggregates.aggregate_call?(call)
        aggregate = Aggregates.spec_for(call, args, [])
      else
        raise SqlError, "#{call.name}() may not be used as a window function"
      end
      check_frame(spec, order_by.length)
      BoundCall.new(name, args, aggregate, partition_by, order_by, spec.frame)
    end

    # Frame rules of 6.2.
    def check_frame(spec, order_terms)
      frame = spec.frame or return
      first = frame.start
      last = frame.stop
      if first.kind == :unbounded_following || last.kind == :unbounded_preceding ||
         (first.kind == :current && last.kind == :preceding) ||
         (first.kind == :following && %i[current preceding].include?(last.kind))
        raise SqlError, "unsupported frame specification"
      end
      has_offset = [first, last].any?(&:offset)
      if frame.units == :range && has_offset && order_terms != 1
        raise SqlError, "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression"
      end
      { "starting" => first, "ending" => last }.each do |which, bound|
        next unless bound.offset
        kind = frame.units == :rows ? "integer" : "number"
        valid = bound.offset >= 0 && (frame.units == :range || bound.offset.is_a?(Integer))
        raise SqlError, "frame #{which} offset must be a non-negative #{kind}" unless valid
      end
    end
  end
end
