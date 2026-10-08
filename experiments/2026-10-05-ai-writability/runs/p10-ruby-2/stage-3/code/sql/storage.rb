# frozen_string_literal: true

require_relative 'errors'
require_relative 'values'

module SQL
  # Returned by Column#convert for a value the column cannot hold.
  REJECTED = Object.new.freeze

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

  # A UNIQUE constraint (or a PRIMARY KEY that is not the row key) over column indexes.
  UniqueKey = Struct.new(:columns) do
    # Does `values` collide with a row of `rows` other than the one at index `skip`?
    def conflict?(values, rows, skip)
      key = values.values_at(*columns)
      return false if key.any?(&:nil?)

      rows.each_with_index.any? { |row, i| i != skip && row.values_at(*columns) == key }
    end
  end

  # A table: columns in declaration order, rows (arrays of values) in insertion order.
  # Every change goes through `insert_rows`, `update_rows` or `delete_rows`; each is all-or-nothing.
  class Table
    attr_reader :name, :columns, :rows

    # Build from a CreateTable statement (SPEC 1.4, 2.1). Declaration order of the unique
    # constraints: column constraints in column order, then the table constraints.
    def self.define(stmt)
      columns = stmt.columns.map { |c| Column.new(c.name, c.type, c.not_null, c.default) }
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

    def initialize(name, columns)
      @name = name
      @columns = columns
      @rows = []
      @key_index = nil # the INTEGER PRIMARY KEY column, which numbers rows itself
      @uniques = []
    end

    def column_index(name)
      key = name.downcase
      @columns.index { |c| c.name.downcase == key }
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
      next_key = (@key_index && working.map { |r| r[@key_index] }.max || 0) + 1
      value_rows.each do |given|
        values = @columns.each_with_index.map { |c, i| i == @key_index ? nil : c.default }
        targets.each_with_index { |col, n| values[col] = given[n] }
        row = check_row(values, working, nil, next_key)
        next_key = [next_key, row[@key_index] + 1].max if @key_index
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

    # The checks of SPEC 2.1 in their order; returns the row as stored. `skip` is the index of
    # the row being replaced (UPDATE); `next_key` is the key an INSERT gives to a NULL key.
    def check_row(values, rows, skip, next_key)
      values = values.dup
      store_key(values, next_key) if @key_index
      @columns.each_with_index do |c, i|
        raise SqlError, "NOT NULL constraint failed: #{@name}.#{c.name}" if c.not_null && values[i].nil?
      end
      check_unique(UniqueKey.new([@key_index]), values, rows, skip) if @key_index
      @columns.each_with_index { |c, i| values[i] = c.coerce(values[i], @name) unless i == @key_index }
      @uniques.reverse_each { |u| check_unique(u, values, rows, skip) }
      values
    end

    def store_key(values, next_key)
      v = values[@key_index]
      if v.nil?
        raise SqlError, 'datatype mismatch' unless next_key

        values[@key_index] = next_key
      else
        stored = @columns[@key_index].convert(v)
        raise SqlError, 'datatype mismatch' if stored.equal?(REJECTED)

        values[@key_index] = stored
      end
    end

    def check_unique(unique, values, rows, skip)
      return unless unique.conflict?(values, rows, skip)

      names = unique.columns.map { |i| "#{@name}.#{@columns[i].name}" }
      raise SqlError, "UNIQUE constraint failed: #{names.join(', ')}"
    end
  end

  # All tables of the database, looked up case-insensitively.
  class Catalog
    def initialize
      @tables = {}
    end

    def find(name) = @tables[name.downcase]

    def fetch(name) = find(name) || raise(SqlError, "no such table: #{name}")

    def add(table) = @tables[table.name.downcase] = table

    def drop(name) = @tables.delete(name.downcase)
  end
end
