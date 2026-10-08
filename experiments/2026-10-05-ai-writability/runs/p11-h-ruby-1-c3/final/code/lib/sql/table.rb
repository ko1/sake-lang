# frozen_string_literal: true

require_relative "constraints"
require_relative "errors"
require_relative "identifier"
require_relative "values"

module Sql
  # name as spelled in CREATE TABLE; type :integer :real :text; default is the DEFAULT value (nil: NULL).
  TableColumn = Data.define(:name, :type, :not_null, :default)

  # A table: its schema, its rows (arrays of stored values, in insertion order) and the checks of
  # 2.1 and 7.3. All changes go through insert/update/delete; `atomically` makes a group of them
  # all-or-nothing.
  #
  # A stored row has one value per column, then the rowid as its last value. With an INTEGER PRIMARY
  # KEY the last value is a copy kept equal to that column, which is what the rowid names read.
  class Table
    attr_reader :columns, :rows
    attr_accessor :name # changed only by Catalog#rename_table

    # name and column names keep the spelling of CREATE TABLE (used in storage error messages).
    # uniques: UniqueConstraint objects in declaration order.
    def initialize(name, columns, uniques)
      @name = name
      @columns = columns
      @uniques = uniques
      @rows = []
      @index = {}
      columns.each_with_index { |c, i| @index[Sql.fold(c.name)] ||= i }
      @ipk_constraint = uniques.find do |u|
        u.primary_key? && u.columns.length == 1 && columns[u.columns.first].type == :integer
      end
      @ipk = @ipk_constraint&.columns&.first
      @rowid_index = @ipk ? nil : RowidIndex.new # uniqueness of the rowid when no column is the key
      @rowid_max = nil # cached largest rowid, nil when unknown
      @journal = nil
    end

    # Position in a stored row that the rowid names (7.1) read and a store into the rowid writes.
    def rowid_pos
      @ipk || @columns.length
    end

    # Position that a statement storing into the column `name` writes, or nil: a real column, else
    # (a rowid name that is not a real column) the rowid.
    def store_index(name)
      column_index(name) || (Sql.rowid_name?(name) ? rowid_pos : nil)
    end

    # Position of a column by (case-insensitive) name, or nil.
    def column_index(name)
      @index[Sql.fold(name)]
    end

    # A fresh row of raw values: each column's DEFAULT.
    def default_row
      @columns.map(&:default) << nil
    end

    # ALTER TABLE ADD COLUMN (5.6): appends `column`; existing rows get its DEFAULT converted as in 1.5.
    # Raises (changing nothing) if that cannot be done.
    def add_column(column)
      raise SqlError, "duplicate column name: #{column.name}" if column_index(column.name)
      if column.not_null && column.default.nil? && !@rows.empty?
        raise SqlError, "Cannot add a NOT NULL column with default value NULL"
      end
      value = @rows.empty? ? nil : coerce_value(column, column.default)
      @columns += [column]
      @index[Sql.fold(column.name)] = @columns.length - 1
      @rows.each { |row| row.insert(-2, value) } # before the rowid
    end

    # ALTER TABLE RENAME COLUMN (5.6): constraints refer to positions, so they follow.
    def rename_column(index, new_name)
      @index.delete_if { |_, i| i == index }
      @columns = @columns.each_with_index.map { |c, i| i == index ? c.with(name: new_name) : c }
      @columns.each_with_index { |c, i| @index[Sql.fold(c.name)] ||= i }
    end

    # Starts enforcing a UniqueConstraint built after the table (a UNIQUE index, 5.7), checked before
    # the older ones. Raises the constraint's error, adding nothing, if the rows already conflict.
    def add_unique(constraint)
      @rows.each do |row|
        raise unique_violation(constraint) if constraint.conflicting_row(row)
        constraint.add(row)
      end
      @uniques << constraint
    end

    def remove_unique(constraint)
      @uniques.delete_if { |u| u.equal?(constraint) }
    end

    # Runs the block; if it raises, every insert/update done inside is undone.
    def atomically
      @journal = []
      yield
    rescue Exception # rubocop:disable Lint/RescueException -- undo, then re-raise whatever it was
      @journal.reverse_each(&:call)
      @rowid_max = nil
      raise
    ensure
      @journal = nil
    end

    # Checks raw values (one per column) and appends the row.
    def insert(raw)
      row = check_row(raw, nil)
      @rows << row
      each_index_structure { |u| u.add(row) }
      @rowid_max = [@rowid_max, row.last].max if @rowid_max
      @journal&.push(lambda do
        @rows.pop
        each_index_structure { |u| u.remove(row) }
      end)
    end

    # Replaces the contents of `row` (a row of this table) by the checked raw values.
    def update(row, raw)
      stored = check_row(raw, row)
      old = row.dup
      each_index_structure { |u| u.remove(row) }
      row.replace(stored)
      each_index_structure { |u| u.add(row) }
      @rowid_max = nil
      @journal&.push(lambda do
        each_index_structure { |u| u.remove(row) }
        row.replace(old)
        each_index_structure { |u| u.add(row) }
      end)
    end

    # Removes the given rows (objects of #rows).
    def delete(doomed)
      return if doomed.empty?
      gone = doomed.to_h { |r| [r, true] }.compare_by_identity
      @rows = @rows.reject { |r| gone.key?(r) }
      doomed.each { |r| each_index_structure { |u| u.remove(r) } }
      @rowid_max = nil
    end

    private

    # Every structure that finds rows by value: the UNIQUE / PRIMARY KEY constraints, and the rowid's.
    def each_index_structure(&block)
      @uniques.each(&block)
      yield @rowid_index if @rowid_index
    end

    # Converts a value for column `index` (1.5) or raises the storage error.
    def coerce(index, value)
      coerce_value(@columns[index], value)
    end

    def coerce_value(column, value)
      stored, rejected = Values.coerce_for_column(value, column.type)
      return stored unless rejected
      raise SqlError, "cannot store #{rejected} value in #{column.type.to_s.upcase} column #{@name}.#{column.name}"
    end

    # The checks of 2.1 and 7.3, in their order; `current` is the row being updated (nil for an insert).
    # Returns the stored row.
    def check_row(raw, current)
      values = raw.dup
      store_rowid(values, current)
      @columns.each_with_index do |c, i|
        raise SqlError, "NOT NULL constraint failed: #{@name}.#{c.name}" if c.not_null && values[i].nil?
      end
      check_unique(@ipk_constraint || @rowid_index, values, current)
      @columns.each_index { |i| values[i] = coerce(i, values[i]) unless i == @ipk }
      @uniques.reverse_each do |u|
        check_unique(u, values, current) unless u.equal?(@ipk_constraint)
      end
      values
    end

    # Settles the rowid (the INTEGER PRIMARY KEY's value, else the last value) and mirrors it into the last value.
    def store_rowid(values, current)
      pos = rowid_pos
      value = values[pos]
      if value.nil?
        raise SqlError, "datatype mismatch" if current
        values[pos] = next_rowid
      else
        stored, rejected = Values.coerce_for_column(value, :integer)
        raise SqlError, "datatype mismatch" if rejected
        values[pos] = stored
      end
      values[-1] = values[pos]
    end

    def next_rowid
      @rowid_max ||= @rows.map(&:last).max # stays nil (unknown) while the table is empty
      @rowid_max ? @rowid_max + 1 : 1
    end

    def check_unique(constraint, values, current)
      other = constraint.conflicting_row(values)
      return if other.nil? || other.equal?(current)
      raise unique_violation(constraint)
    end

    def unique_violation(constraint)
      return SqlError.new("UNIQUE constraint failed: #{@name}.rowid") if constraint.equal?(@rowid_index)
      names = constraint.columns.map { |i| "#{@name}.#{@columns[i].name}" }
      SqlError.new("UNIQUE constraint failed: #{names.join(", ")}")
    end
  end
end
