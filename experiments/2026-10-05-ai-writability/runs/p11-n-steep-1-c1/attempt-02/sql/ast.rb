# frozen_string_literal: true

module Sql
  # Syntax tree. Expressions come from the parser with ColumnRef names; the Resolver
  # replaces those with ResolvedColumn before anything is evaluated.
  module Ast
    class Expr
      # The sub-expressions, in evaluation-independent order.
      def children
        []
      end

      # The parts of this node other than its children (operator, flags...).
      def label
        ""
      end

      # A string that is equal for two expressions written identically (after resolution).
      def signature
        "#{self.class}[#{label}](#{children.map(&:signature).join(",")})"
      end

      # The collation a COLLATE in this expression gives it, or nil (spec 7.3).
      def explicit_collation
        nil
      end

      # The collation of the column this expression is (or passes through), or nil.
      def implicit_collation
        nil
      end

      def collation
        explicit_collation || implicit_collation
      end

      # The collation a sort or a grouping on this expression uses.
      def collation_or_binary
        collation || :binary
      end

      # The first aggregate call in this expression, or nil.
      def first_aggregate
        children.each do |child|
          found = child.first_aggregate
          return found if found
        end
        nil
      end

      # The first window call in this expression, or nil.
      def first_window
        children.each do |child|
          found = child.first_window
          return found if found
        end
        nil
      end
    end

    class Literal < Expr
      attr_reader :value

      def initialize(value)
        super()
        @value = value
      end

      def label
        @value.inspect
      end
    end

    # A column as written: name, or qualifier.name (qualifier is nil when absent).
    class ColumnRef < Expr
      attr_reader :name, :qualifier

      def initialize(name, qualifier)
        super()
        @name = name
        @qualifier = qualifier
      end

      def label
        qualifier = @qualifier
        qualifier ? "#{qualifier}.#{@name}" : @name
      end
    end

    # A column of the row being read: its position in the row, its affinity (nil: none) and its
    # collation (an implicit one: BINARY when the column declares none).
    class ResolvedColumn < Expr
      attr_reader :index, :type

      def initialize(index, type, collation)
        super()
        @index = index
        @type = type
        @collation = collation
      end

      def implicit_collation
        @collation
      end

      def label
        @index.to_s
      end
    end

    # op is "-", "+" or "NOT".
    class Unary < Expr
      attr_reader :op, :operand

      def initialize(op, operand)
        super()
        @op = op
        @operand = operand
      end

      def children
        [@operand]
      end

      def label
        @op
      end

      # Unary plus passes the collation of its operand through.
      def explicit_collation
        @op == "+" ? @operand.explicit_collation : nil
      end

      def implicit_collation
        @op == "+" ? @operand.implicit_collation : nil
      end
    end

    # op is one of + - * / % || = != < <= > >= AND OR (== and <> are normalized by the parser).
    class Binary < Expr
      attr_reader :op, :left, :right

      def initialize(op, left, right)
        super()
        @op = op
        @left = left
        @right = right
      end

      def children
        [@left, @right]
      end

      def label
        @op
      end
    end

    class Is < Expr
      attr_reader :left, :right, :negated

      def initialize(left, right, negated)
        super()
        @left = left
        @right = right
        @negated = negated
      end

      def children
        [@left, @right]
      end

      def label
        @negated.to_s
      end
    end

    # A call as written: name(args), name(*), name(DISTINCT args) or name(args ORDER BY terms),
    # with the window after OVER if it has one. The Resolver turns the calls that are aggregates
    # into Aggregate and those with a window into WindowCall.
    class FunctionCall < Expr
      attr_reader :name, :args, :distinct, :star, :order_by, :over

      def initialize(name, args, distinct: false, star: false, order_by: [], over: nil)
        super()
        @name = name
        @args = args
        @distinct = distinct
        @star = star
        @order_by = order_by
        @over = over
      end

      def children
        @args + @order_by.map(&:expr)
      end

      def label
        "#{@name.tr("A-Z", "a-z")},#{@distinct},#{@star},#{@order_by.map(&:label).join(";")}"
      end
    end

    # A call whose value is computed ahead of the expressions that read it and stored at position
    # index of the row (after the table's columns): an Aggregate or a WindowCall.
    class SlotExpr < Expr
      attr_reader :index

      def initialize(index)
        super()
        @index = index
      end
    end

    # An aggregate call over the rows of a group. Its value is computed per group by
    # Aggregates and stored at position index of the group's row.
    # function is the lower-cased name; name is the spelling in the statement (for messages).
    class Aggregate < SlotExpr
      attr_reader :name, :function, :args, :distinct, :star, :order_by

      def initialize(name, function, args, distinct, star, order_by, index)
        super(index)
        @name = name
        @function = function
        @args = args
        @distinct = distinct
        @star = star
        @order_by = order_by
      end

      def children
        @args + @order_by.map(&:expr)
      end

      def label
        "#{@function},#{@distinct},#{@star},#{@order_by.map(&:label).join(";")}"
      end

      def first_aggregate
        self
      end
    end

    # One end of a window frame. kind is :unbounded_preceding, :preceding, :current, :following or
    # :unbounded_following; offset is the n of the two with an n (else nil).
    class FrameBound
      attr_reader :kind, :offset

      def initialize(kind, offset)
        @kind = kind
        @offset = offset
      end

      def label
        "#{@kind}#{@offset}"
      end
    end

    # units is :rows or :range.
    class Frame
      attr_reader :units, :first, :last

      def initialize(units, first, last)
        @units = units
        @first = first
        @last = last
      end

      def rows?
        @units == :rows
      end

      def label
        "#{@units},#{@first.label},#{@last.label}"
      end
    end

    # A window as written: [base] [PARTITION BY ...] [ORDER BY ...] [frame]. base_name is the
    # named window it extends (nil for none); frame is nil when not written.
    class WindowSpec
      attr_reader :base_name, :partition_by, :order_by, :frame

      def initialize(base_name, partition_by, order_by, frame)
        @base_name = base_name
        @partition_by = partition_by
        @order_by = order_by
        @frame = frame
      end
    end

    # name AS ( window-spec ) of a SELECT's WINDOW clause.
    class NamedWindow
      attr_reader :name, :spec

      def initialize(name, spec)
        @name = name
        @spec = spec
      end
    end

    # A window function call with its window resolved (spec 6): its value for each row is
    # computed by Windows and stored at position index. aggregate is the Aggregate that is
    # computed over the frame when function is an aggregate (else nil).
    class WindowCall < SlotExpr
      attr_reader :name, :function, :args, :partition_by, :order_by, :frame, :aggregate

      def initialize(name, function, args, partition_by, order_by, frame, aggregate, index)
        super(index)
        @name = name
        @function = function
        @args = args
        @partition_by = partition_by
        @order_by = order_by
        @frame = frame
        @aggregate = aggregate
      end

      def children
        @args + @partition_by + @order_by.map(&:expr)
      end

      def label
        "#{@function},#{@partition_by.length},#{@order_by.map(&:label).join(";")},#{@frame.label}"
      end

      def first_window
        self
      end
    end

    # One WHEN condition THEN result of a CASE.
    class WhenClause
      attr_reader :condition, :result

      def initialize(condition, result)
        @condition = condition
        @result = result
      end
    end

    # subject is nil for the searched form (CASE WHEN c ...); else_result is nil without ELSE.
    class CaseExpr < Expr
      attr_reader :subject, :whens, :else_result

      def initialize(subject, whens, else_result)
        super()
        @subject = subject
        @whens = whens
        @else_result = else_result
      end

      def children
        list = [] #: Array[Expr]
        subject = @subject
        list << subject if subject
        @whens.each do |clause|
          list << clause.condition
          list << clause.result
        end
        else_result = @else_result
        list << else_result if else_result
        list
      end

      def label
        "#{@subject ? 1 : 0},#{@whens.length},#{@else_result ? 1 : 0}"
      end
    end

    # value [NOT] BETWEEN low AND high
    class Between < Expr
      attr_reader :value, :low, :high, :negated

      def initialize(value, low, high, negated)
        super()
        @value = value
        @low = low
        @high = high
        @negated = negated
      end

      def children
        [@value, @low, @high]
      end

      def label
        @negated.to_s
      end
    end

    # value [NOT] IN (candidates...)
    class InList < Expr
      attr_reader :value, :candidates, :negated

      def initialize(value, candidates, negated)
        super()
        @value = value
        @candidates = candidates
        @negated = negated
      end

      def children
        [@value] + @candidates
      end

      def label
        @negated.to_s
      end
    end

    # value [NOT] LIKE pattern
    class Like < Expr
      attr_reader :value, :pattern, :negated

      def initialize(value, pattern, negated)
        super()
        @value = value
        @pattern = pattern
        @negated = negated
      end

      def children
        [@value, @pattern]
      end

      def label
        @negated.to_s
      end
    end

    class Cast < Expr
      attr_reader :operand, :type

      def initialize(operand, type)
        super()
        @operand = operand
        @type = type
      end

      def children
        [@operand]
      end

      def label
        @type.to_s
      end

      def explicit_collation
        @operand.explicit_collation
      end

      def implicit_collation
        @operand.implicit_collation
      end
    end

    # operand COLLATE name, as written; the Resolver turns it into a Collate.
    class CollateAs < Expr
      attr_reader :operand, :name

      def initialize(operand, name)
        super()
        @operand = operand
        @name = name
      end

      def children
        [@operand]
      end

      def label
        @name
      end
    end

    # operand COLLATE n resolved: the operand's value and affinity, with the explicit collation n.
    class Collate < Expr
      attr_reader :operand

      def initialize(operand, collation)
        super()
        @operand = operand
        @collation = collation
      end

      def children
        [@operand]
      end

      def label
        @collation.to_s
      end

      def explicit_collation
        @collation
      end
    end

    # ( select ) as an expression, as written.
    class ScalarSubquery < Expr
      attr_reader :select

      def initialize(select)
        super()
        @select = select
      end
    end

    # EXISTS ( select ), as written.
    class ExistsSubquery < Expr
      attr_reader :select

      def initialize(select)
        super()
        @select = select
      end
    end

    # value [NOT] IN ( select ), as written.
    class InSubquery < Expr
      attr_reader :value, :select, :negated

      def initialize(value, select, negated)
        super()
        @value = value
        @select = select
        @negated = negated
      end
    end

    # The resolved forms of the three subquery expressions: they hold the checked plan of the
    # select, which runs against the row the expression is evaluated on (its outer row).
    class ScalarPlan < Expr
      attr_reader :plan

      def initialize(plan)
        super()
        @plan = plan
      end

      def label
        @plan.object_id.to_s
      end
    end

    class ExistsPlan < Expr
      attr_reader :plan

      def initialize(plan)
        super()
        @plan = plan
      end

      def label
        @plan.object_id.to_s
      end
    end

    class InPlan < Expr
      attr_reader :value, :plan, :negated

      def initialize(value, plan, negated)
        super()
        @value = value
        @plan = plan
        @negated = negated
      end

      def children
        [@value]
      end

      def label
        "#{@plan.object_id},#{@negated}"
      end
    end

    class Statement
    end

    # default_value is the value of DEFAULT (nil when absent or DEFAULT NULL); collation is that of
    # COLLATE (BINARY when absent).
    class ColumnDef
      attr_reader :name, :type, :not_null, :unique, :primary_key, :default_value, :collation

      def initialize(name:, type:, not_null:, unique:, primary_key:, default_value:, collation:)
        @name = name
        @collation = collation
        @type = type
        @not_null = not_null
        @unique = unique
        @primary_key = primary_key
        @default_value = default_value
      end
    end

    # A table-level PRIMARY KEY (...) (primary_key true) or UNIQUE (...).
    class TableConstraint
      attr_reader :primary_key, :columns

      def initialize(primary_key, columns)
        @primary_key = primary_key
        @columns = columns
      end
    end

    class CreateTable < Statement
      attr_reader :name, :columns, :constraints, :if_not_exists

      def initialize(name, columns, constraints, if_not_exists)
        super()
        @name = name
        @columns = columns
        @constraints = constraints
        @if_not_exists = if_not_exists
      end
    end

    class DropTable < Statement
      attr_reader :name, :if_exists

      def initialize(name, if_exists)
        super()
        @name = name
        @if_exists = if_exists
      end
    end

    # columns is nil when the statement gives no column list.
    # The rows come from VALUES (rows; query nil) or from a select (query; rows empty).
    class Insert < Statement
      attr_reader :table, :columns, :rows, :query

      def initialize(table, columns, rows, query)
        super()
        @table = table
        @columns = columns
        @rows = rows
        @query = query
      end
    end

    # CREATE VIEW: columns is the optional list of column names.
    class CreateView < Statement
      attr_reader :name, :columns, :query, :if_not_exists

      def initialize(name, columns, query, if_not_exists)
        super()
        @name = name
        @columns = columns
        @query = query
        @if_not_exists = if_not_exists
      end
    end

    class DropView < Statement
      attr_reader :name, :if_exists

      def initialize(name, if_exists)
        super()
        @name = name
        @if_exists = if_exists
      end
    end

    # A column of CREATE INDEX; collation is nil when the index gives none.
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
        super()
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
        super()
        @name = name
        @if_exists = if_exists
      end
    end

    # ALTER TABLE table ADD [COLUMN] column-def
    class AddColumn < Statement
      attr_reader :table, :column

      def initialize(table, column)
        super()
        @table = table
        @column = column
      end
    end

    # ALTER TABLE table RENAME TO new_name
    class RenameTable < Statement
      attr_reader :table, :new_name

      def initialize(table, new_name)
        super()
        @table = table
        @new_name = new_name
      end
    end

    # ALTER TABLE table RENAME [COLUMN] column TO new_name
    class RenameColumn < Statement
      attr_reader :table, :column, :new_name

      def initialize(table, column, new_name)
        super()
        @table = table
        @column = column
        @new_name = new_name
      end
    end

    # BEGIN, COMMIT (also END) or ROLLBACK; kind is :begin, :commit or :rollback.
    class Transaction < Statement
      attr_reader :kind

      def initialize(kind)
        super()
        @kind = kind
      end
    end

    # expr is nil for "*" (qualifier nil) and "qualifier.*".
    class SelectItem
      attr_reader :expr, :alias_name, :qualifier

      def initialize(expr, alias_name, qualifier)
        @expr = expr
        @alias_name = alias_name
        @qualifier = qualifier
      end
    end

    # One source of a FROM; alias_name is nil when the statement gives none.
    class FromItem
    end

    class TableSource < FromItem
      attr_reader :table, :alias_name

      def initialize(table, alias_name)
        super()
        @table = table
        @alias_name = alias_name
      end
    end

    class SubquerySource < FromItem
      attr_reader :select, :alias_name

      def initialize(select, alias_name)
        super()
        @select = select
        @alias_name = alias_name
      end
    end

    # item joined to the sources before it. kind is :cross (also for "," and a JOIN without a
    # constraint), :inner or :left; on and using are the constraint, both nil when there is none.
    class Join
      attr_reader :kind, :item, :on, :using

      def initialize(kind, item, on, using)
        @kind = kind
        @item = item
        @on = on
        @using = using
      end
    end

    class FromClause
      attr_reader :first, :joins

      def initialize(first, joins)
        @first = first
        @joins = joins
      end
    end

    # nulls_first is nil when the statement does not say.
    class OrderTerm
      attr_reader :expr, :descending, :nulls_first

      def initialize(expr, descending, nulls_first)
        @expr = expr
        @descending = descending
        @nulls_first = nulls_first
      end

      def label
        "#{@descending},#{@nulls_first.inspect}"
      end

      # The collation the term sorts TEXT under.
      def collation
        @expr.collation_or_binary
      end
    end

    # What a query is made of: a simple Select or a Compound of them.
    class QueryBody
    end

    # from, having, limit and offset are nil, group_by, windows (the WINDOW clause) and order_by
    # empty, without those clauses.
    # Inside a Compound the select has no order_by, limit or offset of its own.
    class Select < QueryBody
      attr_reader :distinct, :items, :from, :where, :group_by, :having, :windows, :order_by, :limit, :offset

      def initialize(distinct, items, from, where, group_by, having, windows, order_by, limit, offset)
        super()
        @distinct = distinct
        @items = items
        @from = from
        @where = where
        @group_by = group_by
        @having = having
        @windows = windows
        @order_by = order_by
        @limit = limit
        @offset = offset
      end

      # The same select with the given ORDER BY, LIMIT and OFFSET.
      def with_tail(order_by, limit, offset)
        Select.new(@distinct, @items, @from, @where, @group_by, @having, @windows, order_by, limit, offset)
      end
    end

    # parts[0] ops[0] parts[1] ops[1] ...: each op is "UNION", "UNION ALL", "INTERSECT" or "EXCEPT",
    # applied left to right. The ORDER BY, LIMIT and OFFSET apply to the whole result.
    class Compound < QueryBody
      attr_reader :parts, :ops, :order_by, :limit, :offset

      def initialize(parts, ops, order_by, limit, offset)
        @parts = parts
        @ops = ops
        @order_by = order_by
        @limit = limit
        @offset = offset
      end
    end

    # name [( column, ... )] AS ( query ) of a WITH.
    class CteDef
      attr_reader :name, :columns, :query

      def initialize(name, columns, query)
        @name = name
        @columns = columns
        @query = query
      end
    end

    # A select as written: its WITH tables (none: empty; recursive after WITH RECURSIVE) and its body.
    class Query < Statement
      attr_reader :ctes, :recursive, :body

      def initialize(ctes, recursive, body)
        super()
        @ctes = ctes
        @recursive = recursive
        @body = body
      end
    end

    # One column = expr of an UPDATE's SET.
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
        super()
        @table = table
        @assignments = assignments
        @where = where
      end
    end

    class Delete < Statement
      attr_reader :table, :where

      def initialize(table, where)
        super()
        @table = table
        @where = where
      end
    end
  end
end
