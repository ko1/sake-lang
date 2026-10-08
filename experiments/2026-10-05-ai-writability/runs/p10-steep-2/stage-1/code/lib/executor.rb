module MiniSql
  # Executes one parsed statement against the database and returns the lines it prints.
  class Executor
    def initialize(database)
      @database = database
    end

    def execute(statement)
      case statement
      when CreateTable then create_table(statement)
      when DropTable then drop_table(statement)
      when Insert then insert(statement)
      when Select then Query.new(@database, statement).run
      else raise ArgumentError, "unknown statement"
      end
    end

    private

    def create_table(statement)
      if @database.find_table(statement.name)
        return [] if statement.if_not_exists
        raise SqlError, "table #{statement.name} already exists"
      end
      columns = [] # @type var columns: Array[Column]
      statement.columns.each do |definition|
        if columns.any? { |c| c.name.downcase(:ascii) == definition.name.downcase(:ascii) }
          raise SqlError, "duplicate column name: #{definition.name}"
        end
        columns << Column.new(definition.name, definition.type)
      end
      @database.add_table(Table.new(statement.name, columns))
      []
    end

    def drop_table(statement)
      removed = @database.remove_table(statement.name)
      raise SqlError, "no such table: #{statement.name}" unless removed || statement.if_exists
      []
    end

    def insert(statement)
      unless statement.rows.map(&:length).uniq.length == 1
        raise SqlError, "all VALUES must have the same number of terms"
      end
      table = @database.fetch_table(statement.table)
      targets = target_columns(statement, table)
      binder = Binder.new(nil, {})
      new_rows = statement.rows.map do |exprs|
        check_value_count(statement, table, exprs.length)
        row = Array.new(table.columns.length, nil) # @type var row: Array[sql_value]
        exprs.each_with_index do |expr, i|
          index = targets.fetch(i)
          row[index] = table.coerce(Evaluator.evaluate(binder.bind(expr), []), index)
        end
        row
      end
      new_rows.each { |row| table.append(row) }
      []
    end

    # Column positions the VALUES of each row go to.
    def target_columns(statement, table)
      names = statement.columns
      return (0...table.columns.length).to_a unless names
      names.map do |name|
        table.column_index(name) || raise(SqlError, "table #{statement.table} has no column named #{name}")
      end
    end

    def check_value_count(statement, table, count)
      names = statement.columns
      if names
        raise SqlError, "#{count} values for #{names.length} columns" unless count == names.length
      elsif count != table.columns.length
        raise SqlError, "table #{statement.table} has #{table.columns.length} columns but #{count} values were supplied"
      end
    end
  end
end
