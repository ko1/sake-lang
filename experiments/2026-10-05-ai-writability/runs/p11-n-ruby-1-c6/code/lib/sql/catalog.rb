# frozen_string_literal: true

require_relative "errors"
require_relative "identifier"
require_relative "table"

module Sql
  # A view (5.3): a named select, planned anew whenever it is used. `name` is as created; `columns`
  # is the column list or nil.
  View = Data.define(:name, :columns, :select)

  # An index (5.7). `columns` are positions in the table's rows; `constraint` is the UniqueConstraint
  # a UNIQUE index added to the table (nil for a plain index, which changes nothing).
  Index = Data.define(:name, :table, :columns, :constraint)

  # The in-memory database: tables and views (one name space), and indexes (another), by folded name.
  # A snapshot of the whole state is what BEGIN keeps and ROLLBACK goes back to.
  class Catalog
    def initialize
      @tables = {}
      @views = {}
      @indexes = {}
    end

    def table(name)
      @tables[Sql.fold(name)]
    end

    def view(name)
      @views[Sql.fold(name)]
    end

    def index(name)
      @indexes[Sql.fold(name)]
    end

    # The Table or View of that name, or nil.
    def relation(name)
      table(name) || view(name)
    end

    def fetch_table(name)
      table(name) or raise SqlError, "no such table: #{name}"
    end

    # The table an INSERT / UPDATE / DELETE changes.
    def fetch_writable_table(name)
      if (view = view(name))
        raise SqlError, "cannot modify #{view.name} because it is a view"
      end
      fetch_table(name)
    end

    def add_table(table)
      @tables[Sql.fold(table.name)] = table
    end

    def add_view(view)
      @views[Sql.fold(view.name)] = view
    end

    def add_index(index)
      @indexes[Sql.fold(index.name)] = index
    end

    # Drops a table with its indexes.
    def drop_table(name)
      table = @tables.delete(Sql.fold(name))
      @indexes.delete_if { |_, index| index.table.equal?(table) }
    end

    def drop_view(name)
      @views.delete(Sql.fold(name))
    end

    # Drops an index; a UNIQUE one stops being enforced.
    def drop_index(name)
      index = @indexes.delete(Sql.fold(name))
      index.table.remove_unique(index.constraint) if index.constraint
    end

    # The indexes of a table.
    def indexes_of(table)
      @indexes.values.select { |index| index.table.equal?(table) }
    end

    def rename_table(table, new_name)
      @tables.delete(Sql.fold(table.name))
      table.name = new_name
      add_table(table)
    end

    # An opaque copy of the whole state (rows included), for #restore.
    def snapshot
      Marshal.dump([@tables, @views, @indexes])
    end

    def restore(snapshot)
      @tables, @views, @indexes = Marshal.load(snapshot)
    end
  end
end
