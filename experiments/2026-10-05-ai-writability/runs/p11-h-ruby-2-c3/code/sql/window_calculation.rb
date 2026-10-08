# frozen_string_literal: true

require_relative 'aggregate_functions'
require_relative 'aggregates'
require_relative 'errors'
require_relative 'ordering'
require_relative 'values'
require_relative 'window_frame'
require_relative 'window_functions'
require_relative 'window_partition'

module SQL
  # One window call, ready to run (SPEC 6.1 - 6.3): `values(rows)` gives its result for each of the
  # rows of a query (the rows after WHERE, GROUP BY and HAVING). Expressions are compiled in `compiler`'s
  # scope, so name errors surface before any row is read.
  class WindowCalculation
    # `window_call` is a WindowCall; `spec` its WindowSpec with the base window already merged in.
    def initialize(window_call, spec, compiler)
      call = window_call.call
      @partition_by = spec.partition_by.map { |e| compiler.compile(e).fn }
      @order = spec.order_by.map { |t| Ordering::Term.new(t.desc, t.nulls, nil, compiler.compile(t.expr).fn) }
      @frame = WindowFrameRange.new(spec.frame, @order)
      if (function = WindowFunctions.lookup(call.name))
        unless function.arity.cover?(call.args.size)
          raise SqlError, "wrong number of arguments to function #{call.name}()"
        end

        @function = function.impl
        @args = call.args.map { |a| compiler.compile(a).fn }
      elsif Aggregates.aggregate?(call)
        @aggregate = Aggregate.new(call, compiler)
      else
        raise SqlError, "no such function: #{call.name}"
      end
    end

    def values(rows)
      results = Array.new(rows.size)
      partitions(rows).each do |part|
        part.size.times { |i| results[part.indices[i]] = value_at(part, i) }
      end
      results
    end

    private

    # Rows with equal PARTITION BY values (as in GROUP BY) form a partition.
    def partitions(rows)
      groups = rows.each_with_index.group_by { |row, _| @partition_by.map { |f| Values.group_key(f.call(row)) } }
      groups.each_value.map { |items| WindowPartition.new(items.map { |row, index| [index, row] }, @order) }
    end

    def value_at(part, i)
      return @function.call(part, i, @args, @frame) unless @aggregate

      first, last = @frame.bounds(part, i)
      @aggregate.call(first > last ? [] : part.rows[first..last])
    end
  end
end
