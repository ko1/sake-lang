class QueryError < StandardError
end

class Query
  attr_accessor :columns, :table, :where, :group_by, :order_by, :desc, :limit

  def initialize(columns, table)
    @columns = columns
    @table = table
    @where = nil
    @group_by = nil
    @order_by = nil
    @desc = false
    @limit = nil
  end
end

class Cmp
  attr_reader :column, :op, :value

  def initialize(column, op, value)
    @column = column
    @op = op
    @value = value
  end
end

class Logic
  attr_reader :op, :left, :right

  def initialize(op, left, right)
    @op = op
    @left = left
    @right = right
  end
end

class Agg
  attr_reader :fn, :column

  def initialize(fn, column)
    @fn = fn
    @column = column
  end

  def label = "#{@fn}(#{@column})"
end

class Cursor
  def initialize(tokens)
    @tokens = tokens
    @pos = 0
  end

  def peek = @tokens[@pos]

  def next!
    t = @tokens[@pos]
    raise QueryError, "unexpected end of query" if t.nil?
    @pos += 1
    t
  end

  def keyword?(kw) = !peek.nil? && peek.upcase == kw

  def accept(kw)
    return false unless keyword?(kw)
    @pos += 1
    true
  end

  def expect(kw)
    raise QueryError, "expected #{kw} but got #{peek || "end"}" unless accept(kw)
  end
end

def tokenize(sql) = sql.scan(/'[^']*'|\d+|\w+|<=|>=|!=|[=<>,*()]/)

def literal(tok)
  return tok.to_i if tok.match?(/\A\d+\z/)
  return tok[1...-1] if tok.start_with?("'")
  raise QueryError, "expected a literal, got #{tok}"
end

def parse_column(c)
  name = c.next!
  up = name.upcase
  if %w[COUNT SUM AVG MAX].include?(up) && c.accept("(")
    arg = c.next!
    c.expect(")")
    return Agg.new(up.downcase, arg)
  end
  name
end

def parse_condition(c)
  left = parse_comparison(c)
  while c.keyword?("AND") || c.keyword?("OR")
    op = c.next!.upcase
    left = Logic.new(op, left, parse_comparison(c))
  end
  left
end

def parse_comparison(c)
  col = c.next!
  op = c.next!
  raise QueryError, "bad operator #{op}" unless %w[= != < > <= >=].include?(op)
  Cmp.new(col, op, literal(c.next!))
end

def parse_query(sql)
  c = Cursor.new(tokenize(sql))
  c.expect("SELECT")
  columns = [parse_column(c)]
  columns << parse_column(c) while c.accept(",")
  c.expect("FROM")
  q = Query.new(columns, c.next!)
  q.where = parse_condition(c) if c.accept("WHERE")
  if c.accept("GROUP")
    c.expect("BY")
    q.group_by = c.next!
  end
  if c.accept("ORDER")
    c.expect("BY")
    q.order_by = c.next!
    q.desc = true if c.accept("DESC")
    c.accept("ASC")
  end
  q.limit = literal(c.next!) if c.accept("LIMIT")
  raise QueryError, "unexpected #{c.peek}" if c.peek
  q
end

def field(row, col)
  raise QueryError, "no such column: #{col}" unless row.key?(col)
  row[col]
end

def matches?(cond, row)
  case cond
  when nil then true
  when Logic
    l = matches?(cond.left, row)
    cond.op == "AND" ? l && matches?(cond.right, row) : l || matches?(cond.right, row)
  when Cmp
    a = field(row, cond.column)
    b = cond.value
    raise QueryError, "type mismatch on #{cond.column}" unless a.is_a?(Integer) == b.is_a?(Integer)
    case cond.op
    when "=" then a == b
    when "!=" then a != b
    else a.public_send(cond.op, b)
    end
  end
end

def label(col) = col.is_a?(Agg) ? col.label : col

def aggregate(agg, rows)
  return rows.size if agg.fn == "count"
  values = rows.map { |r| field(r, agg.column) }
  raise QueryError, "#{agg.fn} needs numbers" unless values.all?(Integer)
  case agg.fn
  when "sum" then values.sum
  when "max" then values.max
  when "avg" then values.empty? ? 0 : (values.sum / values.size.to_f).round(2)
  end
end

def execute(q, tables)
  rows = tables[q.table]
  raise QueryError, "no such table: #{q.table}" if rows.nil?
  rows = rows.select { |r| matches?(q.where, r) }
  columns = q.columns
  order = q.order_by
  if q.group_by || columns.any?(Agg)
    groups = q.group_by.nil? ? { "all" => rows } : rows.group_by { |r| field(r, q.group_by) }
    result = groups.map do |_key, members|
      columns.to_h { |col| [label(col), col.is_a?(Agg) ? aggregate(col, members) : field(members.first, col)] }
    end
    if order
      raise QueryError, "cannot order by #{order}" unless result.all? { |r| r.key?(order) }
      result = result.sort_by { |r| r[order] }
    end
  else
    rows = rows.sort_by { |r| field(r, order) } if order
    result = rows.map do |r|
      columns.to_h { |col| [label(col), col == "*" ? r : field(r, col)] }
    end
  end
  result = result.reverse if q.desc
  q.limit.nil? ? result : result.take(q.limit)
end

def format_row(r)
  r.map { |k, v| v.is_a?(Hash) ? v.map { |k2, v2| "#{k2}=#{v2}" }.join(" ") : "#{k}=#{v}" }.join(", ")
end

TABLES = {
  "people" => [
    { "name" => "ann", "age" => 34, "city" => "Tokyo", "salary" => 610 },
    { "name" => "bob", "age" => 27, "city" => "Osaka", "salary" => 480 },
    { "name" => "cy", "age" => 45, "city" => "Tokyo", "salary" => 720 },
    { "name" => "dee", "age" => 31, "city" => "Kyoto", "salary" => 530 },
    { "name" => "eve", "age" => 22, "city" => "Osaka", "salary" => 350 },
    { "name" => "fay", "age" => 39, "city" => "Tokyo", "salary" => 655 }
  ]
}.freeze

queries = [
  "SELECT name, age FROM people WHERE age > 30 ORDER BY age DESC",
  "select name from people where city = 'Tokyo' and salary >= 650 or name = 'eve'",
  "SELECT city, COUNT(*), AVG(salary), MAX(age) FROM people GROUP BY city ORDER BY city",
  "SELECT SUM(salary) FROM people WHERE city != 'Osaka'",
  "SELECT * FROM people WHERE age < 30 ORDER BY name LIMIT 1",
  "SELECT city, COUNT(*) FROM people GROUP BY city ORDER BY age",
  "SELECT name FROM people ORDER BY salary LIMIT 3",
  "SELECT name FROM people WHERE age > 'old'",
  "SELECT name FROM pets",
  "SELECT height FROM people",
  "SELECT name people",
  "SELECT name FROM people WHERE age ~ 3",
  "SELECT AVG(city) FROM people"
]
queries.each do |sql|
  puts "sql> #{sql}"
  begin
    rows = execute(parse_query(sql), TABLES)
    rows.each { |r| puts "  #{format_row(r)}" }
    puts "  (#{rows.size} rows)"
  rescue QueryError => e
    puts "  error: #{e.message}"
  end
end
