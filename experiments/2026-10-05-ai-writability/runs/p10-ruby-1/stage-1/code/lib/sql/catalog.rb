# frozen_string_literal: true

require_relative "errors"
require_relative "identifier"
require_relative "values"

module Sql
  TableColumn = Data.define(:name, :type)  # name as spelled in CREATE TABLE; type :integer :real :text

  class Table
    attr_reader :name, :columns, :rows

    # name and column names keep the spelling of CREATE TABLE (used in storage error messages).
    def initialize(name, columns)
      @name = name
      @columns = columns
      @rows = []
      @index = {}
      columns.each_with_index { |c, i| @index[Sql.fold(c.name)] ||= i }
    end

    # Position of a column by (case-insensitive) name, or nil.
    def column_index(name)
      @index[Sql.fold(name)]
    end

    # Converts a value for column `index` (1.5) or raises the storage error.
    def coerce(index, value)
      column = @columns[index]
      stored, rejected = Values.coerce_for_column(value, column.type)
      return stored unless rejected
      raise SqlError, "cannot store #{rejected} value in #{column.type.to_s.upcase} column #{@name}.#{column.name}"
    end

    def append_rows(new_rows)
      @rows.concat(new_rows)
    end
  end

  # The in-memory database: tables by folded name.
  class Catalog
    def initialize
      @tables = {}
    end

    def table(name)
      @tables[Sql.fold(name)]
    end

    def fetch_table(name)
      table(name) or raise SqlError, "no such table: #{name}"
    end

    def add(table)
      @tables[Sql.fold(table.name)] = table
    end

    def drop(name)
      @tables.delete(Sql.fold(name))
    end
  end
end
