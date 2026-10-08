# frozen_string_literal: true

require_relative "ast"
require_relative "value"

module Sql
  # Sorting by ORDER BY terms (and by group keys) in the order of values.
  module Ordering
    # items sorted by the parallel keys (one array of term values per item); ties keep input order.
    def self.sort(items, keys, terms)
      order = (0...items.length).to_a.sort do |a, b|
        c = compare_keys(keys.fetch(a), keys.fetch(b), terms)
        c == 0 ? a <=> b : c
      end
      order.map { |i| items.fetch(i) }
    end

    def self.compare_keys(left, right, terms)
      terms.each_with_index do |term, i|
        c = compare_term(left.fetch(i), right.fetch(i), term)
        return c unless c == 0
      end
      0
    end

    def self.compare_term(a, b, term)
      return 0 if a.nil? && b.nil?

      if a.nil? || b.nil?
        nulls_first = term.nulls_first.nil? ? !term.descending : term.nulls_first
        return a.nil? == nulls_first ? -1 : 1
      end
      c = Value.compare(a, b)
      term.descending ? -c : c
    end

    # Ascending, NULLs first, element by element.
    def self.compare_lists(left, right)
      left.each_with_index do |a, i|
        c = Value.compare(a, right.fetch(i))
        return c unless c == 0
      end
      0
    end
  end
end
