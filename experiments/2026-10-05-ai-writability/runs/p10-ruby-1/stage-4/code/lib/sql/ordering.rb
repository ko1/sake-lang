# frozen_string_literal: true

require_relative "evaluator"
require_relative "values"

module Sql
  # Sorting by ORDER BY terms (1.7, 1.9).
  module Ordering
    # Where a term takes its value: a result column (result_index), or an expression (bound) on a row.
    SortKey = Data.define(:result_index, :expr, :desc, :nulls)

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
      c = Values.compare(x, y)
      key.desc ? -c : c
    end
  end
end
