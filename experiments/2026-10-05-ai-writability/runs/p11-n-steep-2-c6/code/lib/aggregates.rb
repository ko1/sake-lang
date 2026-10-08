module MiniSql
  # A bound aggregate call. name is lower case; star is `count(*)` (or `count()`); order_by
  # orders the rows of the group before the values are taken (group_concat).
  class AggregateSpec
    attr_reader :name, :args, :star, :distinct, :order_by

    def initialize(name, args, star, distinct, order_by)
      @name = name
      @args = args
      @star = star
      @distinct = distinct
      @order_by = order_by
    end
  end

  # The aggregate functions (SPEC 3.2).
  module Aggregates
    # name => accepted numbers of arguments (`count(*)` has none).
    ARITY = {
      "count" => (0..1), "sum" => (1..1), "total" => (1..1), "avg" => (1..1),
      "min" => (1..1), "max" => (1..1), "group_concat" => (1..2)
    }.freeze

    # Whether a call of this name (any case) with this many arguments is an aggregate; min and max with
    # two or more arguments are the scalar functions.
    def self.aggregate?(name, count)
      lower = name.downcase(:ascii)
      return false unless ARITY.key?(lower)
      !((lower == "min" || lower == "max") && count >= 2)
    end

    # Whether the aggregate `lower` (lower case) accepts this many arguments.
    def self.arity_ok?(lower, count)
      range = ARITY[lower]
      range ? range.cover?(count) : false
    end

    # The value of the aggregate over the rows of one group.
    def self.compute(spec, rows)
      ordered = spec.order_by.empty? ? rows : sort_rows(rows, spec.order_by)
      case spec.name
      when "count" then spec.star ? rows.length : present_values(spec, ordered).length
      when "min", "max" then extreme_value(spec, rows)
      when "group_concat" then group_concat(spec, ordered)
      else numeric(spec.name, present_values(spec, ordered))
      end
    end

    # The row of the group giving the minimum / maximum of a min/max aggregate (the first of equals);
    # nil for other aggregates and when every value is NULL.
    def self.extreme_row(spec, rows)
      return nil unless spec.name == "min" || spec.name == "max"
      direction = spec.name == "max" ? 1 : -1
      argument = spec.args.fetch(0)
      best_row = nil # @type var best_row: Array[sql_value]?
      best = nil # @type var best: sql_value
      rows.each do |row|
        value = Evaluator.evaluate(argument, row)
        next if value.nil?
        next unless best_row.nil? || Value.compare(value, best) * direction > 0
        best = value
        best_row = row
      end
      best_row
    end

    def self.extreme_value(spec, rows)
      row = extreme_row(spec, rows)
      row ? Evaluator.evaluate(spec.args.fetch(0), row) : nil
    end

    # The rows ordered by the terms of an ORDER BY inside the call; equal rows keep their order.
    def self.sort_rows(rows, keys)
      candidates = rows.each_with_index.map do |row, serial|
        Candidate.new(row, keys.map { |key| key.value([], row) }, serial)
      end
      candidates.sort { |a, b| SortKey.compare_candidates(keys, a, b) }.map(&:values)
    end

    # The non-NULL values of the first argument, each distinct value once under DISTINCT.
    def self.present_values(spec, rows)
      argument = spec.args.fetch(0)
      seen = {} # @type var seen: Hash[sql_value, bool]
      values = [] # @type var values: Array[sql_value]
      rows.each do |row|
        value = Evaluator.evaluate(argument, row)
        next if value.nil?
        if spec.distinct
          key = Value.group_key(value)
          next if seen.key?(key)
          seen[key] = true
        end
        values << value
      end
      values
    end

    # sum, total and avg over non-NULL values.
    def self.numeric(name, values)
      case name
      when "sum" then values.empty? ? nil : integer_sum(values) || real_sum(values)
      when "total" then values.empty? ? 0.0 : real_sum(values)
      else values.empty? ? nil : real_sum(values) / values.length
      end
    end

    # The INTEGER a value counts as in a sum: an INTEGER, or TEXT that is an integer literal; else nil.
    def self.integer_of(value)
      value = Value.parse_number(value) if value.is_a?(String)
      value.is_a?(Integer) ? value : nil
    end

    # The exact sum if every value is an INTEGER, else nil.
    def self.integer_sum(values)
      total = 0
      values.each do |value|
        integer = integer_of(value)
        return nil unless integer
        total += integer
      end
      raise SqlError, "integer overflow" if total < Value::INT64_MIN || total > Value::INT64_MAX
      total
    end

    # The sum as a REAL: the exact sum of the leading INTEGERs, then compensated addition of the rest.
    def self.real_sum(values)
      sum = 0.0
      compensation = 0.0
      exact = 0
      reached_real = false
      values.each do |value|
        integer = integer_of(value)
        if integer && !reached_real
          exact += integer
          next
        end
        unless reached_real
          reached_real = true
          sum = exact.to_f
        end
        term = Value.to_number(value).to_f
        total = sum + term
        compensation += sum.abs > term.abs ? (sum - total) + term : (term - total) + sum
        sum = total
      end
      reached_real ? sum + compensation : exact.to_f
    end

    # group_concat(x[, separator]): the separator is read on the row that follows the joined text.
    def self.group_concat(spec, rows)
      value_expr = spec.args.fetch(0)
      separator = spec.args[1]
      seen = {} # @type var seen: Hash[sql_value, bool]
      parts = [] # @type var parts: Array[String]
      rows.each do |row|
        value = Evaluator.evaluate(value_expr, row)
        next if value.nil?
        if spec.distinct
          key = Value.group_key(value)
          next if seen.key?(key)
          seen[key] = true
        end
        unless parts.empty?
          parts << (separator ? Value.text_form(Evaluator.evaluate(separator, row)) : ",")
        end
        parts << Value.text_form(value)
      end
      parts.empty? ? nil : parts.join
    end
  end
end
