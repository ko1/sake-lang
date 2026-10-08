module MiniSql
  # Expression nodes. The parser builds Literal, ColumnRef, Unary, Binary, Not, Is, Call, Case, Between, InList, Like
  # and Cast; the Binder turns names into BoundColumn / BoundCall and comparisons (including those
  # BETWEEN, IN and simple CASE stand for) into Compare.
  class Expr
    # The direct sub-expressions (used to look inside a bound expression).
    def children
      []
    end

    # The written name of an aggregate call inside this expression (itself included), or nil.
    def aggregate_name
      children.each do |child|
        name = child.aggregate_name
        return name if name
      end
      nil
    end
  end

  class Literal < Expr
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class ColumnRef < Expr
    attr_reader :qualifier, :name

    def initialize(qualifier, name)
      @qualifier = qualifier
      @name = name
    end

    # The name as the statement wrote it.
    def spelling
      qualifier = @qualifier
      qualifier ? "#{qualifier}.#{@name}" : @name
    end
  end

  # op is "-" or "+".
  class Unary < Expr
    attr_reader :op, :operand

    def initialize(op, operand)
      @op = op
      @operand = operand
    end

    def children
      [@operand]
    end
  end

  # op is one of + - * / % || = == != <> < <= > >= AND OR.
  class Binary < Expr
    attr_reader :op, :left, :right

    def initialize(op, left, right)
      @op = op
      @left = left
      @right = right
    end

    def children
      [@left, @right]
    end
  end

  class Not < Expr
    attr_reader :operand

    def initialize(operand)
      @operand = operand
    end

    def children
      [@operand]
    end
  end

  # `left IS [NOT] right`.
  class Is < Expr
    attr_reader :negated, :left, :right

    def initialize(negated, left, right)
      @negated = negated
      @left = left
      @right = right
    end

    def children
      [@left, @right]
    end
  end

  # `name(args)`, `name(*)` (star), `name(DISTINCT args)` and `name(args ORDER BY terms)`. The
  # signature is the call's tokens as written, which tells identical aggregate calls apart.
  class Call < Expr
    attr_reader :name, :args, :star, :distinct, :order_by, :signature

    def initialize(name, args, star, distinct, order_by, signature)
      @name = name
      @args = args
      @star = star
      @distinct = distinct
      @order_by = order_by
      @signature = signature
    end
  end

  # `CASE [operand] WHEN ... THEN ... [ELSE ...] END`; the Binder rewrites the simple form
  # (operand present) into the searched form (operand nil).
  class Case < Expr
    attr_reader :operand, :whens, :else_expr

    def initialize(operand, whens, else_expr)
      @operand = operand
      @whens = whens
      @else_expr = else_expr
    end

    def children
      parts = [] # @type var parts: Array[Expr]
      operand = @operand
      parts << operand if operand
      @whens.each do |clause|
        parts << clause.condition
        parts << clause.result
      end
      else_expr = @else_expr
      parts << else_expr if else_expr
      parts
    end
  end

  class WhenClause
    attr_reader :condition, :result

    def initialize(condition, result)
      @condition = condition
      @result = result
    end
  end

  # `operand [NOT] BETWEEN low AND high` (parsed form; the Binder rewrites it into comparisons).
  class Between < Expr
    attr_reader :negated, :operand, :low, :high

    def initialize(negated, operand, low, high)
      @negated = negated
      @operand = operand
      @low = low
      @high = high
    end
  end

  # `operand [NOT] IN (items)` (parsed form; the Binder rewrites it into equalities).
  class InList < Expr
    attr_reader :negated, :operand, :items

    def initialize(negated, operand, items)
      @negated = negated
      @operand = operand
      @items = items
    end
  end

  class Like < Expr
    attr_reader :negated, :operand, :pattern

    def initialize(negated, operand, pattern)
      @negated = negated
      @operand = operand
      @pattern = pattern
    end

    def children
      [@operand, @pattern]
    end
  end

  # type is :integer, :real or :text; the expression has that affinity.
  class Cast < Expr
    attr_reader :operand, :type

    def initialize(operand, type)
      @operand = operand
      @type = type
    end

    def children
      [@operand]
    end
  end

  # A column of the scanned row, by position, with the affinity of its declared type.
  class BoundColumn < Expr
    attr_reader :index, :affinity

    def initialize(index, affinity)
      @index = index
      @affinity = affinity
    end
  end

  # The result of an aggregate call, read from the group row: the aggregate results follow the
  # table's columns there (see AggregateScope). name is the call's name as written.
  class AggregateRef < Expr
    attr_reader :index, :name

    def initialize(index, name)
      @index = index
      @name = name
    end

    def aggregate_name
      @name
    end
  end

  # A function known to exist, called with a valid number of arguments; name is lower case.
  class BoundCall < Expr
    attr_reader :name, :args

    def initialize(name, args)
      @name = name
      @args = args
    end

    def children
      @args
    end
  end

  # A comparison with the affinities of its operands. op is = == != <> < <= > >= or IS / IS NOT.
  class Compare < Expr
    attr_reader :op, :left, :right, :left_affinity, :right_affinity

    def initialize(op, left, right, left_affinity, right_affinity)
      @op = op
      @left = left
      @right = right
      @left_affinity = left_affinity
      @right_affinity = right_affinity
    end

    def children
      [@left, @right]
    end
  end

  class Statement
  end

  # A column definition with its constraints; default is the DEFAULT value (NULL when absent).
  class ColumnDef
    attr_reader :name, :type, :primary_key, :not_null, :unique, :default

    def initialize(name, type, primary_key, not_null, unique, default)
      @name = name
      @type = type
      @primary_key = primary_key
      @not_null = not_null
      @unique = unique
      @default = default
    end
  end

  # `PRIMARY KEY (columns)` (kind :primary) or `UNIQUE (columns)` (kind :unique).
  class TableConstraint
    attr_reader :kind, :columns

    def initialize(kind, columns)
      @kind = kind
      @columns = columns
    end
  end

  class CreateTable < Statement
    attr_reader :name, :columns, :constraints, :if_not_exists

    def initialize(name, columns, constraints, if_not_exists)
      @name = name
      @columns = columns
      @constraints = constraints
      @if_not_exists = if_not_exists
    end
  end

  class DropTable < Statement
    attr_reader :name, :if_exists

    def initialize(name, if_exists)
      @name = name
      @if_exists = if_exists
    end
  end

  # columns is nil when no column list was given.
  class Insert < Statement
    attr_reader :table, :columns, :rows

    def initialize(table, columns, rows)
      @table = table
      @columns = columns
      @rows = rows
    end
  end

  class Assignment
    attr_reader :column, :expr

    def initialize(column, expr)
      @column = column
      @expr = expr
    end
  end

  class Update < Statement
    attr_reader :table, :assignments, :where

    def initialize(table, assignments, where)
      @table = table
      @assignments = assignments
      @where = where
    end
  end

  class Delete < Statement
    attr_reader :table, :where

    def initialize(table, where)
      @table = table
      @where = where
    end
  end

  # One result column; expr is nil for `*`.
  class ResultColumn
    attr_reader :expr, :alias_name

    def initialize(expr, alias_name)
      @expr = expr
      @alias_name = alias_name
    end
  end

  # nulls is :first, :last or nil (the direction's default).
  class OrderTerm
    attr_reader :expr, :descending, :nulls

    def initialize(expr, descending, nulls)
      @expr = expr
      @descending = descending
      @nulls = nulls
    end
  end

  # group_by is empty without GROUP BY; having is nil without HAVING.
  class Select < Statement
    attr_reader :distinct, :columns, :from, :where, :group_by, :having, :order_by, :limit, :offset

    def initialize(distinct, columns, from, where, group_by, having, order_by, limit, offset)
      @distinct = distinct
      @columns = columns
      @from = from
      @where = where
      @group_by = group_by
      @having = having
      @order_by = order_by
      @limit = limit
      @offset = offset
    end
  end
end
