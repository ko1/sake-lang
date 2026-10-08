# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "errors"
require_relative "evaluator"
require_relative "ordering"
require_relative "values"
require_relative "window_frames"
require_relative "windows"

module Sql
  # Computing window calls (6.2, 6.3) over the rows a query produced (after WHERE / GROUP BY / HAVING).
  module WindowFunctions
    module_function

    # rows: arrays that have a free slot for each call at `offset + k`; fills them in.
    def apply(rows, calls, offset)
      calls.each_with_index do |call, k|
        values = compute(call, rows)
        rows.each_with_index { |row, i| row[offset + k] = values[i] }
      end
    end

    # The call's value for each row (by the row's index in `rows`).
    def compute(call, rows)
      values = Array.new(rows.length)
      partitions = rows.each_index.group_by do |i|
        call.partition_by.map { |e| Values.group_key(Evaluator.evaluate(e, rows[i])) }
      end
      partitions.each_value do |indexes|
        ordered = Ordering.sort(indexes, call.order_by) { |i, key| Evaluator.evaluate(key.expr, rows[i]) }
        results = partition_results(call, ordered.map { |i| rows[i] })
        ordered.each_with_index { |i, pos| values[i] = results[pos] }
      end
      values
    end

    # The call's value for each row of one sorted partition.
    def partition_results(call, rows)
      frames = WindowFrames.new(rows, call.order_by, call.frame)
      size = rows.length
      case call.function
      when "row_number" then Array.new(size) { |i| i + 1 }
      when "rank" then Array.new(size) { |i| frames.peer_first(i) + 1 }
      when "dense_rank" then Array.new(size) { |i| frames.peer_group(i) }
      when "percent_rank"
        Array.new(size) { |i| size == 1 ? 0.0 : frames.peer_first(i).to_f / (size - 1) }
      when "cume_dist" then Array.new(size) { |i| (frames.peer_last(i) + 1).to_f / size }
      when "ntile" then ntile(call, rows)
      when "lag" then shifted(call, rows, -1)
      when "lead" then shifted(call, rows, 1)
      when "first_value" then frame_edge(call, rows, frames, 0)
      when "last_value" then frame_edge(call, rows, frames, 1)
      when "nth_value" then nth_value(call, rows, frames)
      else aggregate(call.aggregate, rows, frames)
      end
    end

    # The aggregate over each row's frame. Arguments are evaluated once per row, then the aggregate
    # runs on those tuples (the spec's arguments become references into a tuple).
    def aggregate(spec, rows, frames)
      tuples = rows.map { |row| spec.args.map { |a| Evaluator.evaluate(a, row) } }
      on_tuples = spec.with(args: spec.args.each_index.map { |i| ColumnRef.new(i, nil) })
      previous = nil
      result = nil
      Array.new(rows.length) do |i|
        frame = frames.frame(i)
        unless previous && frame == previous
          result = Aggregates.compute(on_tuples, frame ? tuples[frame[0]..frame[1]] : [])
          previous = frame
        end
        result
      end
    end

    # The bucket 1..n of each row; the n is read on the partition's first row.
    def ntile(call, rows)
      n = Evaluator.evaluate(call.args[0], rows.first)
      n = n.nil? ? 0 : Values.cast(n, :integer)
      raise SqlError, "argument of ntile must be a positive integer" unless n.is_a?(Integer) && n > 0
      size = rows.length
      small, larger = size.divmod([n, size].min)
      Array.new(size) do |pos|
        if pos < larger * (small + 1) then pos / (small + 1) + 1
        else larger + (pos - larger * (small + 1)) / small + 1
        end
      end
    end

    # lag (direction -1) / lead (+1): x on the row k positions away, else the default (evaluated on the current row).
    def shifted(call, rows, direction)
      xs = rows.map { |row| Evaluator.evaluate(call.args[0], row) }
      rows.each_index.map do |pos|
        row = rows[pos]
        k = call.args.length > 1 ? Evaluator.evaluate(call.args[1], row) : 1
        next nil if k.nil?
        target = pos + direction * Values.cast(k, :integer)
        if target.between?(0, rows.length - 1) then xs[target]
        elsif call.args.length > 2 then Evaluator.evaluate(call.args[2], row)
        end
      end
    end

    # first_value (edge 0) / last_value (edge 1): x on the frame's first / last row.
    def frame_edge(call, rows, frames, edge)
      Array.new(rows.length) do |pos|
        frame = frames.frame(pos)
        frame && Evaluator.evaluate(call.args[0], rows[frame[edge]])
      end
    end

    def nth_value(call, rows, frames)
      Array.new(rows.length) do |pos|
        n = nth_argument(Evaluator.evaluate(call.args[1], rows[pos]))
        frame = frames.frame(pos)
        target = frame && frame[0] + n - 1
        target && target <= frame[1] ? Evaluator.evaluate(call.args[0], rows[target]) : nil
      end
    end

    def nth_argument(value)
      value = value.to_i if value.is_a?(Float) && value == value.floor
      raise SqlError, "second argument to nth_value must be a positive integer" unless value.is_a?(Integer) && value > 0
      value
    end
  end
end
