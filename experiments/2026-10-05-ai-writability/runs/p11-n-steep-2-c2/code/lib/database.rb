module MiniSql
  # The state saved by BEGIN: copies of the tables, and the views and indexes as they were.
  class Snapshot
    attr_reader :tables, :views, :indexes

    def initialize(tables, views, indexes)
      @tables = tables
      @views = views
      @indexes = indexes
    end
  end

  # The in-memory database: tables and views (one name space) and indexes (another), each by
  # case-insensitive name, and the transaction in progress, if any.
  class Database
    def initialize
      @tables = {} # @type ivar @tables: Hash[String, Table]
      @views = {} # @type ivar @views: Hash[String, View]
      @indexes = {} # @type ivar @indexes: Hash[String, Index]
      @saved = nil # @type ivar @saved: Snapshot?
    end

    def find_table(name)
      @tables[key(name)]
    end

    def fetch_table(name)
      find_table(name) || raise(SqlError, "no such table: #{name}")
    end

    def add_table(table)
      @tables[key(table.name)] = table
    end

    # Removes the table and its indexes; returns the table, or nil if there was none.
    def remove_table(name)
      table = @tables.delete(key(name))
      @indexes.reject! { |_, index| index.table_name.downcase(:ascii) == key(name) } if table
      table
    end

    # Gives the table a new name; its indexes follow it.
    def rename_table(table, new_name)
      @tables.delete(key(table.name))
      @indexes.transform_values! do |index|
        index.table_name.downcase(:ascii) == key(table.name) ? index.on_table(new_name) : index
      end
      table.rename(new_name)
      add_table(table)
    end

    def find_view(name)
      @views[key(name)]
    end

    def add_view(view)
      @views[key(view.name)] = view
    end

    def remove_view(name)
      @views.delete(key(name))
    end

    def find_index(name)
      @indexes[key(name)]
    end

    def add_index(index)
      @indexes[key(index.name)] = index
    end

    def remove_index(name)
      @indexes.delete(key(name))
    end

    def in_transaction?
      !@saved.nil?
    end

    def begin_transaction
      @saved = Snapshot.new(@tables.transform_values(&:copy), @views.dup, @indexes.dup)
    end

    def commit
      @saved = nil
    end

    # Goes back to the state at BEGIN.
    def rollback
      saved = @saved
      return unless saved
      @tables = saved.tables
      @views = saved.views
      @indexes = saved.indexes
      @saved = nil
    end

    private

    def key(name)
      name.downcase(:ascii)
    end
  end
end
