# frozen_string_literal: true

module Sql
  COLUMN_TYPES = %w[integer real text].freeze  # the type names a column or CAST may use

  # Expressions. The parser builds Literal/Column/Unary/Binary/Call; the Binder replaces Column by
  # ColumnRef and fills Call#fn.
  Literal = Data.define(:value)
  Column = Data.define(:table, :name)            # name as written; table is nil or as written
  ColumnRef = Data.define(:index, :type)         # resolved: position in the row, declared type
  Unary = Data.define(:op, :operand)             # :neg :plus :not
  Binary = Data.define(:op, :left, :right)       # :+ :- :* :/ :% :concat :eq :ne :lt :le :gt :ge :is :isnot :and :or
  # name as written. distinct/order_by/star only occur in aggregate-style calls: f(DISTINCT x), f(x ORDER BY y), count(*)
  Call = Data.define(:name, :args, :fn, :distinct, :order_by, :star) do
    def initialize(name:, args:, fn: nil, distinct: false, order_by: [], star: false) = super
  end
  AggRef = Data.define(:index, :name)            # bound: an aggregate's value, at this position of a group row; name as written
  Case = Data.define(:operand, :whens, :else_expr)  # operand nil for the searched form; whens: [[cond, result], ...]
  Between = Data.define(:expr, :low, :high, :negated)
  In = Data.define(:expr, :list, :negated)
  Like = Data.define(:expr, :pattern, :negated)
  Cast = Data.define(:expr, :type)               # type: :integer :real :text
  # Subqueries (4.3). `query` is a Select until the Binder replaces it by a planned Query; `outer_width`
  # (bound only) is how much of the enclosing row the subquery is given to resolve its outer columns.
  Subquery = Data.define(:query, :outer_width) do
    def initialize(query:, outer_width: nil) = super
  end
  InSubquery = Data.define(:expr, :query, :negated, :outer_width) do
    def initialize(expr:, query:, negated:, outer_width: nil) = super
  end
  Exists = Data.define(:query, :outer_width) do   # NOT EXISTS is NOT applied to this
    def initialize(query:, outer_width: nil) = super
  end
  # Bound only: an expression of an enclosing query's row (an alias), found `offset` values into this row.
  OuterExpr = Data.define(:expr, :offset)

  # Statements.
  Default = Data.define(:value)                  # DEFAULT v (a ColumnDef#default of nil means no DEFAULT)
  ColumnDef = Data.define(:name, :type, :primary_key, :not_null, :unique, :default)  # type: :integer :real :text
  TableConstraint = Data.define(:kind, :columns) # kind: :primary_key or :unique; columns as written
  CreateTable = Data.define(:name, :columns, :if_not_exists, :constraints)
  DropTable = Data.define(:name, :if_exists)
  # columns: nil or names; the rows come from `rows` (VALUES: arrays of expressions) or, when that is
  # nil, from `query` (5.4: a Select, Compound or WithQuery).
  Insert = Data.define(:table, :columns, :rows, :query)

  Update = Data.define(:table, :assignments, :where)  # assignments: [[column name, expr], ...]
  Delete = Data.define(:table, :where)

  # Stage 5 statements. Views, indexes, ALTER TABLE and transactions (5.3 - 5.7).
  CreateView = Data.define(:name, :columns, :select, :if_not_exists)  # columns: nil or names
  DropView = Data.define(:name, :if_exists)
  CreateIndex = Data.define(:name, :table, :columns, :unique, :if_not_exists)
  DropIndex = Data.define(:name, :if_exists)
  AlterAddColumn = Data.define(:table, :column)  # column: a ColumnDef
  AlterRenameTable = Data.define(:table, :new_name)
  AlterRenameColumn = Data.define(:table, :column, :new_name)
  Begin = Data.define
  Commit = Data.define
  Rollback = Data.define

  Star = Data.define
  TableStar = Data.define(:table)                # q.* ; table as written
  ResultColumn = Data.define(:expr, :alias)      # expr may be Star; alias is nil or the name as written
  OrderTerm = Data.define(:expr, :desc, :nulls)  # nulls: nil, :first or :last
  # FROM (4.1): `first` is the leftmost item, each JoinStep adds one more (joins associate to the left).
  TableRef = Data.define(:name, :alias)          # alias: nil or as written
  SubqueryRef = Data.define(:select, :alias)
  From = Data.define(:first, :joins)
  JoinStep = Data.define(:kind, :item, :on, :using)  # kind: :cross :inner :left; at most one of on / using
  Select = Data.define(:distinct, :columns, :from, :where, :group_by, :having, :order_by, :limit, :offset)  # from: nil or From; group_by: nil or exprs

  # Queries that are not a plain Select (5.1, 5.2). A "query" below is a Select, Compound or WithQuery.
  # Compound: `first` op `rest`...; rest is [[op, Select], ...] with op :union :union_all :intersect
  # :except; order_by/limit/offset apply to the whole result.
  Compound = Data.define(:first, :rest, :order_by, :limit, :offset)
  Cte = Data.define(:name, :columns, :select)    # columns: nil or names
  WithQuery = Data.define(:recursive, :ctes, :body)  # body: a Select or Compound

  # The sub-expressions of an expression node, bound or not.
  def self.children(node)
    case node
    when Unary then [node.operand]
    when Binary then [node.left, node.right]
    when Call then node.args + node.order_by.map(&:expr)
    when Case then [node.operand, *node.whens.flatten, node.else_expr].compact
    when Between then [node.expr, node.low, node.high]
    when In then [node.expr, *node.list]
    when Like then [node.expr, node.pattern]
    when Cast then [node.expr]
    when InSubquery then [node.expr]
    else []
    end
  end

  # The first node (depth first) in the expression for which the block is true, or nil.
  def self.find_node(node, &block)
    return node if block.call(node)
    children(node).each do |child|
      found = find_node(child, &block)
      return found if found
    end
    nil
  end
end
