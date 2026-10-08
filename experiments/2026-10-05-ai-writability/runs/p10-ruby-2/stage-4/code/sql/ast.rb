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
  Insert      = Data.define(:table, :columns, :rows) # columns nil or [names]; rows [[expr]]
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
