# frozen_string_literal: true

module Sql
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

  # Statements.
  Default = Data.define(:value)                  # DEFAULT v (a ColumnDef#default of nil means no DEFAULT)
  ColumnDef = Data.define(:name, :type, :primary_key, :not_null, :unique, :default)  # type: :integer :real :text
  TableConstraint = Data.define(:kind, :columns) # kind: :primary_key or :unique; columns as written
  CreateTable = Data.define(:name, :columns, :if_not_exists, :constraints)
  DropTable = Data.define(:name, :if_exists)
  Insert = Data.define(:table, :columns, :rows)  # columns: nil or names; rows: arrays of expressions

  Update = Data.define(:table, :assignments, :where)  # assignments: [[column name, expr], ...]
  Delete = Data.define(:table, :where)

  Star = Data.define
  ResultColumn = Data.define(:expr, :alias)      # expr may be Star; alias is nil or the name as written
  OrderTerm = Data.define(:expr, :desc, :nulls)  # nulls: nil, :first or :last
  Select = Data.define(:distinct, :columns, :table, :where, :group_by, :having, :order_by, :limit, :offset)  # group_by: nil or exprs

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
