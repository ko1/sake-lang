# frozen_string_literal: true

module SQL
  # Expressions. `value` of a Literal is nil/Integer/Float/String.
  Literal   = Data.define(:value)
  ColumnRef = Data.define(:table, :name)      # table is nil when unqualified
  Unary     = Data.define(:op, :operand)      # op: :neg :pos :not
  Binary    = Data.define(:op, :left, :right) # op: :add :sub :mul :div :mod :concat :eq :ne :lt :le :gt :ge :is :is_not :and :or
  # name as written; distinct / order_by (OrderTerms) only for aggregate calls; `count(*)` has args [Star]
  Call      = Data.define(:name, :args, :distinct, :order_by) do
    def initialize(name:, args:, distinct: false, order_by: [])
      super
    end
  end
  CaseExpr  = Data.define(:operand, :whens, :else_expr) # operand nil for the searched form; whens [[cond_or_value, result]]
  Between   = Data.define(:expr, :low, :high, :negated)
  InList    = Data.define(:expr, :items, :negated)
  Like      = Data.define(:expr, :pattern, :negated)
  Cast      = Data.define(:expr, :type)       # type: :integer :real :text
  # A column already resolved to its position in the row of its query (from `*` expansion).
  ResolvedColumn = Data.define(:index, :name, :affinity)

  # Subqueries in expressions (4.3); `select` is a Select.
  Subquery  = Data.define(:select)
  InSelect  = Data.define(:expr, :select, :negated)
  Exists    = Data.define(:select)

  # Statements.
  # type: :integer :real :text; default is a Ruby value (nil = NULL, also when absent).
  ColumnDef   = Data.define(:name, :type, :not_null, :primary_key, :unique, :default)
  TableConstraint = Data.define(:kind, :columns) # kind: :primary_key :unique; columns [names]
  CreateTable = Data.define(:name, :columns, :constraints, :if_not_exists)
  DropTable   = Data.define(:name, :if_exists)
  # columns nil or [names]; the source is `rows` ([[expr]], VALUES) or `query` (5.4), the other nil
  Insert      = Data.define(:table, :columns, :rows, :query)
  Update      = Data.define(:table, :assignments, :where) # assignments [[column, expr]]
  Delete      = Data.define(:table, :where)

  # `*` (table nil) or `table.*`
  Star         = Data.define(:table) do
    def initialize(table: nil) = super
  end
  ResultColumn = Data.define(:expr, :alias)   # alias nil or name
  OrderTerm    = Data.define(:expr, :desc, :nulls) # nulls: nil :first :last

  # FROM clause (4.1): a tree of Joins (left-associative) over table and subquery sources.
  TableSource    = Data.define(:name, :alias)
  SubquerySource = Data.define(:select, :alias)
  # kind: :cross :inner :left; constraint: `on` an expression, or `using` a list of names, or neither
  Join           = Data.define(:left, :right, :kind, :on, :using)

  # from: nil, a TableSource, a SubquerySource or a Join
  Select       = Data.define(:distinct, :items, :from, :where, :group_by, :having, :order_by, :limit, :offset)
end

module SQL
  # A query is a Select, a Compound or a WithClause around one of those (5.1, 5.2).
  # op: :union :union_all :intersect :except; left is a Select or a Compound (operators associate to
  # the left); order_by / limit / offset apply to the whole result.
  Compound   = Data.define(:op, :left, :right, :order_by, :limit, :offset)
  Cte        = Data.define(:name, :columns, :query) # columns nil or [names]
  # WITH ctes body: body is a Select or Compound, or an Insert for `WITH ... INSERT`.
  WithClause = Data.define(:recursive, :ctes, :body)

  # Views, indexes, schema changes, transactions (5.3 - 5.7).
  CreateView  = Data.define(:name, :columns, :query, :if_not_exists)
  DropView    = Data.define(:name, :if_exists)
  CreateIndex = Data.define(:name, :table, :columns, :unique, :if_not_exists)
  DropIndex   = Data.define(:name, :if_exists)
  AddColumn    = Data.define(:table, :column)            # column is a ColumnDef
  RenameTable  = Data.define(:table, :new_name)
  RenameColumn = Data.define(:table, :column, :new_name)
  Begin        = Data.define
  Commit       = Data.define
  Rollback     = Data.define
end
