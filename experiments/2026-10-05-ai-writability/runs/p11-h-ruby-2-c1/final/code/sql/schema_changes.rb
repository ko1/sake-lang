# frozen_string_literal: true

require_relative 'ast'
require_relative 'catalog'
require_relative 'collation'
require_relative 'errors'
require_relative 'storage'

module SQL
  # CREATE / DROP of tables, views and indexes, and ALTER TABLE (SPEC 1.4, 5.3, 5.6, 5.7).
  # Each method checks everything before it changes the catalog, so an error leaves it as it was.
  class SchemaChanges
    def initialize(catalog)
      @catalog = catalog
    end

    def create_table(stmt)
      return unless claim_name(stmt.name, stmt.if_not_exists)

      seen = {}
      stmt.columns.each do |c|
        raise SqlError, "duplicate column name: #{c.name}" if seen[c.name.downcase]

        seen[c.name.downcase] = true
      end
      @catalog.add(Table.define(stmt))
    end

    def drop_table(stmt)
      if (view = @catalog.find_view(stmt.name))
        raise SqlError, "use DROP VIEW to delete view #{view.name}"
      elsif @catalog.find(stmt.name)
        @catalog.drop(stmt.name)
      elsif !stmt.if_exists
        raise SqlError, "no such table: #{stmt.name}"
      end
    end

    def create_view(stmt)
      return unless claim_name(stmt.name, stmt.if_not_exists)

      @catalog.add_view(View.new(stmt.name, stmt.columns, stmt.query))
    end

    def drop_view(stmt)
      if (table = @catalog.find(stmt.name))
        raise SqlError, "use DROP TABLE to delete table #{table.name}"
      elsif @catalog.find_view(stmt.name)
        @catalog.drop_view(stmt.name)
      elsif !stmt.if_exists
        raise SqlError, "no such view: #{stmt.name}"
      end
    end

    def create_index(stmt)
      table = @catalog.fetch(stmt.table)
      raise SqlError, 'views may not be indexed' if @catalog.find_view(stmt.table)
      raise SqlError, "there is already a table named #{stmt.name}" if table_or_view?(stmt.name)

      if @catalog.find_index(stmt.name)
        return if stmt.if_not_exists

        raise SqlError, "index #{stmt.name} already exists"
      end
      cols = stmt.columns.map { |n| table.column_index(n) or raise SqlError, "no such column: #{n}" }
      collations = stmt.collations.map { |c| c && Collation.lookup(c) }
      table.add_index(stmt.name, cols, stmt.unique, collations)
    end

    def drop_index(stmt)
      table, index = @catalog.find_index(stmt.name)
      if index
        table.drop_index(index)
      elsif !stmt.if_exists
        raise SqlError, "no such index: #{stmt.name}"
      end
    end

    def add_column(stmt)
      table = alterable_table(stmt.table)
      col = stmt.column
      raise SqlError, "duplicate column name: #{col.name}" if table.column_index(col.name)
      raise SqlError, 'Cannot add a PRIMARY KEY column' if col.primary_key
      raise SqlError, 'Cannot add a UNIQUE column' if col.unique
      if col.not_null && col.default.nil? && !table.rows.empty?
        raise SqlError, 'Cannot add a NOT NULL column with default value NULL'
      end

      table.add_column(Table.column_for(col))
    end

    def rename_table(stmt)
      table = alterable_table(stmt.table)
      other = @catalog.find(stmt.new_name)
      taken = (other && !other.equal?(table)) || @catalog.find_view(stmt.new_name) ||
              @catalog.find_index(stmt.new_name)
      raise SqlError, "there is already another table or index with this name: #{stmt.new_name}" if taken

      @catalog.rename(table, stmt.new_name)
    end

    def rename_column(stmt)
      table = alterable_table(stmt.table)
      index = table.column_index(stmt.column) or raise SqlError, %(no such column: "#{stmt.column}")
      table.rename_column(index, stmt.new_name)
    end

    private

    def table_or_view?(name) = @catalog.find(name) || @catalog.find_view(name)

    def alterable_table(name)
      raise SqlError, "view #{@catalog.find_view(name).name} may not be altered" if @catalog.find_view(name)

      @catalog.fetch(name)
    end

    # Does a new table or view called `name` have a free name? false when it exists and
    # `if_not_exists` says to do nothing; else raises if the name is taken.
    def claim_name(name, if_not_exists)
      if @catalog.find(name)
        return false if if_not_exists

        raise SqlError, "table #{name} already exists"
      elsif @catalog.find_view(name)
        return false if if_not_exists

        raise SqlError, "view #{name} already exists"
      elsif @catalog.find_index(name)
        raise SqlError, "there is already an index named #{name}"
      end
      true
    end
  end
end
