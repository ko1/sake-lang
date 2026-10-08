require_relative "errors"
require_relative "values"

# The aggregate functions (spec 3.2) and the aggregate calls of one query.
module Aggregates
  # kind: :count_star, :count, :sum, :total, :avg, :min, :max or :group_concat; arity: the argument
  # counts that make a call of this name an aggregate.
  Definition = Struct.new(:kind, :arity)

  TABLE = {
    "count" => Definition.new(:count, 0..1),
    "sum" => Definition.new(:sum, 1..1),
    "total" => Definition.new(:total, 1..1),
    "avg" => Definition.new(:avg, 1..1),
    "min" => Definition.new(:min, 1..1),
    "max" => Definition.new(:max, 1..1),
    "group_concat" => Definition.new(:group_concat, 1..2)
  }.freeze
  COUNT_STAR = Definition.new(:count_star, 0..0)
  # Names that are also scalar functions with other argument counts (spec 2.4).
  SCALAR_OVERLOADS = %w[min max].freeze

  module_function

  # The definition when `call` (AST::Call) is an aggregate call, nil when it is a scalar one. Raises
  # SqlError for an aggregate name with a wrong argument count, and for DISTINCT with other than one
  # argument. `count()` is `count(*)`, as in SQLite (the spec only shows `count(*)`).
  def lookup(call)
    key = call.name.downcase
    definition = TABLE[key]
    return nil unless definition
    count = call.args.length
    return nil if SCALAR_OVERLOADS.include?(key) && count != 1 && !call.star
    if call.star || (definition.kind == :count && count.zero?)
      raise SqlError, "wrong number of arguments to function #{call.name}()" unless definition.kind == :count
      definition = COUNT_STAR
    end
    raise SqlError, "wrong number of arguments to function #{call.name}()" unless definition.arity.include?(count)
    raise SqlError, "DISTINCT aggregates must have exactly one argument" if call.distinct && count != 1
    definition
  end

  # One aggregate call, bound: args are bound expressions; order_by: [[bound expression, descending,
  # nulls_first, collation]]. `compute` gives its value over a group's rows (Expressions::Frame), and
  # the row that gave a min or max. DISTINCT, min and max compare under the first argument's
  # collation (7.4).
  Call = Struct.new(:definition, :args, :distinct, :order_by) do
    def compute(frames)
      return [frames.length, nil] if definition.kind == :count_star
      collation = Collation.name_of(args[0])
      entries = frames.filter_map do |frame|
        values = args.map { |arg| arg.evaluate(frame) }
        [frame, values] unless values[0].nil?
      end
      entries = entries.uniq { |_, values| Values.equality_key(values[0], collation) } if distinct
      entries = Aggregates.sort_entries(entries, order_by) unless order_by.empty?
      Aggregates.finish(definition.kind, entries, collation)
    end
  end

  # Entries in the order of an aggregate's ORDER BY; equal ones keep row order.
  def sort_entries(entries, order_by)
    keyed = entries.each_with_index.map do |entry, i|
      [order_by.map { |expr, _, _| expr.evaluate(entry[0]) }, i, entry]
    end
    keyed.sort! do |(a, i), (b, j)|
      c = order_by.each_with_index.reduce(0) do |found, ((_, descending, nulls_first, collation), k)|
        found.zero? ? Values.compare_ordered(a[k], b[k], descending, nulls_first, collation) : found
      end
      c.zero? ? i <=> j : c
    end
    keyed.map(&:last)
  end

  # [value, row that gave it (min and max only)] for entries [row, argument values] whose first
  # argument is not NULL; min and max compare under the collation.
  def finish(kind, entries, collation)
    xs = entries.map { |_, values| values[0] }
    case kind
    when :count then [xs.length, nil]
    when :sum then [xs.empty? ? nil : sum(xs), nil]
    when :total then [xs.empty? ? 0.0 : real_sum(xs), nil]
    when :avg then [xs.empty? ? nil : real_sum(xs) / xs.length, nil]
    when :min then extreme(entries, -1, collation)
    when :max then extreme(entries, 1, collation)
    when :group_concat then [group_concat(entries), nil]
    end
  end

  # The smallest (sign -1) or largest (sign 1) value in the order of values; the first of equal ones.
  def extreme(entries, sign, collation)
    best = nil
    entries.each do |entry|
      best = entry if best.nil? || Values.compare(entry[1][0], best[1][0], collation) * sign > 0
    end
    best ? [best[1][0], best[0]] : [nil, nil]
  end

  # Each value after the first is preceded by its own row's separator (default ',', NULL: nothing).
  def group_concat(entries)
    return nil if entries.empty?
    entries.each_with_index.map do |(_, (x, *sep)), i|
      separator = i.zero? ? "" : (sep.empty? ? "," : (sep[0].nil? ? "" : Values.to_text(sep[0])))
      separator + Values.to_text(x)
    end.join
  end

  # A value as `sum` adds it: numeric text is its number; other text is a REAL by numeric prefix.
  def addend(value)
    return value unless value.is_a?(String)
    Values.parse_number(value) || Values.to_number(value).to_f
  end

  # sum(x): the exact INTEGER sum while every value is an INTEGER, else the compensated REAL sum.
  def sum(xs)
    integer, rest, overflow = integer_prefix_sum(xs.map { |x| addend(x) })
    raise SqlError, "integer overflow" if overflow
    rest.empty? ? integer : compensated(integer.to_f, rest)
  end

  # The REAL sum that total and avg use.
  def real_sum(xs)
    integer, rest, = integer_prefix_sum(xs.map { |x| addend(x) })
    compensated(integer.to_f, rest)
  end

  # [the INTEGER sum of the values before the first non-INTEGER one, the values from there on, whether
  # that INTEGER sum left 64 bits on the way].
  def integer_prefix_sum(numbers)
    split = numbers.index { |v| !v.is_a?(Integer) } || numbers.length
    sum = 0
    overflow = false
    numbers[0...split].each do |v|
      sum += v
      overflow ||= !sum.between?(Values::INT_MIN, Values::INT_MAX)
    end
    [sum, numbers[split..], overflow]
  end

  # Kahan-Babuska summation of `rest` onto s (spec 3.2).
  def compensated(s, rest)
    c = 0.0
    rest.each do |v|
      v = v.to_f
      t = s + v
      c += s.abs > v.abs ? (s - t) + v : (v - t) + s
      s = t
    end
    s + c
  end

  # The aggregate calls of one query, each once: a call written again (in another clause, or through an
  # alias) is the same call, as in SQLite. Their values follow the row's columns: call k is at
  # offset + k of the row an aggregate query evaluates its expressions on.
  class Collector
    def initialize(offset)
      @offset = offset
      @calls = []
      @indexes = {} # normalized call => index
    end

    def empty? = @calls.empty?

    # The slot of the call, adding it unless the same call is already there.
    def add(key, call)
      index = @indexes[key] ||= (@calls << call).length - 1
      @offset + index
    end

    # [the values of every call over `frames`, the frame bare columns take their values from (nil:
    # any)]. That is the one that gave the min or max (spec 3.3: when that is the only call). With
    # several calls the spec allows any row; this takes the last min or max call's row, as SQLite does.
    def compute(frames)
      results = @calls.map { |call| call.compute(frames) }
      extreme = @calls.rindex { |call| %i[min max].include?(call.definition.kind) }
      [results.map(&:first), extreme && results[extreme][1]]
    end
  end
end
