# frozen_string_literal: true

module SQL
  # Expressions. `value` of a Literal is nil/Integer/Float/String.
  Literal   = Data.define(:value)
  ColumnRef = Data.define(:table, :name)      # table is nil when unqualified
  Unary     = Data.define(:op, :operand)      # op: :neg :pos :not
  Binary    = Data.define(:op, :left, :right) # op: :add :sub :mul :div :mod :concat :eq :ne :lt :le :gt :ge :is :is_not :and :or
  Call      = Data.define(:name, :args)       # name as written

  # Statements.
  ColumnDef   = Data.define(:name, :type)     # type: :integer :real :text
  CreateTable = Data.define(:name, :columns, :if_not_exists)
  DropTable   = Data.define(:name, :if_exists)
  Insert      = Data.define(:table, :columns, :rows) # columns nil or [names]; rows [[expr]]

  Star         = Data.define
  ResultColumn = Data.define(:expr, :alias)   # alias nil or name
  OrderTerm    = Data.define(:expr, :desc, :nulls) # nulls: nil :first :last
  Select       = Data.define(:items, :from, :where, :order_by, :limit, :offset)
end
