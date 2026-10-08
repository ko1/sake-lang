# The syntax tree the parser builds. Names keep their spelling as written.
module AST
  # Expressions
  Literal = Struct.new(:value)                  # NULL, a number or a string
  Name = Struct.new(:name)                      # a column or an alias, resolved by Binder
  Paren = Struct.new(:expr)                     # ( expr ), kept because it passes on affinity
  Unary = Struct.new(:op, :operand)             # "-", "+", "NOT"
  Binary = Struct.new(:op, :left, :right)       # arithmetic, "||", comparisons, "IS", "IS NOT", "AND", "OR"
  Call = Struct.new(:name, :args)

  # Statements
  ColumnDef = Struct.new(:name, :type)          # type: "INTEGER", "REAL" or "TEXT"
  CreateTable = Struct.new(:name, :if_not_exists, :columns)
  DropTable = Struct.new(:name, :if_exists)
  Insert = Struct.new(:table, :columns, :rows)  # columns: nil or names; rows: lists of expressions
  Star = Struct.new(:dummy)                     # "*" in a result column list
  ResultColumn = Struct.new(:expr, :alias)
  OrderingTerm = Struct.new(:expr, :descending, :nulls_first)  # nulls_first: nil when not written
  Select = Struct.new(:columns, :from, :where, :order_by, :limit, :offset)
end
