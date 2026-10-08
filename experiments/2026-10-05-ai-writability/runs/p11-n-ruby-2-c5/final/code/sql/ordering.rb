# frozen_string_literal: true

require_relative 'values'

module SQL
  # Sorting by ORDER BY terms (SPEC 1.7), shared by SELECT and by group_concat(... ORDER BY ...).
  module Ordering
    # One term: `index` picks a result column of the output row, else `fn` is evaluated on the row.
    Term = Struct.new(:desc, :nulls, :index, :fn) do
      def key(row, out) = index ? out[index] : fn.call(row)
    end

    module_function

    # Stable sort of [keys, payload] pairs (keys = one value per term).
    def sort(items, terms)
      items.each_with_index.sort do |(a, i), (b, j)|
        c = compare_keys(terms, a[0], b[0])
        c.zero? ? i <=> j : c
      end.map(&:first)
    end

    def compare_keys(terms, ka, kb)
      terms.each_with_index do |t, i|
        c = compare_key(t, ka[i], kb[i])
        return c unless c.zero?
      end
      0
    end

    def compare_key(term, x, y)
      return (x.nil? == (term.nulls == :first) ? -1 : 1) if term.nulls && (x.nil? ^ y.nil?)

      c = Values.order_compare(x, y)
      term.desc ? -c : c
    end
  end
end
