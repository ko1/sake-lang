module MiniSql
  # The rows of one window partition in the order of the window's ORDER BY, with their peer groups, and the
  # frame (SPEC 6.2) of each position. Positions are 0-based.
  class WindowPartition
    # The candidates are the partition's rows (values) with their ORDER BY values (keys) and their number in the
    # input (serial); order is the window's ORDER BY.
    def initialize(order, candidates)
      @order = order
      @entries = candidates.sort { |a, b| SortKey.compare_candidates(order, a, b) }
      @peer_first = [] # @type ivar @peer_first: Array[Integer]
      @peer_last = Array.new(@entries.length, 0) # @type ivar @peer_last: Array[Integer]
      @peer_group = [] # @type ivar @peer_group: Array[Integer]
      find_peers
    end

    def size
      @entries.length
    end

    # The row at a position.
    def row(position)
      @entries.fetch(position).values
    end

    # The number the input gave the row at a position.
    def serial(position)
      @entries.fetch(position).serial
    end

    def peer_first(position)
      @peer_first.fetch(position)
    end

    def peer_last(position)
      @peer_last.fetch(position)
    end

    # The number (from 0) of the peer group of the row at a position.
    def peer_group(position)
      @peer_group.fetch(position)
    end

    # The rows of the frame as positions first..last; last < first for an empty frame.
    def frame(position, spec)
      first = [edge(spec, spec.start, position, true), 0].max
      last = [edge(spec, spec.finish, position, false), size - 1].min
      [first, last]
    end

    private

    def find_peers
      first = 0
      group = -1
      @entries.each_with_index do |entry, position|
        if position.zero? || !peers?(@entries.fetch(position - 1), entry)
          first = position
          group += 1
        end
        @peer_first << first
        @peer_group << group
      end
      last = size - 1
      (size - 1).downto(0) do |position|
        last = position if position == size - 1 || @peer_first.fetch(position + 1) != @peer_first.fetch(position)
        @peer_last[position] = last
      end
    end

    def peers?(left, right)
      @order.each_with_index.all? do |key, i|
        key.compare(left.keys.fetch(i, nil), right.keys.fetch(i, nil)).zero?
      end
    end

    # The position a frame bound stands for from the row at `position` (may lie outside the partition).
    def edge(spec, bound, position, start)
      case bound.kind
      when :unbounded_preceding then 0
      when :unbounded_following then size - 1
      when :current then spec.mode == :rows ? position : (start ? peer_first(position) : peer_last(position))
      else spec.mode == :rows ? rows_edge(bound, position) : range_edge(bound, position, start)
      end
    end

    def rows_edge(bound, position)
      amount = bound.amount.to_i
      bound.kind == :preceding ? position - amount : position + amount
    end

    # RANGE n PRECEDING / n FOLLOWING: a start is the first row, an end the last row, whose value of the single
    # ORDER BY term is on the near side of the current value shifted by n. NULL rows are in range of a NULL row only.
    def range_edge(bound, position, start)
      current = @entries.fetch(position).keys.fetch(0, nil)
      return(start ? peer_first(position) : peer_last(position)) if current.nil?
      key = @order.fetch(0)
      descending = key.descending
      amount = bound.amount.to_f
      shifted = Value.to_number(current).to_f
      target = (bound.kind == :preceding) != descending ? shifted - amount : shifted + amount
      last_in_range = -1
      @entries.each_with_index do |entry, i|
        value = entry.keys.fetch(0, nil)
        next if value.nil?
        order = Value.compare(value, target)
        order = -order if descending
        return i if start && order >= 0
        last_in_range = i if !start && order <= 0
      end
      start ? size : last_in_range
    end
  end
end
