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
      when Update then update(statement)
      when Delete then delete(statement)
      when Select then Query.new(Planner.new(@database, statement, nil).plan).lines
      else raise ArgumentError, "unknown statement"
      end
    end

    private

    def create_table(statement)
      if @database.find_table(statement.name)
        return [] if statement.if_not_exists
        raise SqlError, "table #{statement.name} already exists"
      end
      @database.add_table(SchemaBuilder.build(statement))
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
      binder = Binder.new(Sources.new, {}, environment)
      new_rows = statement.rows.map do |exprs|
        check_value_count(statement, table, exprs.length)
        row = table.default_row
        exprs.each_with_index { |expr, i| row[targets.fetch(i)] = Evaluator.evaluate(binder.bind(expr), []) }
        row
      end
      table.insert_rows(new_rows)
      []
    end

    def update(statement)
      table = @database.fetch_table(statement.table)
      binder = target_binder(table)
      assignments = [] # @type var assignments: Array[[Integer, Expr]]
      statement.assignments.each do |assignment|
        index = table.column_index(assignment.column) || raise(SqlError, "no such column: #{assignment.column}")
        assignments << [index, binder.bind(assignment.expr)]
      end
      where = bound_condition(binder, statement.where)
      changes = [] # @type var changes: Array[[Integer, Array[sql_value]]]
      table.rows.each_with_index do |row, position|
        next unless matches?(where, row)
        changed = row.dup
        assignments.each { |index, expr| changed[index] = Evaluator.evaluate(expr, row) }
        changes << [position, changed]
      end
      table.replace_rows(changes)
      []
    end

    def delete(statement)
      table = @database.fetch_table(statement.table)
      where = bound_condition(target_binder(table), statement.where)
      positions = [] # @type var positions: Array[Integer]
      table.rows.each_with_index { |row, position| positions << position if matches?(where, row) }
      table.delete_rows(positions)
      []
    end

    def environment
      Environment.new(@database, RowFrame.new, nil)
    end

    # Binds against the target table, which subqueries in SET and WHERE see as an enclosing source (SPEC 4.2).
    def target_binder(table)
      sources = Sources.new
      sources.add(TableSource.new(table.name, table, 0))
      Binder.new(sources, {}, environment)
    end

    def bound_condition(binder, condition)
      condition ? binder.bind(condition) : nil
    end

    # Whether the row satisfies a bound WHERE (always, when there is none).
    def matches?(where, row)
      where.nil? || Value.truth(Evaluator.evaluate(where, row)) == true
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
