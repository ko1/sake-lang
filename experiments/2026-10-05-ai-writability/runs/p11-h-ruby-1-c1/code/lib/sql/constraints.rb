# frozen_string_literal: true

require_relative "values"

module Sql
  # A UNIQUE or PRIMARY KEY constraint over one or more columns (2.1), with a hash index of the
  # rows that have no NULL in those columns. Rows are indexed by identity: a row is an Array that
  # an UPDATE changes in place.
  class UniqueConstraint
    attr_reader :columns # positions in the row

    # collations: the collation each column's values are compared under (7.4), one per column.
    def initialize(columns, primary_key, collations)
      @columns = columns
      @primary_key = primary_key
      @collations = collations
      @index = {}
    end

    def primary_key?
      @primary_key
    end

    # The row holding the same values as `values`, or nil (also nil when a value is NULL).
    def conflicting_row(values)
      key = key_for(values)
      key && @index[key]
    end

    def add(row)
      key = key_for(row)
      @index[key] = row if key
    end

    def remove(row)
      key = key_for(row)
      @index.delete(key) if key && @index[key].equal?(row)
    end

    private

    # Values of one column all have the column's type, so eql? agrees with the order of values
    # except for -0.0, which is folded into 0.0, and text, which is keyed under the collation.
    def key_for(values)
      key = @columns.map { |i| values[i] }
      return nil if key.any?(&:nil?)
      key.each_with_index.map do |v, n|
        case v
        when Float then v + 0.0
        when String then Values.text_key(v, @collations[n])
        else v
        end
      end
    end
  end
end
