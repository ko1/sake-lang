require_relative "errors"
require_relative "ast"
require_relative "table"
require_relative "binder"

# The in-memory database and the execution of statements. `execute` returns the result rows (empty
# for statements other than SELECT) or raises SqlError, in which case the database is unchanged.
class Database
  def initialize
    @tables = {} # name (downcased) => Table
  end

  def execute(statement)
    case statement
    when AST::CreateTable then create_table(statement)
    when AST::DropTable then drop_table(statement)
    when AST::Insert then insert(statement)
    when AST::Select then select(statement)
    else raise ArgumentError, "unknown statement #{statement.inspect}"
    end
  end

  private

  def table!(name)
    @tables[name.downcase] or raise SqlError, "no such table: #{name}"
  end

  def create_table(stmt)
    if @tables.key?(stmt.name.downcase)
      return [] if stmt.if_not_exists
      raise SqlError, "table #{stmt.name} already exists"
    end
    seen = {}
    columns = stmt.columns.map do |c|
      raise SqlError, "duplicate column name: #{c.name}" if seen[c.name.downcase]
      seen[c.name.downcase] = true
      Table::Column.new(c.name, c.type)
    end
    @tables[stmt.name.downcase] = Table.new(stmt.name, columns)
    []
  end

  def drop_table(stmt)
    unless @tables.key?(stmt.name.downcase)
      return [] if stmt.if_exists
      raise SqlError, "no such table: #{stmt.name}"
    end
    @tables.delete(stmt.name.downcase)
    []
  end

  # Every row is converted before any is stored, so a failing row leaves the table unchanged.
  def insert(stmt)
    table = table!(stmt.table)
    width = stmt.rows.first.length
    unless stmt.rows.all? { |values| values.length == width }
      raise SqlError, "all VALUES must have the same number of terms"
    end
    targets = insert_targets(table, stmt, width)
    new_rows = stmt.rows.map do |values|
      row = Array.new(table.columns.length)
      # A column listed twice takes its first value, as in SQLite (the spec does not say).
      values.zip(targets).reverse_each do |expr, index|
        value = Binder.bind(expr, Binder::Scope.empty).evaluate([])
        row[index] = table.convert(value, table.columns[index])
      end
      row
    end
    table.rows.concat(new_rows)
    []
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

  # --- SELECT (spec 1.7)

  # A sort key: a result column (by index) or an expression on the table row.
  SortKey = Struct.new(:result_index, :expr, :descending, :nulls_first)

  def select(stmt)
    table = stmt.from && table!(stmt.from)
    columns = table ? table.columns : []
    row_scope = Binder::Scope.new(columns, {})
    results = result_columns(stmt, table, row_scope)
    aliases = {}
    results.each { |name, expr| aliases[name.downcase] ||= expr if name }
    alias_scope = Binder::Scope.new(columns, aliases)
    where = stmt.where && Binder.bind(stmt.where, alias_scope)
    sort_keys = stmt.order_by.each_with_index.map do |term, i|
      sort_key(term, i, results, aliases, alias_scope)
    end
    limit = stmt.limit && integer_value(stmt.limit)
    offset = stmt.offset ? [integer_value(stmt.offset), 0].max : 0

    source_rows = table ? table.rows : [[]]
    output = []
    source_rows.each do |row|
      next unless where.nil? || Values.truth(where.evaluate(row))
      values = results.map { |_, expr| expr.evaluate(row) }
      keys = sort_keys.map { |key| key.result_index ? values[key.result_index] : key.expr.evaluate(row) }
      output << [keys, values]
    end
    output.sort! { |a, b| compare_keys(a[0], b[0], sort_keys) } unless sort_keys.empty?
    output = output.drop(offset)
    output = output.take(limit) if limit && limit >= 0
    output.map(&:last)
  end

  # [[alias or nil, bound expression]] for every result column, `*` expanded.
  def result_columns(stmt, table, scope)
    stmt.columns.flat_map do |column|
      if column.is_a?(AST::Star)
        raise SqlError, "no tables specified" unless table
        table.columns.each_with_index.map { |c, i| [nil, Expressions::ColumnRef.new(i, c.type)] }
      else
        [[column.alias, Binder.bind(column.expr, scope)]]
      end
    end
  end

  def sort_key(term, position, results, aliases, scope)
    expr = term.expr
    index =
      if (k = ordinal(expr))
        unless k.between?(1, results.length)
          raise SqlError, "#{Database.nth(position + 1)} ORDER BY term out of range - should be between 1 and #{results.length}"
        end
        k - 1
      elsif expr.is_a?(AST::Name) && aliases.key?(expr.name.downcase)
        results.index { |name, _| name && name.downcase == expr.name.downcase }
      end
    bound = index ? nil : Binder.bind(expr, scope)
    SortKey.new(index, bound, term.descending, term.nulls_first)
  end

  # k when the term is an integer literal k or `-` applied to one, else nil.
  def ordinal(expr)
    return expr.value if expr.is_a?(AST::Literal) && expr.value.is_a?(Integer)
    if expr.is_a?(AST::Unary) && expr.op == "-" && expr.operand.is_a?(AST::Literal) && expr.operand.value.is_a?(Integer)
      return -expr.operand.value
    end
    nil
  end

  def self.nth(n)
    suffix = (11..13).include?(n % 100) ? "th" : { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(n % 10, "th")
    "#{n}#{suffix}"
  end

  def compare_keys(a, b, sort_keys)
    sort_keys.each_with_index do |key, i|
      x = a[i]
      y = b[i]
      c =
        if x.nil? || y.nil?
          nulls_first = key.nulls_first.nil? ? !key.descending : key.nulls_first
          ((x.nil? ? 0 : 1) <=> (y.nil? ? 0 : 1)) * (nulls_first ? 1 : -1)
        else
          Values.compare(x, y) * (key.descending ? -1 : 1)
        end
      return c unless c.zero?
    end
    0
  end

  # LIMIT and OFFSET: evaluated with no row in scope, read as integers.
  def integer_value(expr)
    value = Binder.bind(expr, Binder::Scope.empty).evaluate([])
    Values.to_number(value || 0).to_i
  end
end
