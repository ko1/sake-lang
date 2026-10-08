module MiniSql
  # The in-memory database: tables by case-insensitive name.
  class Database
    def initialize
      @tables = {} # @type ivar @tables: Hash[String, Table]
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

    def remove_table(name)
      @tables.delete(key(name))
    end

    private

    def key(name)
      name.downcase(:ascii)
    end
  end
end
