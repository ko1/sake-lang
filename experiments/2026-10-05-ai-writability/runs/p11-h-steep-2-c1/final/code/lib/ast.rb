module MiniSql
  # Expression nodes. The parser builds Literal, ColumnRef, Unary, Binary, Not, Is, Call, Case, Between, InList, Like
  # and Cast; the Binder turns names into BoundColumn / BoundCall and comparisons (including those
  # BETWEEN, IN and simple CASE stand for) into Compare.
  class Expr
    # The direct sub-expressions (used to look inside a bound expression).
    def children
      []
    end

    # The affinity (SPEC 1.9) comparisons give this expression, or nil.
    def affinity
      nil
    end

    # The collation a COLLATE on this expression names (SPEC 7.3), or nil.
    def explicit_collation
      nil
    end

    # The collation this expression takes from the column it reads, or nil.
    def implicit_collation
      nil
    end

    # The explicit collation, else the implicit one; nil when the expression has none.
    def own_collation
      explicit_collation || implicit_collation
    end

    # The collation under which the values of this expression are compared among themselves (SPEC 7.4).
    def value_collation
      own_collation || :binary
    end

    # The written name of an aggregate call inside this expression (itself included), or nil.
    def aggregate_name
      children.each do |child|
        name = child.aggregate_name
        return name if name
      end
      nil
    end

    # The written name of a window call inside this expression (itself included), or nil.
    def window_name
      children.each do |child|
        name = child.window_name
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

  # op is "-" or "+"; `+e` has the collation of e, `-e` has none.
  class Unary < Expr
    attr_reader :op, :operand

    def initialize(op, operand)
      @op = op
      @operand = operand
    end

    def explicit_collation
      @op == "+" ? @operand.explicit_collation : nil
    end

    def implicit_collation
      @op == "+" ? @operand.implicit_collation : nil
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

  # `name(args)`, `name(*)` (star), `name(DISTINCT args)` and `name(args ORDER BY terms)`, with `OVER ...`
  # (over) when it is a window call. The signature is the call's tokens as written (without OVER), which
  # tells identical aggregate calls apart.
  class Call < Expr
    attr_reader :name, :args, :star, :distinct, :order_by, :signature, :over

    def initialize(name, args, star, distinct, order_by, signature, over)
      @name = name
      @args = args
      @star = star
      @distinct = distinct
      @order_by = order_by
      @signature = signature
      @over = over
    end
  end

  # One end of a window frame (SPEC 6.1). kind is :unbounded_preceding, :preceding, :current, :following or
  # :unbounded_following; offset is the n of `n PRECEDING` / `n FOLLOWING` (nil for the other kinds).
  class FrameBound
    attr_reader :kind, :offset

    def initialize(kind, offset)
      @kind = kind
      @offset = offset
    end

    def offset?
      @kind == :preceding || @kind == :following
    end

    def amount
      @offset || 0
    end
  end

  # `ROWS` or `RANGE` (mode :rows / :range) with the first and last bound of the frame.
  class FrameSpec
    attr_reader :mode, :start, :finish

    def initialize(mode, start, finish)
      @mode = mode
      @start = start
      @finish = finish
    end
  end

  # What `OVER ( ... )` and `WINDOW name AS ( ... )` hold: the name of a base window (nil: none), the PARTITION BY
  # terms, the ORDER BY terms and the frame (nil: not written).
  class WindowSpec
    attr_reader :base, :partition_by, :order_by, :frame

    def initialize(base, partition_by, order_by, frame)
      @base = base
      @partition_by = partition_by
      @order_by = order_by
      @frame = frame
    end
  end

  # `name AS ( window-spec )` of a WINDOW clause.
  class NamedWindow
    attr_reader :name, :spec

    def initialize(name, spec)
      @name = name
      @spec = spec
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

  # `operand COLLATE name` (parsed form; the Binder turns it into a BoundCollate). name is as written.
  class CollateExpr < Expr
    attr_reader :operand, :name

    def initialize(operand, name)
      @operand = operand
      @name = name
    end

    def children
      [@operand]
    end
  end

  # `operand COLLATE name` after name resolution: the value and affinity of the operand, with an explicit collation.
  class BoundCollate < Expr
    attr_reader :operand, :collation

    def initialize(operand, collation)
      @operand = operand
      @collation = collation
    end

    def affinity
      @operand.affinity
    end

    def explicit_collation
      @collation
    end

    def children
      [@operand]
    end
  end

  # type is :integer, :real or :text; the expression has that affinity and the collation of the operand.
  class Cast < Expr
    attr_reader :operand, :type

    def initialize(operand, type)
      @operand = operand
      @type = type
    end

    def explicit_collation
      @operand.explicit_collation
    end

    def implicit_collation
      @operand.implicit_collation
    end

    def affinity
      @type
    end

    def children
      [@operand]
    end
  end

  # `( select )` used as a value (parsed form; the Binder plans it into a BoundScalar).
  class ScalarSelect < Expr
    attr_reader :select

    def initialize(select)
      @select = select
    end
  end

  # `[NOT] EXISTS ( select )`: NOT is the prefix operator, so this is the EXISTS part only.
  class ExistsSelect < Expr
    attr_reader :select

    def initialize(select)
      @select = select
    end
  end

  # `operand [NOT] IN ( select )` (parsed form).
  class InSelect < Expr
    attr_reader :negated, :operand, :select

    def initialize(negated, operand, select)
      @negated = negated
      @operand = operand
      @select = select
    end
  end

  # A column of the scanned row, by position, with the affinity of its declared type (nil: none) and its
  # collation (an implicit one, :binary when it declares none).
  class BoundColumn < Expr
    attr_reader :index, :affinity, :collation

    def initialize(index, affinity, collation)
      @index = index
      @affinity = affinity
      @collation = collation
    end

    def implicit_collation
      @collation
    end
  end

  # An expression of an enclosing query, evaluated on that query's current row (frame).
  class OuterRef < Expr
    attr_reader :frame, :inner

    def initialize(frame, inner)
      @frame = frame
      @inner = inner
    end

    def affinity
      @inner.affinity
    end

    def explicit_collation
      @inner.explicit_collation
    end

    def implicit_collation
      @inner.implicit_collation
    end
  end

  # The result of a window call, read from the row extended with the window results (see WindowScope);
  # name is the call's name as written.
  class WindowRef < Expr
    attr_reader :name

    def initialize(scope, position, name)
      @scope = scope
      @position = position
      @name = name
    end

    def index
      @scope.base + @position
    end

    def window_name
      @name
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

  # A comparison with the affinities of its operands and the collation its TEXT operands compare under
  # (SPEC 7.4). op is = == != <> < <= > >= or IS / IS NOT.
  class Compare < Expr
    attr_reader :op, :left, :right, :left_affinity, :right_affinity, :collation

    def initialize(op, left, right, left_affinity, right_affinity, collation)
      @op = op
      @left = left
      @right = right
      @left_affinity = left_affinity
      @right_affinity = right_affinity
      @collation = collation
    end

    def children
      [@left, @right]
    end
  end

  class Statement
  end

  # A column definition with its constraints; default is the DEFAULT value (NULL when absent); collation is the
  # name after COLLATE as written (nil when absent).
  class ColumnDef
    attr_reader :name, :type, :primary_key, :not_null, :unique, :default, :collation

    def initialize(name, type, primary_key, not_null, unique, default, collation)
      @name = name
      @type = type
      @primary_key = primary_key
      @not_null = not_null
      @unique = unique
      @default = default
      @collation = collation
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

  # columns is nil when no column list was given; source is a ValuesList or a select; with is nil without WITH.
  class Insert < Statement
    attr_reader :table, :columns, :source, :with

    def initialize(table, columns, source, with)
      @table = table
      @columns = columns
      @source = source
      @with = with
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

  # One result column; expr is nil for `*` and `q.*` (star_qualifier is the q of `q.*`, else nil).
  class ResultColumn
    attr_reader :expr, :alias_name, :star_qualifier

    def initialize(expr, alias_name, star_qualifier)
      @expr = expr
      @alias_name = alias_name
      @star_qualifier = star_qualifier
    end
  end

  class FromItem
  end

  # `table [[AS] alias]`.
  class TableRef < FromItem
    attr_reader :name, :alias_name

    def initialize(name, alias_name)
      @name = name
      @alias_name = alias_name
    end
  end

  # `( select ) [[AS] alias]`.
  class SubqueryRef < FromItem
    attr_reader :select, :alias_name

    def initialize(select, alias_name)
      @select = select
      @alias_name = alias_name
    end
  end

  # `, item`, `JOIN item ...` and so on. kind is :inner (also `,` and CROSS JOIN) or :left; at most one of
  # on / using is set, and neither means every pair joins.
  class JoinClause
    attr_reader :kind, :item, :on, :using

    def initialize(kind, item, on, using)
      @kind = kind
      @item = item
      @on = on
      @using = using
    end
  end

  # The FROM clause: the first item, then joins that associate to the left.
  class FromClause
    attr_reader :first, :joins

    def initialize(first, joins)
      @first = first
      @joins = joins
    end

    # Whether some item of this FROM (not inside a subquery) is the table `name` (case-insensitive).
    def mentions_table?(name)
      items = [@first] + @joins.map(&:item)
      items.any? { |item| item.is_a?(TableRef) && item.name.downcase(:ascii) == name.downcase(:ascii) }
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

  # Any select: a simple Select, a CompoundSelect or a WithSelect.
  class SelectNode < Statement
  end

  # A simple select. from is nil without FROM; group_by is empty without GROUP BY; having is nil without
  # HAVING; windows is empty without WINDOW. order_by / limit / offset are empty / nil on an arm of a compound select, which keeps them itself.
  class Select < SelectNode
    attr_reader :distinct, :columns, :from, :where, :group_by, :having, :windows, :order_by, :limit, :offset

    def initialize(distinct, columns, from, where, group_by, having, windows, order_by, limit, offset)
      @distinct = distinct
      @columns = columns
      @from = from
      @where = where
      @group_by = group_by
      @having = having
      @windows = windows
      @order_by = order_by
      @limit = limit
      @offset = offset
    end

    # The same select with a trailing ORDER BY / LIMIT / OFFSET.
    def with_tail(order_by, limit, offset)
      Select.new(@distinct, @columns, @from, @where, @group_by, @having, @windows, order_by, limit, offset)
    end
  end

  # One `op select` of a compound select; op is "UNION", "UNION ALL", "INTERSECT" or "EXCEPT".
  class CompoundArm
    attr_reader :op, :select

    def initialize(op, select)
      @op = op
      @select = select
    end
  end

  # `first op select op select ...` (left to right) with the ORDER BY / LIMIT / OFFSET of the whole.
  class CompoundSelect < SelectNode
    attr_reader :first, :arms, :order_by, :limit, :offset

    def initialize(first, arms, order_by, limit, offset)
      @first = first
      @arms = arms
      @order_by = order_by
      @limit = limit
      @offset = offset
    end
  end

  # `name [( columns )] AS ( select )`.
  class CommonTable
    attr_reader :name, :columns, :select

    def initialize(name, columns, select)
      @name = name
      @columns = columns
      @select = select
    end
  end

  # `WITH [RECURSIVE] cte, ...`.
  class WithClause
    attr_reader :recursive, :tables

    def initialize(recursive, tables)
      @recursive = recursive
      @tables = tables
    end
  end

  # `WITH ... select`: the select (simple or compound) sees the tables of the clause.
  class WithSelect < SelectNode
    attr_reader :with, :body

    def initialize(with, body)
      @with = with
      @body = body
    end
  end

  # `VALUES (...), (...)` as the source of an INSERT.
  class ValuesList
    attr_reader :rows

    def initialize(rows)
      @rows = rows
    end
  end

  # kind is :begin, :commit (also END) or :rollback.
  class TransactionStatement < Statement
    attr_reader :kind

    def initialize(kind)
      @kind = kind
    end
  end

  # columns is nil without a column list.
  class CreateView < Statement
    attr_reader :name, :columns, :select, :if_not_exists

    def initialize(name, columns, select, if_not_exists)
      @name = name
      @columns = columns
      @select = select
      @if_not_exists = if_not_exists
    end
  end

  class DropView < Statement
    attr_reader :name, :if_exists

    def initialize(name, if_exists)
      @name = name
      @if_exists = if_exists
    end
  end

  # `column [COLLATE name]` of CREATE INDEX; collation is the name as written (nil when absent).
  class IndexColumn
    attr_reader :name, :collation

    def initialize(name, collation)
      @name = name
      @collation = collation
    end
  end

  class CreateIndex < Statement
    attr_reader :name, :table, :columns, :unique, :if_not_exists

    def initialize(name, table, columns, unique, if_not_exists)
      @name = name
      @table = table
      @columns = columns
      @unique = unique
      @if_not_exists = if_not_exists
    end
  end

  class DropIndex < Statement
    attr_reader :name, :if_exists

    def initialize(name, if_exists)
      @name = name
      @if_exists = if_exists
    end
  end

  # `ALTER TABLE table ADD [COLUMN] column-def`.
  class AddColumn < Statement
    attr_reader :table, :column

    def initialize(table, column)
      @table = table
      @column = column
    end
  end

  # `ALTER TABLE table RENAME TO new-name`.
  class RenameTable < Statement
    attr_reader :table, :new_name

    def initialize(table, new_name)
      @table = table
      @new_name = new_name
    end
  end

  # `ALTER TABLE table RENAME [COLUMN] column TO new-name`.
  class RenameColumn < Statement
    attr_reader :table, :column, :new_name

    def initialize(table, column, new_name)
      @table = table
      @column = column
      @new_name = new_name
    end
  end
end
