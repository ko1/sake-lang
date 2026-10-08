require_relative "errors"
require_relative "ast"
require_relative "schema"
require_relative "catalog"
require_relative "query"
require_relative "binder"
require_relative "select_query"

# The in-memory database and the execution of statements. `execute` returns the result rows (empty
# for statements other than SELECT) or raises SqlError, in which case the database is unchanged.
# The database is also the outermost Catalog: the views and tables a FROM can name.
class Database
  SCHEMA_STATEMENTS = {
    AST::CreateTable => :create_table, AST::DropTable => :drop_table,
    AST::CreateView => :create_view, AST::DropView => :drop_view,
    AST::CreateIndex => :create_index, AST::DropIndex => :drop_index,
    AST::AddColumn => :add_column, AST::RenameTable => :rename_table, AST::RenameColumn => :rename_column
  }.freeze

  def initialize
    @schema = Schema.new
    @saved = nil     # the schema as BEGIN found it, while a transaction is open
    @expanding = []  # the views being bound, innermost last
  end

  def execute(statement)
    if (action = SCHEMA_STATEMENTS[statement.class])
      @schema.public_send(action, statement)
      return []
    end
    case statement
    when AST::Transaction then transaction(statement.action)
    when AST::Insert then insert(statement)
    when AST::Update then update(statement)
    when AST::Delete then delete(statement)
    when AST::Select, AST::Compound, AST::With then Query.build(statement, self).rows
    else raise ArgumentError, "unknown statement #{statement.inspect}"
    end
  end

  # Catalog: a view, else a table, of that name; nil if there is none.
  def relation(name)
    view = @schema.view(name)
    view ? Catalog::ViewSource.new(view, self) : @schema.table(name)
  end

  # Runs the block (the binding of view's select), refusing a view that is used inside itself.
  def expanding(view)
    raise SqlError, "view #{view.name} is circularly defined" if @expanding.include?(view)
    @expanding.push(view)
    begin
      yield
    ensure
      @expanding.pop
    end
  end

  private

  # BEGIN keeps a copy of the schema (tables with their rows, views, indexes); ROLLBACK goes back to
  # it (5.5).
  def transaction(action)
    case action
    when :begin
      raise SqlError, "cannot start a transaction within a transaction" if @saved
      @saved = @schema.dup
    when :commit
      raise SqlError, "cannot commit - no transaction is active" unless @saved
      @saved = nil
    when :rollback
      raise SqlError, "cannot rollback - no transaction is active" unless @saved
      @schema = @saved
      @saved = nil
    end
    []
  end

  # INSERT ... VALUES and INSERT ... select (5.4): the rows are all computed first, then stored one at
  # a time, each checked against the table as the previous rows left it; the table changes only when
  # every row succeeded.
  def insert(stmt)
    table = @schema.target_table(stmt.table)
    catalog = stmt.with ? Catalog.with(stmt.with, self, nil) : self
    if stmt.select
      query = Query.build(stmt.select, catalog)
      targets = insert_targets(table, stmt, query.column_names.length)
      value_rows = query.rows
    else
      width = stmt.rows.first.length
      unless stmt.rows.all? { |values| values.length == width }
        raise SqlError, "all VALUES must have the same number of terms"
      end
      targets = insert_targets(table, stmt, width)
      value_rows = stmt.rows.map do |exprs|
        exprs.map { |expr| Binder.bind(expr, catalog).evaluate(Expressions::EMPTY_FRAME) }
      end
    end
    rows = table.rows.dup
    value_rows.each do |values|
      row = table.default_row
      # A column listed twice takes its first value, as in SQLite (the spec does not say).
      values.zip(targets).reverse_each { |value, index| row[index] = value }
      rows << table.store(row, rows, inserting: true)
    end
    table.replace_rows(rows)
    []
  end

  # Each changed row is checked against the table at that moment (spec 2.2); on an error the table
  # keeps its old rows.
  def update(stmt)
    table = @schema.target_table(stmt.table)
    binder = target_binder(table)
    assignments = stmt.assignments.map do |name, expr|
      index = table.column_index(name) or raise SqlError, "no such column: #{name}"
      [index, binder.bind(expr)]
    end
    where = stmt.where && binder.bind(stmt.where)
    rows = table.rows.dup
    rows.each_index do |i|
      old = Expressions::Frame.new(rows[i], nil)
      next unless where.nil? || Values.truth(where.evaluate(old))
      values = rows[i].dup
      assignments.each { |index, expr| values[index] = expr.evaluate(old) }
      others = rows[0...i] + rows[i + 1..]
      rows[i] = table.store(values, others, inserting: false)
    end
    table.replace_rows(rows)
    []
  end

  def delete(stmt)
    table = @schema.target_table(stmt.table)
    where = stmt.where && target_binder(table).bind(stmt.where)
    table.replace_rows(table.rows.reject { |row| where.nil? || Values.truth(where.evaluate(Expressions::Frame.new(row, nil))) })
    []
  end

  # Names in UPDATE and DELETE: the target table is the one source, named by its table name (4.2).
  def target_binder(table)
    Binder.new(Scope.new.add(table.name, table.columns.map { |c| [c.name, c.type, c.collation] }), self)
  end

  # The column index each value of a row goes to.
  def insert_targets(table, stmt, width)
    if stmt.columns.nil?
      n = table.columns.length
      raise SqlError, "table #{stmt.table} has #{n} columns but #{width} values were supplied" unless width == n
      return (0...n).to_a
    end
    targets = stmt.columns.map do |name|
      table.column_index(name) or raise SqlError, "table #{stmt.table} has no column named #{name}"
    end
    raise SqlError, "#{width} values for #{targets.length} columns" unless width == targets.length
    targets
  end
end
