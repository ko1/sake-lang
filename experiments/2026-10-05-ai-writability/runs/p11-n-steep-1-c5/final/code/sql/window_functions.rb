# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "error"
require_relative "evaluator"
require_relative "value"
require_relative "window_partition"

module Sql
  # The functions that only exist as window functions (spec 6.3), and their value on a row of a
  # window partition. The aggregates used with OVER are computed by Aggregates over the frame.
  module WindowFunctions
    # name => [fewest arguments, most arguments]
    ARITY = {
      "row_number" => [0, 0], "rank" => [0, 0], "dense_rank" => [0, 0], "percent_rank" => [0, 0],
      "cume_dist" => [0, 0], "ntile" => [1, 1], "lag" => [1, 3], "lead" => [1, 3],
      "first_value" => [1, 1], "last_value" => [1, 1], "nth_value" => [2, 2]
    }.freeze

    # Whether this (lower-case) name is one of the window-only functions.
    def self.window_only?(function)
      ARITY.key?(function)
    end

    def self.accepts?(function, argc)
      range = ARITY.fetch(function)
      argc >= range.fetch(0) && argc <= range.fetch(1)
    end

    # The value of a window call on the row at position pos of its partition.
    def self.value(call, partition, pos)
      aggregate = call.aggregate
      return Aggregates.compute(aggregate, partition.frame_rows(pos)) if aggregate

      case call.function
      when "row_number" then pos + 1
      when "rank" then partition.peer_first(pos) + 1
      when "dense_rank" then partition.peer_group(pos) + 1
      when "percent_rank" then percent_rank(partition, pos)
      when "cume_dist" then (partition.peer_last(pos) + 1).to_f / partition.size
      when "ntile" then ntile(call, partition, pos)
      when "lag", "lead" then shifted(call, partition, pos)
      when "first_value" then frame_value(call, partition, pos, 0)
      when "last_value" then frame_value(call, partition, pos, -1)
      else nth_value(call, partition, pos)
      end
    end

    def self.percent_rank(partition, pos)
      return 0.0 if partition.size == 1

      partition.peer_first(pos).to_f / (partition.size - 1)
    end

    # The bucket of the row when size rows are split into n buckets, larger ones first.
    def self.ntile(call, partition, pos)
      n = integer_argument(call, partition, pos, 0)
      raise Error, "argument of ntile must be a positive integer" if n.nil? || n < 1

      base = partition.size / n
      extra = partition.size % n
      big = extra * (base + 1)
      pos < big ? pos / (base + 1) + 1 : extra + (pos - big) / base + 1
    end

    # lag(x, k, d) and lead(x, k, d): x on the row k positions away, else d.
    def self.shifted(call, partition, pos)
      row = partition.row(pos)
      steps = call.args.length > 1 ? integer_argument(call, partition, pos, 1) : 1
      return nil if steps.nil?

      target = call.function == "lag" ? pos - steps : pos + steps
      if target >= 0 && target < partition.size
        Evaluator.evaluate(call.args.fetch(0), partition.row(target))
      else
        default = call.args[2]
        default ? Evaluator.evaluate(default, row) : nil
      end
    end

    # first_value (which 0) and last_value (-1): the argument on that row of the frame.
    def self.frame_value(call, partition, pos, which)
      rows = partition.frame_rows(pos)
      row = rows[which]
      row ? Evaluator.evaluate(call.args.fetch(0), row) : nil
    end

    def self.nth_value(call, partition, pos)
      n = integer_argument(call, partition, pos, 1)
      raise Error, "second argument to nth_value must be a positive integer" if n.nil? || n < 1

      row = partition.frame_rows(pos)[n - 1]
      row ? Evaluator.evaluate(call.args.fetch(0), row) : nil
    end

    # The integer value of an argument on the current row; nil for NULL or a non-integer.
    def self.integer_argument(call, partition, pos, index)
      value = Evaluator.evaluate(call.args.fetch(index), partition.row(pos))
      case value
      when Integer then value
      when Float then Value.integer_exact(value)
      when String
        number = Value.parse_numeric_text(value)
        number.is_a?(Integer) ? number : nil
      end
    end
  end
end
