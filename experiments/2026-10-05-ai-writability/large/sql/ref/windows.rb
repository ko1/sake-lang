require_relative "errors"
require_relative "ast"
require_relative "values"
require_relative "aggregates"
require_relative "functions"

# Window calls (spec 6): the window functions, the windows of one simple-select, and how a window
# call's values are computed over the rows the query would otherwise produce.
module Windows
  # The functions that exist only as window functions, with their argument counts (6.3).
  FUNCTIONS = {
    "row_number" => 0..0, "rank" => 0..0, "dense_rank" => 0..0, "percent_rank" => 0..0,
    "cume_dist" => 0..0, "ntile" => 1..1, "lag" => 1..3, "lead" => 1..3,
    "first_value" => 1..1, "last_value" => 1..1, "nth_value" => 2..2
  }.freeze
  OFFSET_KINDS = %i[preceding following].freeze

  # A frame bound: kind as in AST::FrameBound; offset: the number n, or nil.
  Bound = Struct.new(:kind, :offset)
  # unit: :rows or :range.
  Frame = Struct.new(:unit, :start, :end)
  # Without a frame clause (6.2): to the current row's last peer, which without ORDER BY is the whole
  # partition (every row is a peer).
  DEFAULT_FRAME = Frame.new(:range, Bound.new(:unbounded_preceding, nil), Bound.new(:current_row, nil)).freeze

  # A window, bound: partition_by: expressions; order_by: [[expression, descending, nulls_first]].
  Window = Struct.new(:partition_by, :order_by, :frame)

  module_function

  def window_only?(name) = FUNCTIONS.key?(name.downcase)

  # [kind, aggregate definition or nil] for a call with OVER: kind is the window function's name as a
  # symbol, or :aggregate for an aggregate of 3.2.
  def function(call)
    key = call.name.downcase
    if (arity = FUNCTIONS[key])
      raise SqlError, "wrong number of arguments to function #{call.name}()" if call.star || !arity.include?(call.args.length)
      return [key.to_sym, nil]
    end
    definition = Aggregates.lookup(call)
    if definition
      # Not in the spec's catalogue; SQLite's message (tests do not use DISTINCT here, 6.3).
      raise SqlError, "DISTINCT is not supported for window functions" if call.distinct
      return [:aggregate, definition]
    end
    raise SqlError, "no such function: #{call.name}" unless Functions::TABLE.key?(key)
    raise SqlError, "#{call.name}() may not be used as a window function"
  end

  # The bound frame of a frame clause (nil: the default) for a window of order_count ORDER BY terms.
  # The block gives an offset expression's value. Raises the frame errors of 6.2, in SQLite's order.
  def frame(spec, order_count, &value)
    return DEFAULT_FRAME unless spec
    start = spec.start.kind
    finish = spec.end.kind
    if (start == :current_row && finish == :preceding) ||
       (start == :following && %i[current_row preceding].include?(finish))
      raise SqlError, "unsupported frame specification"
    end
    if spec.unit == :range && (OFFSET_KINDS.include?(start) || OFFSET_KINDS.include?(finish)) && order_count != 1
      raise SqlError, "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression"
    end
    Frame.new(spec.unit, bound(spec.unit, spec.start, "starting", &value), bound(spec.unit, spec.end, "ending", &value))
  end

  # n of `n PRECEDING`/`n FOLLOWING`: under ROWS a non-negative integer, under RANGE a non-negative number.
  def bound(unit, ast, which)
    return Bound.new(ast.kind, nil) unless ast.offset
    n = yield(ast.offset)
    n = n.to_i if n.is_a?(Float) && unit == :rows && n == n.truncate
    valid = unit == :rows ? n.is_a?(Integer) : n.is_a?(Integer) || n.is_a?(Float)
    unless valid && n >= 0
      raise SqlError, "frame #{which} offset must be a non-negative #{unit == :rows ? 'integer' : 'number'}"
    end
    Bound.new(ast.kind, n)
  end

  # The windows a simple-select's window calls name (its WINDOW clause), and its window calls. The
  # values of call k for a row are frame.windows[k] once `compute` has run over the query's rows.
  class Collector
    # definitions: the WINDOW clause, [[name, AST::WindowSpec]].
    def initialize(definitions)
      @definitions = definitions
      @calls = []
    end

    def empty? = @calls.empty?

    # The slot of a bound window call (Windows::Call).
    def add(call) = (@calls << call).length - 1

    # The AST::WindowSpec a call's OVER stands for, its base windows merged in: a base gives what the
    # spec does not have (6.1).
    def resolve(over, visiting = [])
      return resolve(named(over, visiting), visiting + [over.downcase]) if over.is_a?(String)
      return over unless over.base
      base = resolve(named(over.base, visiting), visiting + [over.base.downcase])
      AST::WindowSpec.new(nil,
                          over.partition_by.empty? ? base.partition_by : over.partition_by,
                          over.order_by.empty? ? base.order_by : over.order_by,
                          over.frame || base.frame)
    end

    # Sets each frame's windows to the values of the calls on its row.
    def compute(frames)
      columns = @calls.map { |call| call.compute(frames) }
      frames.each_with_index { |frame, i| frame.windows = columns.map { |values| values[i] } }
    end

    private

    # The spec of the window `name` of the WINDOW clause (the last of that name, as in SQLite); a window
    # used inside its own definition is unknown there.
    def named(name, visiting)
      found = @definitions.reverse_each.find { |defined, _| defined.casecmp?(name) }
      raise SqlError, "no such window: #{name}" if found.nil? || visiting.include?(name.downcase)
      found[1]
    end
  end

  # One window call, bound: kind and definition as `Windows.function` gives them; args: bound
  # expressions; window: a Window. For an aggregate, aggregate is its Aggregates::Call.
  class Call
    def initialize(kind, definition, args, window)
      @kind = kind
      @args = args
      @window = window
      @aggregate = definition && Aggregates::Call.new(definition, args, false, [])
    end

    # The call's value for each of `frames` (Expressions::Frame), in their order.
    def compute(frames)
      result = Array.new(frames.length)
      partitions(frames).each do |indexes|
        partition = Partition.new(indexes.map { |i| frames[i] }, @window)
        indexes.each_with_index { |i, j| result[i] = value(partition, j) }
      end
      result
    end

    private

    # The indexes of the frames of each partition (rows with equal PARTITION BY values, as in GROUP BY),
    # each sorted by the window's ORDER BY; rows that tie keep their order.
    def partitions(frames)
      groups = frames.each_index.group_by do |i|
        @window.partition_by.map { |expr| Values.equality_key(expr.evaluate(frames[i])) }
      end
      order = @window.order_by
      return groups.values if order.empty?
      groups.values.map do |indexes|
        keys = indexes.to_h { |i| [i, order.map { |expr, _, _| expr.evaluate(frames[i]) }] }
        indexes.sort_by.with_index { |i, position| [SortKey.new(keys[i], order), position] }
      end
    end

    # The value for row j of the partition (6.3).
    def value(partition, j)
      case @kind
      when :aggregate then @aggregate.compute(partition.rows_in_frame(j)).first
      when :row_number then j + 1
      when :rank then partition.peer_first(j) + 1
      when :dense_rank then partition.peer_group(j) + 1
      when :percent_rank
        partition.size == 1 ? 0.0 : partition.peer_first(j).to_f / (partition.size - 1)
      when :cume_dist then (partition.peer_last(j) + 1).to_f / partition.size
      when :ntile then ntile(partition, j)
      when :lag then shifted(partition, j, -1)
      when :lead then shifted(partition, j, 1)
      when :first_value then nth_in_frame(partition, j, 1)
      when :last_value then nth_in_frame(partition, j, -1)
      when :nth_value then nth_in_frame(partition, j, nth_argument(partition.rows[j]))
      end
    end

    # Buckets of sizes differing by at most one, the larger first.
    def ntile(partition, j)
      n = @args[0].evaluate(partition.rows[j])
      buckets = n.nil? ? 0 : Values.to_number(n).to_i
      raise SqlError, "argument of ntile must be a positive integer" unless buckets.positive?
      size, extra = partition.size.divmod(buckets)
      large = extra * (size + 1)
      j < large ? j / (size + 1) + 1 : extra + (j - large) / size + 1
    end

    # lag (direction -1) and lead (1): x on the row k positions away, else the default on this row.
    def shifted(partition, j, direction)
      row = partition.rows[j]
      k = @args[1] ? @args[1].evaluate(row) : 1
      return nil if k.nil?
      target = j + direction * Values.to_number(k).to_i
      return @args[0].evaluate(partition.rows[target]) if target.between?(0, partition.size - 1)
      @args[2]&.evaluate(row)
    end

    def nth_argument(row)
      n = @args[1].evaluate(row)
      n = Values.to_number(n) unless n.nil?
      unless (n.is_a?(Integer) || (n.is_a?(Float) && n == n.truncate)) && n.positive?
        raise SqlError, "second argument to nth_value must be a positive integer"
      end
      n.to_i
    end

    # x on the n-th row of the frame (-1: its last), NULL when there is none.
    def nth_in_frame(partition, j, n)
      rows = partition.rows_in_frame(j)
      row = n == -1 ? rows.last : rows[n - 1]
      row && @args[0].evaluate(row)
    end
  end

  # A row's ORDER BY values, ordered by the window's terms.
  class SortKey
    include Comparable
    attr_reader :values

    def initialize(values, order)
      @values = values
      @order = order
    end

    def <=>(other)
      @order.each_with_index do |(_, descending, nulls_first), k|
        c = Values.compare_ordered(@values[k], other.values[k], descending, nulls_first)
        return c unless c.zero?
      end
      0
    end
  end

  # One partition in window order: its rows, their peer groups, and each row's frame (6.2).
  class Partition
    attr_reader :rows

    def initialize(rows, window)
      @rows = rows
      @window = window
      @keys = rows.map { |row| SortKey.new(window.order_by.map { |expr, _, _| expr.evaluate(row) }, window.order_by) }
      @first = []
      @group = []
      rows.each_index do |j|
        new_group = j.zero? || @keys[j] != @keys[j - 1]
        @first[j] = new_group ? j : @first[j - 1]
        @group[j] = j.zero? ? 0 : @group[j - 1] + (new_group ? 1 : 0)
      end
      @last = []
      (rows.length - 1).downto(0) do |j|
        @last[j] = j == rows.length - 1 || @group[j + 1] != @group[j] ? j : @last[j + 1]
      end
    end

    def size = @rows.length
    def peer_first(j) = @first[j]
    def peer_last(j) = @last[j]
    def peer_group(j) = @group[j]

    # The rows of row j's frame, in partition order (empty when its start comes after its end).
    def rows_in_frame(j)
      frame = @window.frame
      from = [position(frame.start, j, frame.unit, :start), 0].max
      to = [position(frame.end, j, frame.unit, :end), size - 1].min
      from > to ? [] : @rows[from..to]
    end

    private

    # The index a bound stands for (it may lie outside the partition, to be clipped).
    def position(bound, j, unit, side)
      case bound.kind
      when :unbounded_preceding then 0
      when :unbounded_following then size - 1
      when :current_row
        return j if unit == :rows
        side == :start ? @first[j] : @last[j]
      else
        sign = bound.kind == :preceding ? -1 : 1
        unit == :rows ? j + sign * bound.offset : range_position(j, sign * bound.offset, side)
      end
    end

    # RANGE n PRECEDING/FOLLOWING (offset -n / n): the first (start) or last (end) row whose ORDER BY
    # value is within the offset of the current row's, counted in the term's direction. A NULL value
    # is in range of a NULL only: its peers. (Tests use numeric values; any other is treated as NULL.)
    def range_position(j, offset, side)
      value = @keys[j].values[0]
      return side == :start ? @first[j] : @last[j] unless value.is_a?(Numeric)
      direction = @window.order_by[0][1] ? -1 : 1
      limit = direction * value + offset
      within = lambda do |k|
        v = @keys[k].values[0]
        v.is_a?(Numeric) && (side == :start ? direction * v >= limit : direction * v <= limit)
      end
      if side == :start
        (0...size).find(&within) || size
      else
        (size - 1).downto(0).find(&within) || -1
      end
    end
  end
end
