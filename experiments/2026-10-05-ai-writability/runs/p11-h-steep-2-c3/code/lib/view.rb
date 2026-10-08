module MiniSql
  # A view (SPEC 5.3): a named select, kept unchecked and run anew wherever it is used. name is as created;
  # columns is the column list or nil.
  class View
    attr_reader :name, :columns, :select

    def initialize(name, columns, select)
      @name = name
      @columns = columns
      @select = select
    end
  end
end
