module MiniSql
  # A window after name resolution (SPEC 6.1): its PARTITION BY expressions, its ORDER BY keys and its frame (the
  # default one filled in).
  class WindowDef
    attr_reader :partition_by, :order, :frame

    # Raises SqlError for a frame that cannot be used with this ORDER BY (SPEC 6.2).
    def self.build(partition_by, order, frame)
      frame ||= FrameSpec.new(:range, FrameBound.new(:unbounded_preceding, nil), FrameBound.new(:current, nil))
      start = frame.start.kind
      finish = frame.finish.kind
      if (start == :current && finish == :preceding) ||
         ((start == :following || start == :unbounded_following) && finish != :following && finish != :unbounded_following) ||
         finish == :unbounded_preceding
        raise SqlError, "unsupported frame specification"
      end
      if frame.mode == :range && (frame.start.offset? || frame.finish.offset?) && order.length != 1
        raise SqlError, "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression"
      end
      new(partition_by, order, frame)
    end

    def initialize(partition_by, order, frame)
      @partition_by = partition_by
      @order = order
      @frame = frame
    end

    # Raises SqlError for a negative (or, under ROWS, fractional) offset; SQLite finds it when it first reads a row.
    def check_offsets
      noun = @frame.mode == :rows ? "integer" : "number"
      check_offset(@frame.start, "starting", noun)
      check_offset(@frame.finish, "ending", noun)
    end

    private

    def check_offset(bound, which, noun)
      offset = bound.offset
      return unless offset
      return unless offset < 0 || (@frame.mode == :rows && !offset.is_a?(Integer))
      raise SqlError, "frame #{which} offset must be a non-negative #{noun}"
    end
  end
end
