# frozen_string_literal: true

require_relative "ast"
require_relative "errors"
require_relative "evaluator"
require_relative "values"

module Sql
  # Sorting by ORDER BY terms (1.7, 1.9).
  module Ordering
    # Where a term takes its value: a result column (result_index), or an expression (bound) on a row.
    # collation: the Collation name the term's TEXT values compare under.
    SortKey = Data.define(:result_index, :expr, :desc, :nulls, :collation) do
      def initialize(result_index:, expr:, desc:, nulls:, collation: :binary) = super
    end

    module_function

    # Stable sort of `items`; the block gives the value of a key for an item.
    def sort(items, keys)
      decorated = items.each_with_index.map do |item, n|
        [item, keys.map { |k| yield(item, k) }, n]
      end
      decorated.sort do |a, b|
        c = compare_keys(a[1], b[1], keys)
        c == 0 ? a[2] <=> b[2] : c
      end.map(&:first)
    end

    # Sorts source rows by keys that are all expressions.
    def sort_rows(rows, keys)
      sort(rows, keys) { |row, k| Evaluator.evaluate(k.expr, row) }
    end

    # A term `x COLLATE name` (unbound) -> [x, name as written]; any other term -> [term, nil].
    def split_collate(expr)
      expr.is_a?(Collate) ? [expr.expr, expr.name] : [expr, nil]
    end

    # `k` or `-k` (an integer literal) names the k-th result column (0-based result here).
    def ordinal(expr, position, count, clause)
      return nil unless expr.is_a?(Literal) && expr.value.is_a?(Integer)
      k = expr.value
      return k - 1 if k.between?(1, count)
      raise SqlError, "#{ordinal_word(position + 1)} #{clause} term out of range - should be between 1 and #{count}"
    end

    def ordinal_word(n)
      suffix = if (11..13).cover?(n % 100) then "th"
               else { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(n % 10, "th")
               end
      "#{n}#{suffix}"
    end

    def compare_keys(a, b, keys)
      keys.each_index do |i|
        c = compare_term(a[i], b[i], keys[i])
        return c unless c == 0
      end
      0
    end

    def compare_term(x, y, key)
      if (x.nil? || y.nil?) && key.nulls
        return 0 if x.nil? && y.nil?
        nulls_first = key.nulls == :first
        return x.nil? == nulls_first ? -1 : 1
      end
      c = Values.compare(x, y, key.collation)
      key.desc ? -c : c
    end
  end
end
