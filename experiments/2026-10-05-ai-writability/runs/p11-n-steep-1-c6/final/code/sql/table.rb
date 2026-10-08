# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "schema"
require_relative "value"

module Sql
  # A table: its columns, its constraints and its rows (arrays of values in column order).
  # Every change goes through insert_rows, update_rows or delete_rows, which check the
  # constraints (spec 2.1) and either apply the whole statement's change or none of it.
  class Table
    attr_reader :name, :columns, :rows

    # rowid is the position of the INTEGER PRIMARY KEY column, if any. uniques lists the other
    # UNIQUE / PRIMARY KEY constraints (as column positions) in declaration order. Those of UNIQUE
    # indexes follow them (index_uniques, by folded index name).
    def initialize(name, columns, rowid, uniques)
      @name = name
      @columns = columns
      @rowid = rowid
      @uniques = uniques
      @index_uniques = {} #: Hash[String, Array[Integer]]
      @rows = [] #: Array[Array[value]]
    end

    # A table that later changes to this one do not reach (rows are never changed in place).
    def copy
      table = Table.new(@name, @columns.dup, @rowid, @uniques.dup)
      table.restore(@rows, @index_uniques.dup)
      table
    end

    # Sets the state copy cannot pass through initialize.
    def restore(rows, index_uniques)
      @rows = rows
      @index_uniques = index_uniques
    end

    # Builds the table a CREATE TABLE describes; raises on a repeated or unknown column name.
    def self.from_statement(statement)
      definitions = statement.columns
      seen = {} #: Hash[String, bool]
      definitions.each do |definition|
        key = Names.fold(definition.name)
        raise Error, "duplicate column name: #{definition.name}" if seen.key?(key)

        seen[key] = true
      end

      declared = [] #: Array[Array[Integer]]
      primary = nil #: Array[Integer]?
      definitions.each_with_index do |definition, i|
        next unless definition.primary_key || definition.unique

        declared << [i]
        primary = declared.last if definition.primary_key
      end
      statement.constraints.each do |constraint|
        declared << positions(definitions, constraint.columns)
        primary = declared.last if constraint.primary_key
      end

      rowid = primary && primary.length == 1 && definitions.fetch(primary.fetch(0)).type == :integer ? primary.fetch(0) : nil
      uniques = declared.reject { |columns| rowid && columns.equal?(primary) }
      required = primary || []
      columns = definitions.each_with_index.map do |d, i|
        Column.new(d.name, d.type, d.not_null || required.include?(i), i == rowid ? nil : d.default_value)
      end
      new(statement.name, columns, rowid, uniques)
    end

    # The positions of the named columns.
    def self.positions(definitions, names)
      names.map do |n|
        definitions.index { |d| Names.fold(d.name) == Names.fold(n) } || raise(Error, "no such column: #{n}")
      end
    end
    private_class_method :positions

    # The positions of the named columns of this table, or the error for an unknown one.
    def positions_of(names)
      names.map { |n| column_index(n) || raise(Error, "no such column: #{n}") }
    end

    def rename_to(new_name)
      @name = new_name
    end

    # Appends a column (spec 5.6); existing rows get its default. Changes nothing when it raises.
    def add_column(definition)
      raise Error, "Cannot add a PRIMARY KEY column" if definition.primary_key
      raise Error, "Cannot add a UNIQUE column" if definition.unique

      default = definition.default_value
      if definition.not_null && default.nil? && !@rows.empty?
        raise Error, "Cannot add a NOT NULL column with default value NULL"
      end
      raise Error, "duplicate column name: #{definition.name}" if column_index(definition.name)

      column = Column.new(definition.name, definition.type, definition.not_null, default)
      filled = column.store(default, @name)
      @rows = @rows.map { |row| row + [filled] }
      @columns += [column]
    end

    def rename_column(old_name, new_name)
      position = column_index(old_name) || raise(Error, "no such column: \"#{old_name}\"")
      @columns = @columns.each_with_index.map { |column, i| i == position ? column.renamed(new_name) : column }
    end

    # Makes a UNIQUE index's columns a uniqueness constraint, checked before the existing ones.
    # Raises (and changes nothing) when the rows already break it.
    def add_unique_index(index_name, positions)
      @rows.each_with_index do |row, i|
        raise Error, unique_message(positions) if duplicate?(positions, row, @rows, i)
      end
      @index_uniques[Names.fold(index_name)] = positions
    end

    def drop_unique_index(index_name)
      @index_uniques.delete(Names.fold(index_name))
    end

    def column_index(name)
      key = Names.fold(name)
      @columns.index { |column| Names.fold(column.name) == key }
    end

    # A row holding each column's default, which an INSERT overwrites with the values it gives.
    def default_row
      @columns.map(&:default)
    end

    # Adds rows (each full width, not yet converted) one at a time, each checked against the
    # table with the rows before it; adds none if one fails.
    def insert_rows(raw_rows)
      work = @rows.dup
      raw_rows.each { |raw| work << checked_row(raw, work, nil) }
      @rows = work
    end

    # changes pairs the position of a row with its new, not yet converted, values.
    def update_rows(changes)
      work = @rows.dup
      changes.each { |position, raw| work[position] = checked_row(raw, work, position) }
      @rows = work
    end

    # doomed[i] tells whether the i-th row is removed.
    def delete_rows(doomed)
      kept = [] #: Array[Array[value]]
      @rows.each_with_index { |row, i| kept << row unless doomed.fetch(i) }
      @rows = kept
    end

    private

    # The row as stored, or the constraint error. others are the rows to check uniqueness
    # against; the one at position skip (an updated row itself) is ignored.
    def checked_row(raw, others, skip)
      row = raw.dup
      rowid = @rowid
      row[rowid] = key_value(raw.fetch(rowid), others, skip.nil?) if rowid
      @columns.each_with_index do |column, i|
        raise Error, "NOT NULL constraint failed: #{@name}.#{column.name}" if column.not_null && i != rowid && row.fetch(i).nil?
      end
      raise Error, unique_message([rowid]) if rowid && duplicate?([rowid], row, others, skip)

      @columns.each_with_index { |column, i| row[i] = column.store(row.fetch(i), @name) unless i == rowid }
      (@uniques + @index_uniques.values).reverse_each { |columns| raise Error, unique_message(columns) if duplicate?(columns, row, others, skip) }
      row
    end

    # The INTEGER PRIMARY KEY value: a given value converted to an INTEGER, or for an INSERT
    # without one the next free key.
    def key_value(given, others, inserting)
      if given.nil?
        raise Error, "datatype mismatch" unless inserting

        return next_key(others)
      end
      given = Value.parse_numeric_text(given) || given if given.is_a?(String)
      case given
      when Integer then given
      when Float then Value.integer_exact(given) || raise(Error, "datatype mismatch")
      else raise Error, "datatype mismatch"
      end
    end

    def next_key(others)
      rowid = @rowid
      largest = 0
      others.each do |row|
        key = rowid ? row.fetch(rowid) : nil
        largest = key if key.is_a?(Integer) && key > largest
      end
      largest + 1
    end

    # Whether another row has equal values in all the columns (never so with a NULL among them).
    def duplicate?(positions, row, others, skip)
      return false if positions.any? { |i| row.fetch(i).nil? }

      others.each_with_index do |other, n|
        next if n == skip

        return true if positions.all? { |i| Value.compare(row.fetch(i), other.fetch(i)) == 0 }
      end
      false
    end

    def unique_message(positions)
      "UNIQUE constraint failed: " + positions.map { |i| "#{@name}.#{@columns.fetch(i).name}" }.join(", ")
    end
  end
end
