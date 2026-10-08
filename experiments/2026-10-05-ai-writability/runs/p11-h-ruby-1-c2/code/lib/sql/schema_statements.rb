# frozen_string_literal: true

require_relative "catalog"
require_relative "constraints"
require_relative "errors"
require_relative "identifier"
require_relative "table"

module Sql
  # CREATE / DROP of tables, views and indexes, and ALTER TABLE (2.1, 5.3, 5.6, 5.7), mixed into
  # Executor (which has @catalog). Each statement checks everything before it changes anything.
  module SchemaStatements
    private

    # ---- tables and views ----

    def execute_create_table(stmt)
      return [] if relation_exists?(stmt.name, stmt.if_not_exists)
      seen = {}
      stmt.columns.each do |c|
        key = Sql.fold(c.name)
        raise SqlError, "duplicate column name: #{c.name}" if seen[key]
        seen[key] = true
      end
      @catalog.add_table(build_table(stmt))
      []
    end

    # The Table for a CREATE TABLE: columns with their NOT NULL / DEFAULT, and the UNIQUE and
    # PRIMARY KEY constraints in declaration order (column constraints, then table constraints).
    def build_table(stmt)
      positions = {}
      stmt.columns.each_with_index { |c, i| positions[Sql.fold(c.name)] = i }
      groups = [] # [column positions, primary key?]
      stmt.columns.each_with_index do |c, i|
        groups << [[i], true] if c.primary_key
        groups << [[i], false] if c.unique
      end
      stmt.constraints.each do |tc|
        cols = tc.columns.map { |name| positions[Sql.fold(name)] or raise SqlError, "no such column: #{name}" }
        groups << [cols, tc.kind == :primary_key]
      end
      key_columns = groups.select(&:last).flat_map(&:first)
      columns = stmt.columns.each_with_index.map do |c, i|
        TableColumn.new(c.name, c.type, c.not_null || key_columns.include?(i), c.default&.value)
      end
      Table.new(stmt.name, columns, groups.map { |cols, primary| UniqueConstraint.new(cols, primary) })
    end

    def execute_drop_table(stmt)
      if (view = @catalog.view(stmt.name))
        raise SqlError, "use DROP VIEW to delete view #{view.name}"
      end
      unless @catalog.table(stmt.name)
        return [] if stmt.if_exists
        raise SqlError, "no such table: #{stmt.name}"
      end
      @catalog.drop_table(stmt.name)
      []
    end

    def execute_create_view(stmt)
      return [] if relation_exists?(stmt.name, stmt.if_not_exists)
      # the select is not checked here: each statement that uses the view reports its errors
      @catalog.add_view(View.new(stmt.name, stmt.columns, stmt.select))
      []
    end

    def execute_drop_view(stmt)
      if (table = @catalog.table(stmt.name))
        raise SqlError, "use DROP TABLE to delete table #{table.name}"
      end
      unless @catalog.view(stmt.name)
        return [] if stmt.if_exists
        raise SqlError, "no such view: #{stmt.name}"
      end
      @catalog.drop_view(stmt.name)
      []
    end

    # Is the name of a new table or view taken? True (when IF NOT EXISTS) to do nothing, else raises.
    def relation_exists?(name, if_not_exists)
      if @catalog.table(name)
        return true if if_not_exists
        raise SqlError, "table #{name} already exists"
      elsif @catalog.view(name)
        return true if if_not_exists
        raise SqlError, "view #{name} already exists"
      end
      raise SqlError, "there is already an index named #{name}" if @catalog.index(name)
      false
    end

    # ---- indexes ----

    def execute_create_index(stmt)
      table = @catalog.table(stmt.table)
      raise SqlError, "views may not be indexed" if table.nil? && @catalog.view(stmt.table)
      table or raise SqlError, "no such table: #{stmt.table}"
      raise SqlError, "there is already a table named #{stmt.name}" if @catalog.relation(stmt.name)
      if @catalog.index(stmt.name)
        return [] if stmt.if_not_exists
        raise SqlError, "index #{stmt.name} already exists"
      end
      positions = stmt.columns.map { |name| table.column_index(name) or raise SqlError, "no such column: #{name}" }
      constraint = stmt.unique ? UniqueConstraint.new(positions, false) : nil
      table.add_unique(constraint) if constraint
      @catalog.add_index(Index.new(stmt.name, table, positions, constraint))
      []
    end

    def execute_drop_index(stmt)
      unless @catalog.index(stmt.name)
        return [] if stmt.if_exists
        raise SqlError, "no such index: #{stmt.name}"
      end
      @catalog.drop_index(stmt.name)
      []
    end

    # ---- ALTER TABLE ----

    def execute_add_column(stmt)
      table = alterable_table(stmt.table)
      c = stmt.column
      raise SqlError, "duplicate column name: #{c.name}" if table.column_index(c.name)
      raise SqlError, "Cannot add a PRIMARY KEY column" if c.primary_key
      raise SqlError, "Cannot add a UNIQUE column" if c.unique
      table.add_column(TableColumn.new(c.name, c.type, c.not_null, c.default&.value))
      []
    end

    def execute_rename_table(stmt)
      table = alterable_table(stmt.table)
      if @catalog.relation(stmt.new_name) || @catalog.index(stmt.new_name)
        raise SqlError, "there is already another table or index with this name: #{stmt.new_name}"
      end
      @catalog.rename_table(table, stmt.new_name)
      []
    end

    def execute_rename_column(stmt)
      table = alterable_table(stmt.table)
      index = table.column_index(stmt.column) or raise SqlError, %(no such column: "#{stmt.column}")
      table.rename_column(index, stmt.new_name)
      []
    end

    def alterable_table(name)
      raise SqlError, "cannot alter #{@catalog.view(name).name}: it is a view" if @catalog.view(name)
      @catalog.fetch_table(name)
    end
  end
end
