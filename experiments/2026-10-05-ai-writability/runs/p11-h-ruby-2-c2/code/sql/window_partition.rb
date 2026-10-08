# frozen_string_literal: true

require_relative 'ordering'

module SQL
  # The rows of one partition of a window, in the window's order, with their peer groups (SPEC 6.2).
  # Positions are 0-based.
  class WindowPartition
    attr_reader :rows, :indices

    # `items` are [index, row] pairs, `index` being where the row sits in the rows of the whole query;
    # `order` the window's Ordering::Terms.
    def initialize(items, order)
      keyed = items.map { |index, row| [order.map { |t| t.key(row, nil) }, [index, row]] }
      sorted = Ordering.sort(keyed, order)
      @keys = sorted.map(&:first)
      @indices = sorted.map { |_, (index, _)| index }
      @rows = sorted.map { |_, (_, row)| row }
      find_peers(order)
    end

    def size = @rows.size

    # Position of the first / last row of the peer group of position `i`.
    def peer_start(i) = @peer_starts[i]
    def peer_end(i) = @peer_ends[i]

    # Number of the peer group of position `i`, from 0.
    def peer_group(i) = @groups[i]

    # The value of the (only) ORDER BY term at position `i`.
    def range_value(i) = @keys[i][0]

    private

    def find_peers(order)
      @peer_starts = []
      @groups = []
      @keys.each_with_index do |key, i|
        if i.positive? && Ordering.compare_keys(order, @keys[i - 1], key).zero?
          @peer_starts << @peer_starts.last
          @groups << @groups.last
        else
          @peer_starts << i
          @groups << (@groups.empty? ? 0 : @groups.last + 1)
        end
      end
      @peer_ends = Array.new(size)
      (size - 1).downto(0) do |i|
        @peer_ends[i] = i < size - 1 && @peer_starts[i + 1] == @peer_starts[i] ? @peer_ends[i + 1] : i
      end
    end
  end
end
