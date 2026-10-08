# frozen_string_literal: true

require_relative 'ast'
require_relative 'errors'

module SQL
  # The frame of a window (SPEC 6.2): which rows of a partition the current row's result is computed
  # from. Validated when the query is planned; `bounds` then gives the rows for one row of a partition.
  class WindowFrameRange
    DEFAULT = WindowFrame.new(:range, FrameBound.new(:unbounded_preceding, nil), FrameBound.new(:current, nil))
    OFFSET_KINDS = %i[preceding following].freeze

    # `frame` is a WindowFrame or nil (the default frame); `order` the window's Ordering::Terms.
    def initialize(frame, order)
      frame ||= DEFAULT
      @unit = frame.unit
      @start = frame.start
      @finish = frame.finish
      @desc = order.first&.desc
      validate(order.size)
    end

    # [first, last] positions in `partition` (a WindowPartition) of the frame of the row at position
    # `i`, both inside the partition; first > last when the frame is empty.
    def bounds(partition, i)
      first = start_position(partition, i)
      last = end_position(partition, i)
      [[first, 0].max, [last, partition.size - 1].min]
    end

    private

    def validate(order_size)
      unless supported?
        raise SqlError, 'unsupported frame specification'
      end
      if @unit == :range && (offset?(@start) || offset?(@finish)) && order_size != 1
        raise SqlError, 'RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression'
      end
      check_offset(@start, 'starting')
      check_offset(@finish, 'ending')
    end

    # A frame may not start after its current row has ended, nor end before it has started.
    def supported?
      return false if @start.kind == :unbounded_following || @finish.kind == :unbounded_preceding

      case @start.kind
      when :current then @finish.kind != :preceding
      when :following then @finish.kind == :following || @finish.kind == :unbounded_following
      else true
      end
    end

    def offset?(bound) = OFFSET_KINDS.include?(bound.kind)

    def check_offset(bound, which)
      return unless offset?(bound)

      n = bound.offset
      if @unit == :rows
        return if n.is_a?(Integer) && !n.negative?

        raise SqlError, "frame #{which} offset must be a non-negative integer"
      end
      raise SqlError, "frame #{which} offset must be a non-negative number" if n.negative?
    end

    def start_position(partition, i)
      case @start.kind
      when :unbounded_preceding then 0
      when :current then @unit == :rows ? i : partition.peer_start(i)
      else @unit == :rows ? i + signed(@start) : range_start(partition, i, @start)
      end
    end

    def end_position(partition, i)
      case @finish.kind
      when :unbounded_following then partition.size - 1
      when :current then @unit == :rows ? i : partition.peer_end(i)
      else @unit == :rows ? i + signed(@finish) : range_end(partition, i, @finish)
      end
    end

    def signed(bound) = bound.kind == :following ? bound.offset : -bound.offset

    # RANGE offsets: the first / last row whose ORDER BY value is within the offset of the current
    # row's. A NULL value is within range of other NULLs only, that is of its peers.
    def range_start(partition, i, bound)
      limit = range_limit(partition, i, bound) or return partition.peer_start(i)
      partition.size.times.find { |j| (v = number_at(partition, j)) && (@desc ? v <= limit : v >= limit) } ||
        partition.size
    end

    def range_end(partition, i, bound)
      limit = range_limit(partition, i, bound) or return partition.peer_end(i)
      (partition.size - 1).downto(0).find { |j| (v = number_at(partition, j)) && (@desc ? v >= limit : v <= limit) } || -1
    end

    # The value that the current row's value plus / minus the offset reaches, or nil for a NULL.
    def range_limit(partition, i, bound)
      v = number_at(partition, i) or return nil
      @desc ? v - signed(bound) : v + signed(bound)
    end

    def number_at(partition, j)
      v = partition.range_value(j)
      v if v.is_a?(Numeric)
    end
  end
end
