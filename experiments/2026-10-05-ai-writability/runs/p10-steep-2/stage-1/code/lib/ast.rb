module MiniSql
  # Expression nodes. The parser builds Literal, ColumnRef, Unary, Binary, Not, Is and Call;
  # the Binder turns names into BoundColumn / BoundCall and comparisons into Compare.
  class Expr
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
  end

  # op is one of + - * / % || = == != <> < <= > >= AND OR.
  class Binary < Expr
    attr_reader :op, :left, :right

    def initialize(op, left, right)
      @op = op
      @left = left
      @right = right
    end
  end

  class Not < Expr
    attr_reader :operand

    def initialize(operand)
      @operand = operand
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
  end

  class Call < Expr
    attr_reader :name, :args

    def initialize(name, args)
      @name = name
      @args = args
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

  # A function known to exist, called with a valid number of arguments; name is lower case.
  class BoundCall < Expr
    attr_reader :name, :args

    def initialize(name, args)
      @name = name
      @args = args
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
      @name = name
      @columns = columns
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

  class Select < Statement
    attr_reader :columns, :from, :where, :order_by, :limit, :offset

    def initialize(columns, from, where, order_by, limit, offset)
      @columns = columns
      @from = from
      @where = where
      @order_by = order_by
      @limit = limit
      @offset = offset
    end
  end
end
