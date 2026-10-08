# frozen_string_literal: true

require_relative "constraints"
require_relative "errors"
require_relative "identifier"
require_relative "values"

module Sql
  # name as spelled in CREATE TABLE; type :integer :real :text; default is the DEFAULT value (nil: NULL).
  TableColumn = Data.define(:name, :type, :not_null, :default)

  # A table: its schema, its rows (arrays of stored values, in insertion order) and the checks of
  # 2.1. A stored row is its column values followed by the row's rowid (7), so the rowid is always
  # `row[-1]`, wherever ADD COLUMN has put the columns; for an INTEGER PRIMARY KEY the key column and
  # the rowid hold the same value. All changes go through insert/update/delete; `atomically` makes a group of them all-or-nothing.
  class Table
    ROWID_SLOT = -1 # index of the rowid in a stored row

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
      # the constraint that makes rowids unique: the INTEGER PRIMARY KEY's, else one on the rowid slot (-1)
      @key_constraint = @ipk_constraint || UniqueConstraint.new([ROWID_SLOT], false).tap { |c| uniques.unshift(c) }
      @rowid_max = nil # cached largest rowid, nil when unknown
      @journal = nil
    end

    # Position of a column by (case-insensitive) name, or nil.
    def column_index(name)
      @index[Sql.fold(name)]
    end

    # A fresh row of raw values: each column's DEFAULT, then no rowid (NULL: assign one).
    def default_row
      @columns.map(&:default) + [nil]
    end

    # Where a statement that names the rowid puts the value in a raw row: the INTEGER PRIMARY KEY, else the rowid slot.
    def key_position
      @ipk || @columns.length
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
      @rows.each { |row| row.insert(ROWID_SLOT, value) } # before the rowid
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
      @uniques.each { |u| u.add(row) }
      @rowid_max = [@rowid_max, row[ROWID_SLOT]].max if @rowid_max
      @journal&.push(lambda do
        @rows.pop
        @uniques.each { |u| u.remove(row) }
      end)
    end

    # Replaces the contents of `row` (a row of this table) by the checked raw values.
    def update(row, raw)
      stored = check_row(raw, row)
      old = row.dup
      @uniques.each { |u| u.remove(row) }
      row.replace(stored)
      @uniques.each { |u| u.add(row) }
      @rowid_max = nil
      @journal&.push(lambda do
        @uniques.each { |u| u.remove(row) }
        row.replace(old)
        @uniques.each { |u| u.add(row) }
      end)
    end

    # Removes the given rows (objects of #rows).
    def delete(doomed)
      return if doomed.empty?
      gone = doomed.to_h { |r| [r, true] }.compare_by_identity
      @rows = @rows.reject { |r| gone.key?(r) }
      doomed.each { |r| @uniques.each { |u| u.remove(r) } }
      @rowid_max = nil
    end

    private

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
    # `raw` has one value per column and then the rowid. Returns the stored row.
    def check_row(raw, current)
      values = raw.dup
      store_key(values, current)
      @columns.each_with_index do |c, i|
        raise SqlError, "NOT NULL constraint failed: #{@name}.#{c.name}" if c.not_null && values[i].nil?
      end
      check_unique(@key_constraint, values, current)
      @columns.each_index { |i| values[i] = coerce(i, values[i]) unless i == @ipk }
      @uniques.reverse_each do |u|
        check_unique(u, values, current) unless u.equal?(@key_constraint)
      end
      values
    end

    # Settles the rowid (7.3): given (an INTEGER after 1.5), or assigned on insert (NULL is an error on
    # update). It is read from the INTEGER PRIMARY KEY column if there is one, and then copied to the
    # other of the two.
    def store_key(values, current)
      value = values[key_position]
      if value.nil?
        raise SqlError, "datatype mismatch" if current
        value = next_key
      else
        value, rejected = Values.coerce_for_column(value, :integer)
        raise SqlError, "datatype mismatch" if rejected
      end
      values[key_position] = value
      values[ROWID_SLOT] = value
    end

    def next_key
      @rowid_max ||= @rows.map { |r| r[ROWID_SLOT] }.max || 0
      @rowid_max + 1
    end

    def check_unique(constraint, values, current)
      other = constraint.conflicting_row(values)
      return if other.nil? || other.equal?(current)
      raise unique_violation(constraint)
    end

    def unique_violation(constraint)
      names = constraint.columns.map { |i| "#{@name}.#{i == ROWID_SLOT ? "rowid" : @columns[i].name}" }
      SqlError.new("UNIQUE constraint failed: #{names.join(", ")}")
    end
  end
end
