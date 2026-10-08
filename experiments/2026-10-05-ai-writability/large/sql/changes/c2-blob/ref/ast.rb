# The syntax tree the parser builds. Names keep their spelling as written.
module AST
  # Expressions
  Literal = Struct.new(:value)                  # NULL, a number or a string
  Name = Struct.new(:name)                      # a column or an alias, resolved by Binder
  QualifiedName = Struct.new(:source, :name)    # source.name
  SourceColumn = Struct.new(:column)            # a Scope::Column itself (from expanding `*`)
  Paren = Struct.new(:expr)                     # ( expr ), kept because it passes on affinity
  Unary = Struct.new(:op, :operand)             # "-", "+", "NOT"
  Binary = Struct.new(:op, :left, :right)       # arithmetic, "||", comparisons, "IS", "IS NOT", "AND", "OR"
  # star: `name(*)`; distinct: `name(DISTINCT ...)`; order_by: OrderingTerms inside the parentheses;
  # over: nil, or for a window call (spec 6.1) a window's name or a WindowSpec.
  Call = Struct.new(:name, :args, :distinct, :order_by, :star, :over)
  Case = Struct.new(:base, :whens, :else_expr)  # base: nil for the searched form; whens: [[when, then]]
  Between = Struct.new(:expr, :low, :high, :negated)
  In = Struct.new(:expr, :list, :negated)
  Like = Struct.new(:expr, :pattern, :negated)
  Cast = Struct.new(:expr, :type)               # type: "INTEGER", "REAL", "TEXT" or "BLOB"
  Subquery = Struct.new(:select)                # ( select ), a scalar subquery
  Exists = Struct.new(:select)
  InSelect = Struct.new(:expr, :select, :negated) # expr [NOT] IN ( select )

  # Statements
  # default: the DEFAULT value, or NO_DEFAULT; constraints: written order, each :primary_key, :not_null
  # or :unique.
  NO_DEFAULT = Object.new.freeze
  ColumnDef = Struct.new(:name, :type, :constraints, :default)
  TableConstraint = Struct.new(:kind, :columns) # kind: :primary_key or :unique; columns: names
  CreateTable = Struct.new(:name, :if_not_exists, :columns, :constraints)
  DropTable = Struct.new(:name, :if_exists)
  # columns: nil or names; rows: lists of expressions, or nil when select (a query) gives the rows;
  # with: a With whose body is nil (`WITH ... INSERT`), or nil.
  Insert = Struct.new(:table, :columns, :rows, :select, :with)
  Update = Struct.new(:table, :assignments, :where) # assignments: [[column name, expression]]
  Delete = Struct.new(:table, :where)
  Star = Struct.new(:source)                    # "*" (source nil) or "source.*" in a result column list
  ResultColumn = Struct.new(:expr, :alias)
  OrderingTerm = Struct.new(:expr, :descending, :nulls_first)  # nulls_first: nil when not written
  # FROM (spec 4.1): the first source, then each join with the source it adds. kind: :inner (also
  # `,` and CROSS JOIN) or :left; on: an expression or nil; using: column names or nil.
  From = Struct.new(:first, :joins)
  Join = Struct.new(:kind, :source, :on, :using)
  TableSource = Struct.new(:table, :alias)
  SubquerySource = Struct.new(:select, :alias)  # alias: nil when not written
  # from: nil without FROM; group_by: expressions (empty without GROUP BY); having: nil without HAVING;
  # windows: the WINDOW clause, [[name, WindowSpec]] (empty without it).
  Select = Struct.new(:distinct, :columns, :from, :where, :group_by, :having, :order_by, :limit, :offset, :windows)

  # Windows (spec 6.1). base: a window's name or nil; partition_by: expressions; order_by:
  # OrderingTerms; frame: a FrameSpec or nil.
  WindowSpec = Struct.new(:base, :partition_by, :order_by, :frame)
  FrameSpec = Struct.new(:unit, :start, :end)    # unit: :rows or :range; start, end: FrameBounds
  # kind: :unbounded_preceding, :preceding, :current_row, :following or :unbounded_following;
  # offset: the expression n of `n PRECEDING` / `n FOLLOWING`, else nil.
  FrameBound = Struct.new(:kind, :offset)

  # Queries (spec 5.1, 5.2). A query is a Select, a Compound or a With.
  # parts: [[nil, first Select], [op, Select]...], op being "UNION", "UNION ALL", "INTERSECT" or
  # "EXCEPT"; the Selects have no ORDER BY or LIMIT of their own.
  Compound = Struct.new(:parts, :order_by, :limit, :offset)
  Cte = Struct.new(:name, :columns, :select)     # columns: nil or names
  With = Struct.new(:recursive, :ctes, :body)    # body: the query the ctes are visible in

  # Schema statements and transactions (spec 5.3, 5.5-5.7)
  CreateView = Struct.new(:name, :if_not_exists, :columns, :select)
  DropView = Struct.new(:name, :if_exists)
  CreateIndex = Struct.new(:name, :unique, :if_not_exists, :table, :columns)
  DropIndex = Struct.new(:name, :if_exists)
  Transaction = Struct.new(:action)              # :begin, :commit or :rollback
  AddColumn = Struct.new(:table, :column)        # column: a ColumnDef
  RenameTable = Struct.new(:table, :new_name)
  RenameColumn = Struct.new(:table, :column, :new_name)

  # Whether a query's FROM clauses (its subqueries' included) name the source `name`.
  def self.mentions?(node, name)
    case node
    when TableSource then node.table.casecmp?(name)
    when Struct then node.to_a.any? { |child| mentions?(child, name) }
    when Array then node.any? { |child| mentions?(child, name) }
    else false
    end
  end

  # A comparable form of an expression in which names differ only by spelling case: two expressions
  # with equal forms are the same expression.
  def self.normalize(node)
    case node
    when Name then [:name, node.name.downcase]
    when QualifiedName then [:qualified_name, node.source.downcase, node.name.downcase]
    when SourceColumn then [:source_column, node.column.index]
    when Struct then [node.class, *node.to_a.map { |child| normalize(child) }]
    when Array then node.map { |child| normalize(child) }
    else node
    end
  end
end
