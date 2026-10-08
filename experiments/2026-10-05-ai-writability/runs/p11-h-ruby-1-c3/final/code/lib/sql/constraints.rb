# frozen_string_literal: true

module Sql
  # A UNIQUE or PRIMARY KEY constraint over one or more columns (2.1), with a hash index of the
  # rows that have no NULL in those columns. Rows are indexed by identity: a row is an Array that
  # an UPDATE changes in place.
  class UniqueConstraint
    attr_reader :columns # positions in the row

    def initialize(columns, primary_key)
      @columns = columns
      @primary_key = primary_key
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
    # except for -0.0, which is folded into 0.0.
    def key_for(values)
      key = @columns.map { |i| values[i] }
      return nil if key.any?(&:nil?)
      key.map { |v| v.is_a?(Float) ? v + 0.0 : v }
    end
  end

  # Uniqueness of the rowid of a table without an INTEGER PRIMARY KEY (7.3). The rowid is the last
  # value of a stored row (see Table). Same interface as UniqueConstraint, as far as Table uses it.
  class RowidIndex
    def initialize
      @index = {}
    end

    # The row with the same rowid as `values`, or nil.
    def conflicting_row(values)
      @index[values.last]
    end

    def add(row)
      @index[row.last] = row
    end

    def remove(row)
      @index.delete(row.last) if @index[row.last].equal?(row)
    end
  end
end
