module MiniSql
  # CREATE / DROP of tables, views and indexes, and ALTER TABLE (SPEC 1.4, 5.3, 5.6, 5.7). Each change is made
  # completely or raises SqlError and changes nothing.
  class SchemaChanges
    def initialize(database)
      @database = database
    end

    def create_table(statement)
      return if name_in_use?(statement.name, statement.if_not_exists)
      @database.add_table(SchemaBuilder.build(statement))
    end

    def create_view(statement)
      return if name_in_use?(statement.name, statement.if_not_exists)
      @database.add_view(View.new(statement.name, statement.columns, statement.select))
    end

    def drop_table(statement)
      view = @database.find_view(statement.name)
      raise SqlError, "use DROP VIEW to delete view #{view.name}" if view
      removed = @database.remove_table(statement.name)
      raise SqlError, "no such table: #{statement.name}" unless removed || statement.if_exists
    end

    def drop_view(statement)
      table = @database.find_table(statement.name)
      raise SqlError, "use DROP TABLE to delete table #{table.name}" if table
      removed = @database.remove_view(statement.name)
      raise SqlError, "no such view: #{statement.name}" unless removed || statement.if_exists
    end

    def create_index(statement)
      table = @database.fetch_table(statement.table)
      if @database.find_table(statement.name) || @database.find_view(statement.name)
        raise SqlError, "there is already a table named #{statement.name}"
      end
      if @database.find_index(statement.name)
        return if statement.if_not_exists
        raise SqlError, "index #{statement.name} already exists"
      end
      key = statement.unique ? UniqueKey.new(column_positions(table, statement.columns)) : nil
      table.add_unique_key(key) if key
      @database.add_index(Index.new(statement.name, table.name, key))
    end

    def drop_index(statement)
      index = @database.remove_index(statement.name)
      unless index
        return if statement.if_exists
        raise SqlError, "no such index: #{statement.name}"
      end
      key = index.unique_key
      @database.fetch_table(index.table_name).remove_unique_key(key) if key
    end

    def add_column(statement)
      table = @database.fetch_table(statement.table)
      definition = statement.column
      raise SqlError, "duplicate column name: #{definition.name}" if table.column_index(definition.name)
      raise SqlError, "Cannot add a PRIMARY KEY column" if definition.primary_key
      raise SqlError, "Cannot add a UNIQUE column" if definition.unique
      table.add_column(Column.new(definition.name, definition.type, definition.not_null, definition.default))
    end

    def rename_table(statement)
      table = @database.fetch_table(statement.table)
      new_name = statement.new_name
      if @database.find_table(new_name) || @database.find_view(new_name) || @database.find_index(new_name)
        raise SqlError, "there is already another table or index with this name: #{new_name}"
      end
      @database.rename_table(table, new_name)
    end

    def rename_column(statement)
      table = @database.fetch_table(statement.table)
      index = table.column_index(statement.column) || raise(SqlError, "no such column: \"#{statement.column}\"")
      table.rename_column(index, statement.new_name)
    end

    private

    # Whether a table or view of this name exists: an error, or with IF NOT EXISTS nothing to do (true). A new
    # table or view may not take an index's name either.
    def name_in_use?(name, if_not_exists)
      table = @database.find_table(name)
      view = @database.find_view(name)
      if table || view
        return true if if_not_exists
        raise SqlError, table ? "table #{name} already exists" : "view #{name} already exists"
      end
      raise SqlError, "there is already an index named #{name}" if @database.find_index(name)
      false
    end

    def column_positions(table, names)
      names.map { |name| table.column_index(name) || raise(SqlError, "no such column: #{name}") }
    end
  end
end
