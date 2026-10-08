module MiniSql
  # Executes one parsed statement against the database and returns the lines it prints.
  class Executor
    def initialize(database)
      @database = database
      @schema = SchemaChanges.new(database)
    end

    def execute(statement)
      case statement
      when SelectNode then select(statement)
      when Insert then insert(statement)
      when Update then update(statement)
      when Delete then delete(statement)
      when TransactionStatement then transaction(statement)
      else define_schema(statement)
      end
    end

    private

    def select(statement)
      Planner.new(@database, statement, nil, nil).plan.rows.map do |values|
        values.map { |value| Value.render(value) }.join("|")
      end
    end

    def define_schema(statement)
      case statement
      when CreateTable then @schema.create_table(statement)
      when CreateView then @schema.create_view(statement)
      when CreateIndex then @schema.create_index(statement)
      when DropTable then @schema.drop_table(statement)
      when DropView then @schema.drop_view(statement)
      when DropIndex then @schema.drop_index(statement)
      when AddColumn then @schema.add_column(statement)
      when RenameTable then @schema.rename_table(statement)
      when RenameColumn then @schema.rename_column(statement)
      else raise ArgumentError, "unknown statement"
      end
      []
    end

    def transaction(statement)
      case statement.kind
      when :begin
        raise SqlError, "cannot start a transaction within a transaction" if @database.in_transaction?
        @database.begin_transaction
      when :commit
        raise SqlError, "cannot commit - no transaction is active" unless @database.in_transaction?
        @database.commit
      else
        raise SqlError, "cannot rollback - no transaction is active" unless @database.in_transaction?
        @database.rollback
      end
      []
    end

    # INSERT INTO table [(columns)] VALUES ... | select.
    def insert(statement)
      refuse_view(statement.table)
      ctes = statement.with ? CtePlanner.new(@database, nil, nil).scope_for(statement.with) : nil
      source = statement.source
      rows =
        if source.is_a?(ValuesList)
          values_rows(statement, source, ctes)
        elsif source.is_a?(SelectNode)
          select_rows(statement, source, ctes)
        else
          raise ArgumentError, "unknown insert source"
        end
      @database.fetch_table(statement.table).insert_rows(rows)
      []
    end

    # The full-width rows a VALUES list stands for.
    def values_rows(statement, source, ctes)
      unless source.rows.map(&:length).uniq.length == 1
        raise SqlError, "all VALUES must have the same number of terms"
      end
      table = @database.fetch_table(statement.table)
      targets = target_columns(statement, table)
      binder = Binder.new(Sources.new, {}, environment(ctes))
      source.rows.map do |exprs|
        check_value_count(statement, table, exprs.length)
        full_row(table, targets, exprs.map { |expr| Evaluator.evaluate(binder.bind(expr), []) })
      end
    end

    # The full-width rows of a select, which is computed completely first.
    def select_rows(statement, source, ctes)
      table = @database.fetch_table(statement.table)
      targets = target_columns(statement, table)
      plan = Planner.new(@database, source, nil, ctes).plan
      check_value_count(statement, table, plan.columns.length)
      plan.rows.map { |values| full_row(table, targets, values) }
    end

    # A row of the table with these values in the target columns and defaults elsewhere.
    def full_row(table, targets, values)
      row = table.default_row
      values.each_with_index { |value, i| row[targets.fetch(i)] = value }
      row
    end

    def refuse_view(name)
      view = @database.find_view(name)
      raise SqlError, "cannot modify #{view.name} because it is a view" if view
    end

    def update(statement)
      refuse_view(statement.table)
      table = @database.fetch_table(statement.table)
      binder = target_binder(table)
      assignments = [] # @type var assignments: Array[[Integer, Expr]]
      statement.assignments.each do |assignment|
        index = table.target_index(assignment.column) || raise(SqlError, "no such column: #{assignment.column}")
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
      refuse_view(statement.table)
      table = @database.fetch_table(statement.table)
      where = bound_condition(target_binder(table), statement.where)
      positions = [] # @type var positions: Array[Integer]
      table.rows.each_with_index { |row, position| positions << position if matches?(where, row) }
      table.delete_rows(positions)
      []
    end

    def environment(ctes)
      Environment.new(@database, RowFrame.new, nil, ctes)
    end

    # Binds against the target table, which subqueries in SET and WHERE see as an enclosing source (SPEC 4.2).
    def target_binder(table)
      sources = Sources.new
      sources.add(TableSource.new(table.name, table, 0))
      Binder.new(sources, {}, environment(nil))
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
        table.target_index(name) || raise(SqlError, "table #{statement.table} has no column named #{name}")
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
