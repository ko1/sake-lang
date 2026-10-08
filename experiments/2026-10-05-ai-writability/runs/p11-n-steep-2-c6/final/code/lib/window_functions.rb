module MiniSql
  # The window-only functions (SPEC 6.3); the aggregates are computed by Aggregates over the frame.
  module WindowFunctions
    # name => accepted numbers of arguments.
    ARITY = {
      "row_number" => (0..0), "rank" => (0..0), "dense_rank" => (0..0), "percent_rank" => (0..0),
      "cume_dist" => (0..0), "ntile" => (1..1), "lag" => (1..3), "lead" => (1..3),
      "first_value" => (1..1), "last_value" => (1..1), "nth_value" => (2..2)
    }.freeze

    # The functions whose result depends on the frame; the others ignore it.
    FRAME_FUNCTIONS = %w[first_value last_value nth_value].freeze

    # Whether `lower` (lower case) is a window-only function.
    def self.known?(lower)
      ARITY.key?(lower)
    end

    def self.arity_ok?(lower, count)
      range = ARITY[lower]
      range ? range.cover?(count) : false
    end

    def self.uses_frame?(name)
      FRAME_FUNCTIONS.include?(name)
    end

    # The result for the row at `position`; its frame is the positions first..last.
    def self.compute(name, args, partition, position, first, last)
      case name
      when "row_number" then position + 1
      when "rank" then partition.peer_first(position) + 1
      when "dense_rank" then partition.peer_group(position) + 1
      when "percent_rank" then percent_rank(partition, position)
      when "cume_dist" then (partition.peer_last(position) + 1).to_f / partition.size
      when "ntile" then ntile(args, partition, position)
      when "lag" then shifted(args, partition, position, -1)
      when "lead" then shifted(args, partition, position, 1)
      when "first_value" then at(args, partition, first <= last ? first : nil)
      when "last_value" then at(args, partition, first <= last ? last : nil)
      else nth_value(args, partition, position, first, last)
      end
    end

    def self.percent_rank(partition, position)
      return 0.0 if partition.size == 1
      partition.peer_first(position).to_f / (partition.size - 1)
    end

    # The bucket of `position` when the partition is cut into n buckets, the larger ones first.
    def self.ntile(args, partition, position)
      buckets = positive_integer(Evaluator.evaluate(args.fetch(0), partition.row(0)))
      raise SqlError, "argument of ntile must be a positive integer" unless buckets
      size, extra = partition.size.divmod(buckets)
      return position + 1 if size.zero?
      large = extra * (size + 1)
      position < large ? position / (size + 1) + 1 : extra + (position - large) / size + 1
    end

    # lag / lead: the value of args[0] on the row `direction * k` positions away, else args[2] (default NULL) on
    # the current row.
    def self.shifted(args, partition, position, direction)
      row = partition.row(position)
      step = 1
      if args.length > 1
        count = Evaluator.evaluate(args.fetch(1), row)
        return nil if count.nil?
        step = Value.to_integer(count)
      end
      target = position + direction * step
      if target >= 0 && target < partition.size
        Evaluator.evaluate(args.fetch(0), partition.row(target))
      else
        fallback = args[2]
        fallback ? Evaluator.evaluate(fallback, row) : nil
      end
    end

    def self.nth_value(args, partition, position, first, last)
      wanted = positive_integer(Evaluator.evaluate(args.fetch(1), partition.row(position)))
      raise SqlError, "second argument to nth_value must be a positive integer" unless wanted
      at(args, partition, first + wanted - 1 <= last ? first + wanted - 1 : nil)
    end

    # args[0] on the row at `position` of the partition; NULL for nil.
    def self.at(args, partition, position)
      position ? Evaluator.evaluate(args.fetch(0), partition.row(position)) : nil
    end

    # The value as an integer of at least 1, else nil.
    def self.positive_integer(value)
      number = value.is_a?(Integer) || value.is_a?(Float) ? value : nil
      return nil unless number && number >= 1 && number == number.floor
      number.to_i
    end
  end
end
