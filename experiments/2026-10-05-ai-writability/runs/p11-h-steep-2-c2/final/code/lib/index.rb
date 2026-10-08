module MiniSql
  # An index (SPEC 5.7). It changes no result; a UNIQUE one carries the uniqueness constraint it added to its
  # table (nil for a plain index). name is as created; table_name is the table's current name.
  class Index
    attr_reader :name, :table_name, :unique_key

    def initialize(name, table_name, unique_key)
      @name = name
      @table_name = table_name
      @unique_key = unique_key
    end

    # The same index after its table was renamed.
    def on_table(new_table_name)
      Index.new(@name, new_table_name, @unique_key)
    end
  end
end
