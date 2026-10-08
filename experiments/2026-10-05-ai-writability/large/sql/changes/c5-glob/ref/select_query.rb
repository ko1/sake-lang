require_relative "errors"
require_relative "ast"
require_relative "binder"
require_relative "aggregates"
require_relative "from_clause"
require_relative "query"

# A simple-select (spec 1.7, 3.3, 3.4, 4) bound: every name, aggregate and subquery-shape error is
# raised by `new`, before any row is read; `rows` runs it. A subquery (4.3) is a query (Query.build)
# whose `outer` is the Binder of the enclosing clause; it runs again for each enclosing row (the
# Frame given to `rows`).
#
# An aggregate query evaluates its result columns, HAVING and ORDER BY once per group, on the group's
# row: the values of the row bare columns take (Aggregates::Collector#compute) followed by the values
# of the query's aggregate calls (Expressions::AggregateRef).
#
# Window calls (6), allowed in the result columns and ORDER BY, are computed over the rows that WHERE,
# GROUP BY and HAVING leave (Windows::Collector#compute), before DISTINCT, ORDER BY and LIMIT.
class SelectQuery
  # A sort key: a result column (by index) or an expression on the row.
  SortKey = Struct.new(:result_index, :expr, :descending, :nulls_first)

  # column_names: each result column's name as a subquery source sees it (4.1: the alias, else the
  # column's name for a plain column reference, else nil); affinities: each result column's affinity.
  attr_reader :column_names, :affinities

  def initialize(stmt, catalog, outer = nil)
    @stmt = stmt
    @catalog = catalog
    @outer = outer
    @aliases = {}
    stmt.columns.each { |c| @aliases[c.alias.downcase] ||= c.expr if c.is_a?(AST::ResultColumn) && c.alias }
    @from = FromClause.new(stmt.from, catalog, outer) do |scope|
      # An aggregate call in ON is SQLite's `misuse of aggregate: f()` (the spec does not say).
      Binder.new(scope, catalog, aliases: @aliases, misuse: Binder::MISUSE_AGGREGATE, outer: outer)
    end
    @scope = @from.scope
    @result_asts = result_columns # [[alias or nil, syntax tree]]
    @aggregates = Aggregates::Collector.new(@scope.width)
    @windows = Windows::Collector.new(stmt.windows)
    # Result columns see the sources' columns only.
    @results = @result_asts.map { |_, ast| binder(aggregates: @aggregates, aliases: {}, windows: @windows).bind(ast) }
    @column_names = @result_asts.map { |name, ast| name || SelectQuery.column_name(ast) }
    @affinities = @results.map(&:affinity)
    @grouped = !stmt.group_by.empty? || !@aggregates.empty?
    raise SqlError, "HAVING clause on a non-aggregate query" if stmt.having && !@grouped
    @where = stmt.where && binder(misuse: Binder::MISUSE_FUNCTION, alias_misuse: Binder::MISUSE_AGGREGATE).bind(stmt.where)
    @group_by = stmt.group_by.each_with_index.map { |term, i| group_term(term, i) }
    @having = stmt.having && binder(aggregates: @aggregates).bind(stmt.having)
    @sort_keys = stmt.order_by.each_with_index.map { |term, i| sort_key(term, i) }
    @limit = stmt.limit && Query.integer_value(stmt.limit, catalog)
    @offset = stmt.offset ? Query.integer_value(stmt.offset, catalog) : 0
  end

  # The result rows; outer: the enclosing query's Frame for a subquery, else nil.
  def rows(outer = nil)
    source = @from.rows(outer).filter_map do |values|
      frame = Expressions::Frame.new(values, outer)
      frame if @where.nil? || Values.truth(@where.evaluate(frame))
    end
    frames = @grouped ? group_frames(source, outer) : source
    @windows.compute(frames) unless @windows.empty?
    output = frames.map do |frame|
      values = @results.map { |expr| expr.evaluate(frame) }
      [@sort_keys.map { |key| key.result_index ? values[key.result_index] : key.expr.evaluate(frame) }, values]
    end
    output.uniq! { |_, values| values.map { |value| Values.equality_key(value) } } if @stmt.distinct
    output.sort! { |a, b| compare_keys(a[0], b[0]) } unless @sort_keys.empty?
    Query.slice(output, @limit, @offset).map(&:last)
  end

  # The name a subquery source gives a result column without an alias.
  def self.column_name(ast)
    case ast
    when AST::Name, AST::QualifiedName then ast.name
    when AST::SourceColumn then ast.column.name
    end
  end

  private

  # [[alias or nil, syntax tree]] for every result column, `*` and `q.*` expanded (4.2).
  def result_columns
    @stmt.columns.flat_map do |column|
      next [[column.alias, column.expr]] unless column.is_a?(AST::Star)
      columns =
        if column.source
          source = @scope.source(column.source) or raise SqlError, "no such table: #{column.source}"
          source.columns
        else
          raise SqlError, "no tables specified" if @scope.sources.empty?
          @scope.star
        end
      columns.map { |c| [nil, AST::SourceColumn.new(c)] }
    end
  end

  # A binder for this query's clauses: the sources' columns, then result column aliases (unless
  # options say otherwise), then the enclosing query.
  def binder(**options)
    Binder.new(@scope, @catalog, **{ aliases: @aliases, outer: @outer }.merge(options))
  end

  # GROUP BY term: k means the k-th result column (3.3); aggregate calls are not allowed.
  def group_term(term, position)
    clause = binder(misuse: Binder::MISUSE_GROUP_BY)
    k = Query.ordinal(term) or return clause.bind(term)
    unless k.between?(1, @results.length)
      raise Query.out_of_range("GROUP BY", position, @results.length)
    end
    clause.bind(@result_asts[k - 1][1])
  end

  def sort_key(term, position)
    expr = term.expr
    index =
      if (k = Query.ordinal(expr))
        unless k.between?(1, @results.length)
          raise Query.out_of_range("ORDER BY", position, @results.length)
        end
        k - 1
      elsif expr.is_a?(AST::Name) && @aliases.key?(expr.name.downcase)
        @result_asts.index { |name, _| name && name.downcase == expr.name.downcase }
      end
    clause = @grouped ? binder(aggregates: @aggregates, windows: @windows) : binder(misuse: Binder::MISUSE_AGGREGATE, windows: @windows)
    bound = index ? nil : clause.bind(expr)
    SortKey.new(index, bound, term.descending, term.nulls_first)
  end

  # The frames of the groups that HAVING keeps, each the row the group's expressions evaluate on.
  # Without GROUP BY there is one group, even of no rows (its bare columns are NULL).
  def group_frames(source, outer)
    groups =
      if @group_by.empty? then [source]
      else source.group_by { |frame| @group_by.map { |expr| Values.equality_key(expr.evaluate(frame)) } }.values
      end
    groups.filter_map do |frames|
      values, chosen = @aggregates.compute(frames)
      frame = Expressions::Frame.new(((chosen || frames.first)&.values || Array.new(@scope.width)) + values, outer)
      frame if @having.nil? || Values.truth(@having.evaluate(frame))
    end
  end

  def compare_keys(a, b)
    @sort_keys.each_with_index do |key, i|
      c = Values.compare_ordered(a[i], b[i], key.descending, key.nulls_first)
      return c unless c.zero?
    end
    0
  end
end
