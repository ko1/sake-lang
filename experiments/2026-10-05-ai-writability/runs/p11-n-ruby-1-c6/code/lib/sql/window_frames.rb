# frozen_string_literal: true

require_relative "ast"
require_relative "evaluator"
require_relative "values"

module Sql
  # One partition of a window, already sorted by the window's ORDER BY: its peer groups and, for each
  # position, the frame (6.2). Positions are 0-based; a frame is [first, last] positions, or nil if empty.
  class WindowFrames
    DEFAULT_FRAME = Frame.new(:range, FrameBound.new(:unbounded_preceding, nil), FrameBound.new(:current, nil))

    attr_reader :size

    # rows: the partition's rows in order; order_by: the window's SortKeys; frame: a Frame or nil.
    def initialize(rows, order_by, frame)
      @size = rows.length
      @frame = frame || DEFAULT_FRAME
      @order_key = order_by.first
      @values = order_by.empty? ? [] : rows.map { |row| Evaluator.evaluate(@order_key.expr, row) }
      find_peers(rows, order_by)
    end

    def peer_first(pos) = @peer_first[pos]

    def peer_last(pos) = @peer_last[pos]

    # The 1-based number of the peer group of the row at `pos`.
    def peer_group(pos) = @peer_group[pos]

    def frame(pos)
      first = [bound_start(@frame.start, pos), 0].max
      last = [bound_end(@frame.stop, pos), @size - 1].min
      first > last ? nil : [first, last]
    end

    private

    # Rows with equal ORDER BY values (equal as in GROUP BY) are peers; all rows are without ORDER BY.
    def find_peers(rows, order_by)
      keys = rows.map { |row| order_by.map { |k| Values.group_key(Evaluator.evaluate(k.expr, row)) } }
      @peer_first = Array.new(@size)
      @peer_last = Array.new(@size)
      @peer_group = Array.new(@size)
      group = 0
      pos = 0
      while pos < @size
        stop = pos
        stop += 1 while stop + 1 < @size && keys[stop + 1] == keys[pos]
        group += 1
        (pos..stop).each { |i| @peer_first[i] = pos; @peer_last[i] = stop; @peer_group[i] = group }
        pos = stop + 1
      end
    end

    def bound_start(bound, pos)
      case bound.kind
      when :unbounded_preceding then 0
      when :unbounded_following then @size
      when :current then @frame.units == :rows ? pos : @peer_first[pos]
      else @frame.units == :rows ? pos + row_offset(bound) : range_start(bound, pos)
      end
    end

    def bound_end(bound, pos)
      case bound.kind
      when :unbounded_preceding then -1
      when :unbounded_following then @size - 1
      when :current then @frame.units == :rows ? pos : @peer_last[pos]
      else @frame.units == :rows ? pos + row_offset(bound) : range_end(bound, pos)
      end
    end

    def row_offset(bound) = bound.kind == :preceding ? -bound.offset : bound.offset

    # In RANGE the offset applies to the one ORDER BY value, in the direction of the sort: the first row
    # whose value is not before `current -/+ n`. NULL (and non-numeric) values only match each other.
    def range_start(bound, pos)
      target = range_target(bound, pos) or return @peer_first[pos]
      (0...@size).find { |i| (v = sorted_value(i)) && v >= target } || @size
    end

    def range_end(bound, pos)
      target = range_target(bound, pos) or return @peer_last[pos]
      (@size - 1).downto(0).find { |i| (v = sorted_value(i)) && v <= target } || -1
    end

    # The value to reach, in sort direction, or nil when the current row has no numeric value.
    def range_target(bound, pos)
      current = sorted_value(pos) or return nil
      bound.kind == :preceding ? current - bound.offset : current + bound.offset
    end

    # A row's ORDER BY value negated under DESC so that it increases along the partition; nil if not a number.
    def sorted_value(pos)
      v = @values[pos]
      return nil unless v.is_a?(Integer) || v.is_a?(Float)
      @order_key.desc ? -v : v
    end
  end
end
