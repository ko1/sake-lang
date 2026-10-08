# frozen_string_literal: true

module Sql
  # Syntax tree. Expressions come from the parser with ColumnRef names; the Resolver
  # replaces those with ResolvedColumn before anything is evaluated.
  module Ast
    class Expr
    end

    class Literal < Expr
      attr_reader :value

      def initialize(value)
        super()
        @value = value
      end
    end

    class ColumnRef < Expr
      attr_reader :name

      def initialize(name)
        super()
        @name = name
      end
    end

    # A column of the table being read: its position in the row and its declared type.
    class ResolvedColumn < Expr
      attr_reader :index, :type

      def initialize(index, type)
        super()
        @index = index
        @type = type
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
    end

    class Is < Expr
      attr_reader :left, :right, :negated

      def initialize(left, right, negated)
        super()
        @left = left
        @right = right
        @negated = negated
      end
    end

    class FunctionCall < Expr
      attr_reader :name, :args

      def initialize(name, args)
        super()
        @name = name
        @args = args
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
    end

    class Cast < Expr
      attr_reader :operand, :type

      def initialize(operand, type)
        super()
        @operand = operand
        @type = type
      end
    end

    class Statement
    end

    # default_value is the value of DEFAULT (nil when absent or DEFAULT NULL).
    class ColumnDef
      attr_reader :name, :type, :not_null, :unique, :primary_key, :default_value

      def initialize(name:, type:, not_null:, unique:, primary_key:, default_value:)
        @name = name
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
    class Insert < Statement
      attr_reader :table, :columns, :rows

      def initialize(table, columns, rows)
        super()
        @table = table
        @columns = columns
        @rows = rows
      end
    end

    # expr is nil for "*".
    class SelectItem
      attr_reader :expr, :alias_name

      def initialize(expr, alias_name)
        @expr = expr
        @alias_name = alias_name
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
    end

    class Select < Statement
      attr_reader :items, :table, :where, :order_by, :limit, :offset

      def initialize(items, table, where, order_by, limit, offset)
        super()
        @items = items
        @table = table
        @where = where
        @order_by = order_by
        @limit = limit
        @offset = offset
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
