require_relative "errors"
require_relative "ast"
require_relative "binder"
require_relative "catalog"

# Queries (spec 5.1, 5.2) bound: a SelectQuery, a CompoundQuery, or the body of a With seen through
# its ctes. Every query answers column_names, affinities, collations and rows(outer), outer being the
# Frame of the enclosing query's row (nil at the top), which is what a relation (FromClause) answers
# too. A query also answers result_collations: each result column's collation (Collation::Of or nil,
# 7.3); collations are the names a source's columns have from them (7.5).
module Query
  module_function

  # The bound query for a query's syntax tree; catalog: the named sources it sees; outer: the Binder
  # of the enclosing clause, or nil.
  def build(ast, catalog, outer = nil)
    case ast
    when AST::Select then SelectQuery.new(ast, catalog, outer)
    when AST::Compound then CompoundQuery.new(ast, catalog, outer)
    when AST::With then build(ast.body, Catalog.with(ast, catalog, outer), outer)
    else raise ArgumentError, "unknown query #{ast.inspect}"
    end
  end

  # [the term without a COLLATE written on it, that collation's canonical name or nil] (7.4).
  def split_collate(expr)
    return [expr, nil] unless expr.is_a?(AST::Collate)
    [expr.expr, Collation.lookup(expr.collation)]
  end

  # The names of the collations of a source's columns made from result collations (7.5).
  def source_collations(result_collations)
    result_collations.map { |c| c ? c.name : Collation::BINARY }
  end

  # k when the term is an integer literal k or `-` applied to one, else nil (1.7).
  def ordinal(expr)
    return expr.value if expr.is_a?(AST::Literal) && expr.value.is_a?(Integer)
    if expr.is_a?(AST::Unary) && expr.op == "-" && expr.operand.is_a?(AST::Literal) && expr.operand.value.is_a?(Integer)
      return -expr.operand.value
    end
    nil
  end

  def nth(n)
    suffix = (11..13).include?(n % 100) ? "th" : { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(n % 10, "th")
    "#{n}#{suffix}"
  end

  def out_of_range(clause, position, n)
    SqlError.new("#{nth(position + 1)} #{clause} term out of range - should be between 1 and #{n}")
  end

  # LIMIT and OFFSET: evaluated with no row in scope, read as integers.
  def integer_value(expr, catalog)
    value = Binder.bind(expr, catalog).evaluate(Expressions::EMPTY_FRAME)
    Values.to_number(value || 0).to_i
  end

  # A hash key under which rows equal (3.4) under the columns' collations (names) coincide.
  def row_key(values, collations) = values.zip(collations).map { |value, c| Values.equality_key(value, c) }

  # The ORDER BY of a compound select (5.1) as [column index, descending, nulls_first, collation] per
  # term: an integer k, or a name that is the alias or column name of a result column of some part
  # (name_lists: each part's column names, first part first), optionally followed by COLLATE n; it
  # sorts under n, else the column's collation (collations: names, 7.4).
  def compound_order(order_by, name_lists, collations)
    width = name_lists[0].length
    order_by.each_with_index.map do |term, position|
      expr, collation = split_collate(term.expr)
      index =
        if (k = ordinal(expr))
          raise out_of_range("ORDER BY", position, width) unless k.between?(1, width)
          k - 1
        elsif expr.is_a?(AST::Name)
          name_lists.lazy.filter_map { |names| names.index { |name| name&.casecmp?(expr.name) } }.first
        end
      index or raise SqlError, "#{nth(position + 1)} ORDER BY term does not match any column in the result set"
      [index, term.descending, term.nulls_first, collation || collations[index]]
    end
  end

  # The collation of each column of a compound whose parts have these result collations, first part
  # first: the first part's, left to right, that has one (7.4).
  def compound_collations(part_collations)
    part_collations[0].each_index.map { |k| part_collations.lazy.map { |cs| cs[k] }.find(&:itself) }
  end

  # rows sorted by such terms (stable).
  def sort_rows(rows, order)
    return rows if order.empty?
    rows.each_with_index.sort do |(a, i), (b, j)|
      c = 0
      order.each do |index, descending, nulls_first, collation|
        c = Values.compare_ordered(a[index], b[index], descending, nulls_first, collation)
        break unless c.zero?
      end
      c.zero? ? i <=> j : c
    end.map(&:first)
  end

  # OFFSET then LIMIT (1.7): a negative LIMIT is no limit, a negative OFFSET is 0.
  def slice(rows, limit, offset)
    rows = rows.drop([offset, 0].max)
    limit && limit >= 0 ? rows.take(limit) : rows
  end
end

# simple-select compound-op simple-select ... [ORDER BY] [LIMIT] (5.1). The parts are bound left to
# right; their column counts must agree. The result's column names and affinities are the first
# part's (tests do not depend on a compound's affinity); its collations follow 7.4, and rows are
# compared under them.
class CompoundQuery
  attr_reader :column_names, :affinities, :result_collations, :collations

  def initialize(ast, catalog, outer)
    @parts = []
    ast.parts.each do |op, select|
      query = SelectQuery.new(select, catalog, outer)
      if op && query.column_names.length != @parts[0][1].column_names.length
        raise SqlError, "SELECTs to the left and right of #{op} do not have the same number of result columns"
      end
      @parts << [op, query]
    end
    @column_names = @parts[0][1].column_names
    @affinities = @parts[0][1].affinities
    @result_collations = Query.compound_collations(@parts.map { |_, query| query.result_collations })
    @collations = Query.source_collations(@result_collations)
    @order = Query.compound_order(ast.order_by, @parts.map { |_, query| query.column_names }, @collations)
    @limit = ast.limit && Query.integer_value(ast.limit, catalog)
    @offset = ast.offset ? Query.integer_value(ast.offset, catalog) : 0
  end

  def rows(outer = nil)
    result = @parts.reduce(nil) do |left, (op, query)|
      right = query.rows(outer)
      left.nil? ? right : CompoundQuery.combine(op, left, right, @collations)
    end
    Query.slice(Query.sort_rows(result, @order), @limit, @offset)
  end

  def self.combine(op, left, right, collations)
    key = ->(row) { Query.row_key(row, collations) }
    case op
    when "UNION ALL" then left + right
    when "UNION" then (left + right).uniq(&key)
    when "INTERSECT", "EXCEPT"
      keys = right.to_h { |row| [key.(row), true] }
      keep = op == "INTERSECT"
      left.uniq(&key).select { |row| keys.key?(key.(row)) == keep }
    end
  end
end

# A cte of WITH RECURSIVE whose select mentions it (5.2): `initial UNION [ALL] recursive`, computed
# with a queue. While `recursive` runs, the cte's name stands for the one row taken from the queue
# (a Working relation). An ORDER BY of the cte's select picks the next row from the queue by its
# terms and a LIMIT stops the computation, as in SQLite (the spec does not cover them). Its columns'
# collations are those of the compound its select is (7.4).
class RecursiveQuery
  # The cte's name inside its recursive part: the current row.
  class Working
    attr_reader :column_names, :affinities, :collations
    attr_accessor :current

    def initialize(column_names, affinities, collations)
      @column_names = column_names
      @affinities = affinities
      @collations = collations
      @current = []
    end

    def bind(_outer) = self
    def rows(_outer = nil) = @current
  end

  attr_reader :column_names, :affinities, :collations

  # cte: the AST::Cte; catalog: the sources its select sees (without itself).
  def initialize(cte, catalog, outer)
    body = cte.select
    unless body.is_a?(AST::Compound) && ["UNION", "UNION ALL"].include?(body.parts.last[0]) &&
           !AST.mentions?(body.parts[0...-1], cte.name)
      raise SqlError, "circular reference: #{cte.name}"
    end
    *initial_parts, (op, step) = body.parts
    initial_ast = initial_parts.length == 1 ? initial_parts[0][1] : AST::Compound.new(initial_parts, [], nil, nil)
    @initial = Query.build(initial_ast, catalog, outer)
    @column_names = Catalog.column_names(cte, @initial)
    @affinities = @initial.affinities
    @distinct = op == "UNION"
    # The step's own collations are not known before it is bound, which needs the working relation.
    @working = Working.new(@column_names, @affinities, Query.source_collations(@initial.result_collations))
    @step = SelectQuery.new(step, Catalog.new(catalog, cte.name => @working), outer)
    unless @step.column_names.length == @column_names.length
      raise SqlError, "SELECTs to the left and right of #{op} do not have the same number of result columns"
    end
    @collations = Query.source_collations(Query.compound_collations([@initial.result_collations, @step.result_collations]))
    @order = Query.compound_order(body.order_by, [@column_names], @collations)
    @limit = body.limit && Query.integer_value(body.limit, catalog)
    @offset = body.offset ? Query.integer_value(body.offset, catalog) : 0
  end

  def rows(outer = nil)
    queue = []
    seen = {}
    enqueue = lambda do |rows|
      rows.each do |row|
        next if @distinct && seen.key?(key = Query.row_key(row, @collations))
        seen[key] = true if @distinct
        queue << row
      end
    end
    enqueue.(@initial.rows(outer))
    result = []
    wanted = @limit && @limit >= 0 ? [@offset, 0].max + @limit : nil
    until queue.empty? || (wanted && result.length >= wanted)
      row = queue.delete_at(next_index(queue))
      result << row
      @working.current = [row]
      enqueue.(@step.rows(outer))
    end
    Query.slice(result, nil, @offset)
  end

  private

  # The queue's first row, or with ORDER BY the first of its smallest rows.
  def next_index(queue)
    return 0 if @order.empty?
    Query.sort_rows(queue.each_with_index.map { |row, i| row + [i] }, @order).first.last
  end
end
