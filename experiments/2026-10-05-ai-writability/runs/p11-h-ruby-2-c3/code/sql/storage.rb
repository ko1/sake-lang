# frozen_string_literal: true

require_relative 'errors'
require_relative 'values'

module SQL
  # Returned by Column#convert for a value the column cannot hold.
  REJECTED = Object.new.freeze

  # The reserved names of the rowid (SPEC 7.1): a hidden INTEGER column of every table, kept as the
  # last element of each stored row (after the real columns).
  module Rowid
    NAMES = %w[rowid _rowid_ oid].freeze

    def self.name?(name) = NAMES.include?(name.downcase)
  end

  # A column keeps the spelling of its CREATE TABLE; `type` is :integer, :real or :text.
  # `not_null` includes the implicit NOT NULL of a PRIMARY KEY; `default` is a Ruby value.
  Column = Struct.new(:name, :type, :not_null, :default) do
    def type_name = type.to_s.upcase

    # The value converted for this column (SPEC 1.5), or REJECTED.
    def convert(value)
      return nil if value.nil?

      value = Values.parse_numeric_literal(value) || value if value.is_a?(String) && type != :text
      case type
      when :integer then to_integer(value)
      when :real then value.is_a?(String) ? REJECTED : value.to_f
      else value.is_a?(String) ? value : Values.text_form(value)
      end
    end

    # Like `convert`, but raises the storage error.
    def coerce(value, table_name)
      stored = convert(value)
      return stored unless stored.equal?(REJECTED)

      parsed = value.is_a?(String) ? Values.parse_numeric_literal(value) || value : value
      raise SqlError, "cannot store #{Values.type_name(parsed).upcase} value in #{type_name} " \
                      "column #{table_name}.#{name}"
    end

    private

    def to_integer(value)
      case value
      when Integer then value
      when Float then value == value.floor && value >= Values::INT_MIN && value < 2**63 ? value.to_i : REJECTED
      else REJECTED
      end
    end
  end

  # Converts a rowid value as an INTEGER column does (7.3).
  ROWID_COLUMN = Column.new('rowid', :integer, false, nil)

  # A UNIQUE constraint (or a PRIMARY KEY that is not the row key) over column indexes.
  UniqueKey = Struct.new(:columns) do
    # Does `values` collide with a row of `rows` other than the one at index `skip`?
    def conflict?(values, rows, skip)
      key = values.values_at(*columns)
      return false if key.any?(&:nil?)

      rows.each_with_index.any? { |row, i| i != skip && row.values_at(*columns) == key }
    end
  end

  # A named index of a table (5.7); `unique_key` is the UniqueKey it adds to the table, or nil.
  Index = Struct.new(:name, :columns, :unique_key)

  # A table: columns in declaration order, rows (arrays of values) in insertion order. A row holds
  # one value per column followed by its rowid (SPEC 7); with an INTEGER PRIMARY KEY the two are equal.
  # Every change goes through `insert_rows`, `update_rows` or `delete_rows`; each is all-or-nothing.
  class Table
    attr_reader :name, :columns, :rows, :indexes

    # Build from a CreateTable statement (SPEC 1.4, 2.1). Declaration order of the unique
    # constraints: column constraints in column order, then the table constraints.
    def self.define(stmt)
      columns = stmt.columns.map { |c| column_for(c) }
      table = new(stmt.name, columns)
      groups = []
      stmt.columns.each_with_index do |c, i|
        groups << [:primary_key, [i]] if c.primary_key
        groups << [:unique, [i]] if c.unique
      end
      stmt.constraints.each do |tc|
        groups << [tc.kind, tc.columns.map { |n| table.column_index(n) or raise SqlError, "no such column: #{n}" }]
      end
      groups.each { |kind, cols| table.add_constraint(kind, cols) }
      table
    end

    def self.column_for(def_) = Column.new(def_.name, def_.type, def_.not_null, def_.default)

    def initialize(name, columns)
      @name = name
      @columns = columns
      @rows = []
      @key_index = nil # the INTEGER PRIMARY KEY column, which is the rowid under another name
      @uniques = []
      @indexes = []
    end

    # A copy that later changes to this table do not touch (for ROLLBACK, 5.5). Rows and unique
    # keys are never changed in place, so they are shared.
    def initialize_copy(source)
      super
      @columns = source.columns.map(&:dup)
      @rows = source.rows.dup
      @uniques = @uniques.dup
      @indexes = @indexes.dup
    end

    def rename_to(new_name) = @name = new_name

    def rename_column(index, new_name) = @columns[index].name = new_name

    # Append a column (5.6); existing rows get its DEFAULT converted as on insert.
    def add_column(column)
      fill = column.coerce(column.default, @name)
      @rows = @rows.map { |row| row[0...-1] + [fill, row.last] } # the rowid stays last
      @columns << column
    end

    # CREATE INDEX (5.7). A unique index is a uniqueness constraint checked before the older ones;
    # rows that already conflict make it fail and leave the table as it was.
    def add_index(name, cols, unique)
      key = UniqueKey.new(cols) if unique
      @rows.each_with_index { |row, i| check_unique(key, row, @rows, i) } if unique
      @uniques << key if unique
      @indexes << Index.new(name, cols, key)
    end

    def find_index(name) = @indexes.find { |ix| ix.name.casecmp?(name) }

    def drop_index(index)
      @uniques.delete_if { |u| u.equal?(index.unique_key) }
      @indexes.delete(index)
    end

    def column_index(name)
      key = name.downcase
      @columns.index { |c| c.name.downcase == key }
    end

    # Index within a row of what a statement means by `name` when storing: the real column of that
    # name, else (for a rowid name) the rowid, which is the INTEGER PRIMARY KEY column if there is one.
    def target_index(name)
      column_index(name) || (Rowid.name?(name) ? @key_index || @columns.size : nil)
    end

    def add_constraint(kind, cols)
      if kind == :primary_key
        cols.each { |i| @columns[i].not_null = true }
        if cols.size == 1 && @columns[cols.first].type == :integer
          @key_index = cols.first
          return
        end
      end
      @uniques << UniqueKey.new(cols)
    end

    # Insert rows given as values for the columns `targets`; the other columns get their DEFAULT.
    def insert_rows(targets, value_rows)
      working = @rows.dup
      top = working.map(&:last).max # largest rowid present; each new row sees the rows before it
      value_rows.each do |given|
        values = @columns.each_with_index.map { |c, i| i == @key_index ? nil : c.default } << nil
        targets.each_with_index { |col, n| values[col] = given[n] }
        row = check_row(values, working, nil, (top || 0) + 1)
        top = row.last if top.nil? || row.last > top
        working << row
      end
      @rows = working
    end

    # Replace each row for which `selected.call(row)` is true by the row with `changes.call(row)`
    # (a list of [column index, value]) applied.
    def update_rows(selected, changes)
      working = @rows.dup
      working.each_index do |i|
        old = working[i]
        next unless selected.call(old)

        values = old.dup
        changes.call(old).each { |col, v| values[col] = v }
        working[i] = check_row(values, working, i, nil)
      end
      @rows = working
    end

    def delete_rows(selected) = @rows = @rows.reject { |row| selected.call(row) }

    private

    # The checks of SPEC 2.1 and 7.3 in their order; returns the row as stored. `skip` is the index
    # of the row being replaced (UPDATE); `next_rowid` is the rowid an INSERT gives to a NULL one.
    def check_row(values, rows, skip, next_rowid)
      values = values.dup
      store_rowid(values, next_rowid)
      @columns.each_with_index do |c, i|
        raise SqlError, "NOT NULL constraint failed: #{@name}.#{c.name}" if c.not_null && values[i].nil?
      end
      check_rowid_unique(values, rows, skip)
      @columns.each_with_index { |c, i| values[i] = c.coerce(values[i], @name) unless i == @key_index }
      @uniques.reverse_each { |u| check_unique(u, values, rows, skip) }
      values
    end

    # Converts the rowid (the INTEGER PRIMARY KEY column if any) and stores it in both its places.
    def store_rowid(values, next_rowid)
      pos = @key_index || @columns.size
      v = values[pos]
      if v.nil?
        raise SqlError, 'datatype mismatch' unless next_rowid

        stored = next_rowid
      else
        stored = ROWID_COLUMN.convert(v)
        raise SqlError, 'datatype mismatch' if stored.equal?(REJECTED)
      end
      values[pos] = values[@columns.size] = stored
    end

    def check_rowid_unique(values, rows, skip)
      slot = @columns.size
      return unless rows.each_with_index.any? { |row, i| i != skip && row[slot] == values[slot] }

      raise SqlError, "UNIQUE constraint failed: #{@name}.#{@key_index ? @columns[@key_index].name : 'rowid'}"
    end

    def check_unique(unique, values, rows, skip)
      return unless unique.conflict?(values, rows, skip)

      names = unique.columns.map { |i| "#{@name}.#{@columns[i].name}" }
      raise SqlError, "UNIQUE constraint failed: #{names.join(', ')}"
    end
  end
end
