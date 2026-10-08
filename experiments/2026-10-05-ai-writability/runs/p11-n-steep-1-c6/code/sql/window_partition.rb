# frozen_string_literal: true

require_relative "ast"
require_relative "evaluator"
require_relative "ordering"
require_relative "value"

module Sql
  # The rows of one partition of a window call, sorted by the window's ORDER BY, with their peer
  # groups and frames (spec 6.2). Positions are 0-based.
  class WindowPartition
    attr_reader :size

    def initialize(call, members)
      @call = call
      terms = call.order_by
      keys = members.map { |row| terms.map { |term| Evaluator.evaluate(term.expr, row) } }
      order = Ordering.sort((0...members.length).to_a, keys, terms)
      @rows = order.map { |i| members.fetch(i) }
      @keys = order.map { |i| keys.fetch(i) }
      @size = members.length
      @peer_first = Array.new(@size, 0)
      @peer_last = Array.new(@size, 0)
      @peer_group = Array.new(@size, 0)
      find_peers(terms)
    end

    def row(pos)
      @rows.fetch(pos)
    end

    # The position of the first / last peer of the row, and the number of peer groups before it.
    def peer_first(pos)
      @peer_first.fetch(pos)
    end

    def peer_last(pos)
      @peer_last.fetch(pos)
    end

    def peer_group(pos)
      @peer_group.fetch(pos)
    end

    # The rows of the frame of the row at pos, in partition order.
    def frame_rows(pos)
      frame = @call.frame
      first = frame_start(frame, pos)
      last = frame_end(frame, pos)
      first <= last ? @rows[first..last].to_a : []
    end

    private

    def find_peers(terms)
      group_start = 0
      group = 0
      (1..@size).each do |i|
        next unless i == @size || Ordering.compare_keys(@keys.fetch(i - 1), @keys.fetch(i), terms) != 0

        (group_start...i).each do |j|
          @peer_first[j] = group_start
          @peer_last[j] = i - 1
          @peer_group[j] = group
        end
        group_start = i
        group += 1
      end
    end

    def frame_start(frame, pos)
      bound = frame.first
      case bound.kind
      when :unbounded_preceding then 0
      when :current then frame.rows? ? pos : @peer_first.fetch(pos)
      when :preceding then frame.rows? ? [pos - rows_offset(bound), 0].max : range_edge(pos, bound, true)
      else frame.rows? ? pos + rows_offset(bound) : range_edge(pos, bound, true)
      end
    end

    def frame_end(frame, pos)
      bound = frame.last
      case bound.kind
      when :unbounded_following then @size - 1
      when :current then frame.rows? ? pos : @peer_last.fetch(pos)
      when :preceding then frame.rows? ? pos - rows_offset(bound) : range_edge(pos, bound, false)
      else frame.rows? ? [pos + rows_offset(bound), @size - 1].min : range_edge(pos, bound, false)
      end
    end

    def rows_offset(bound)
      bound.offset.to_i
    end

    # RANGE n PRECEDING / n FOLLOWING: the first (first true) or last row whose ORDER BY value is
    # not before / not after the current value moved by n in the direction of the sort. A NULL
    # current value has only its peers in range.
    def range_edge(pos, bound, first)
      term = @call.order_by.fetch(0)
      current = @keys.fetch(pos).fetch(0)
      return (first ? @peer_first : @peer_last).fetch(pos) if current.nil?

      target = shifted(current, bound, term)
      if first
        @keys.index { |key| Ordering.compare_term(key.fetch(0), target, term) >= 0 } || @size
      else
        (@size - 1).downto(0).find { |i| Ordering.compare_term(@keys.fetch(i).fetch(0), target, term) <= 0 } || -1
      end
    end

    def shifted(current, bound, term)
      offset = bound.offset || 0
      earlier = bound.kind == :preceding
      delta = earlier == !term.descending ? -offset : offset
      base = Value.to_number(current)
      base.is_a?(Integer) && delta.is_a?(Integer) ? base + delta : base.to_f + delta.to_f
    end
  end
end
