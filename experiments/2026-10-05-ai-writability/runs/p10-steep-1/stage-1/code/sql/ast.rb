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

    class Statement
    end

    class ColumnDef
      attr_reader :name, :type

      def initialize(name, type)
        @name = name
        @type = type
      end
    end

    class CreateTable < Statement
      attr_reader :name, :columns, :if_not_exists

      def initialize(name, columns, if_not_exists)
        super()
        @name = name
        @columns = columns
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
  end
end
