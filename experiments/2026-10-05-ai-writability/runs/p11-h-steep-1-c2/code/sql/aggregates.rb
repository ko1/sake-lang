# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "evaluator"
require_relative "functions"
require_relative "ordering"
require_relative "value"

module Sql
  # Aggregate functions (spec 3.2): which calls are aggregates, and their value over a group.
  module Aggregates
    NAMES = %w[count sum total avg min max group_concat].freeze

    # Whether a call of this (lower-case) name with argc arguments is an aggregate; min and max
    # with two or more arguments are the scalar functions.
    def self.aggregate?(function, argc)
      NAMES.include?(function) && !((function == "min" || function == "max") && argc >= 2)
    end

    def self.accepts?(function, argc, star)
      return function == "count" && argc == 0 if star

      function == "group_concat" ? (argc == 1 || argc == 2) : argc == 1
    end

    # The value of call over the rows of one group (rows may be empty).
    def self.compute(call, rows)
      ordered = ordered_rows(call, rows)
      return ordered.length if call.star

      return group_concat(call, ordered) if call.function == "group_concat"

      values = distinct_values(call, argument_values(call.args.fetch(0), ordered))
      fold(call.function, values)
    end

    # Whether the bare columns of a query take the row that gave this call's value (spec 3.3).
    def self.picks_row?(call)
      (call.function == "min" || call.function == "max") && call.args.length == 1
    end

    # The row of the group that gave the call's minimum or maximum (the first row if all are NULL).
    def self.extreme_row(call, rows)
      direction = call.function == "max" ? 1 : -1
      best_row = rows.fetch(0)
      best = nil #: value
      rows.each do |row|
        value = Evaluator.evaluate(call.args.fetch(0), row)
        next if value.nil?

        if best.nil? || Value.compare(value, best) == direction
          best = value
          best_row = row
        end
      end
      best_row
    end

    def self.ordered_rows(call, rows)
      terms = call.order_by
      return rows if terms.empty?

      keys = rows.map { |row| terms.map { |term| Evaluator.evaluate(term.expr, row) } }
      Ordering.sort(rows, keys, terms)
    end

    # The non-NULL values of an argument over the rows.
    def self.argument_values(arg, rows)
      values = [] #: Array[present]
      rows.each do |row|
        value = Evaluator.evaluate(arg, row)
        values << value unless value.nil?
      end
      values
    end

    # Each distinct value once (the first) when the call says DISTINCT.
    def self.distinct_values(call, values)
      return values unless call.distinct

      seen = {} #: Hash[value, bool]
      values.select { |value| seen.key?(Value.identity(value)) ? false : (seen[Value.identity(value)] = true) }
    end

    def self.fold(function, values)
      case function
      when "count" then values.length
      when "sum" then values.empty? ? nil : sum(values)
      when "total" then real_sum(values)
      when "avg" then values.empty? ? nil : real_sum(values) / values.length
      when "min" then values.empty? ? nil : Functions.extreme(values, -1)
      else values.empty? ? nil : Functions.extreme(values, 1)
      end
    end

    # group_concat(x [, sep]): the separator before a value is the one of that value's row.
    def self.group_concat(call, rows)
      separator = call.args[1]
      seen = {} #: Hash[value, bool]
      out = nil #: String?
      rows.each do |row|
        value = Evaluator.evaluate(call.args.fetch(0), row)
        next if value.nil?
        next if call.distinct && seen.key?(Value.identity(value))

        seen[Value.identity(value)] = true
        sep = separator ? Evaluator.evaluate(separator, row) : ","
        joiner = sep.nil? ? "" : Value.text_form(sep)
        text = Value.text_form(value)
        out = out.nil? ? text : "#{out}#{joiner}#{text}"
      end
      out
    end

    # The INTEGER a value counts as in a sum (an INTEGER, or TEXT that is an integer literal; never a BLOB), else nil.
    def self.integer_value(value)
      case value
      when Integer then value
      when String
        number = Value.parse_numeric_text(value)
        number.is_a?(Integer) ? number : nil
      end
    end

    # sum(): exact when every value is an INTEGER, else the compensated REAL sum.
    def self.sum(values)
      integers = values.map { |value| integer_value(value) }.compact
      return real_sum(values) unless integers.length == values.length

      total = integers.sum
      raise Error, "integer overflow" if total < Value::INT_MIN || total > Value::INT_MAX

      total
    end

    # The REAL sum of spec 3.2: exact INTEGER prefix, then Kahan-Babuska compensation.
    def self.real_sum(values)
      prefix = 0
      taken = 0
      values.each do |value|
        integer = integer_value(value)
        break unless integer

        prefix += integer
        taken += 1
      end
      s = prefix.to_f
      c = 0.0
      values.drop(taken).each do |value|
        v = Value.to_number(value).to_f
        t = s + v
        c += s.abs > v.abs ? (s - t) + v : (v - t) + s
        s = t
      end
      s + c
    end
  end
end
