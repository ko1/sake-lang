module MiniSql
  class Column
    attr_reader :name, :type

    # type is :integer, :real or :text.
    def initialize(name, type)
      @name = name
      @type = type
    end
  end

  class Table
    attr_reader :name, :columns, :rows

    def initialize(name, columns)
      @name = name
      @columns = columns
      @rows = [] # @type ivar @rows: Array[Array[sql_value]]
    end

    # Position of the column with this name (case-insensitive), or nil.
    def column_index(name)
      wanted = name.downcase(:ascii)
      @columns.index { |column| column.name.downcase(:ascii) == wanted }
    end

    # The value as it is stored into the column at index (SPEC 1.5), or a SqlError.
    def coerce(value, index)
      column = @columns.fetch(index)
      return nil if value.nil?
      value = Value.parse_number(value) || value if value.is_a?(String) && column.type != :text
      case column.type
      when :integer then coerce_integer(value, column)
      when :real then coerce_real(value, column)
      else Value.text_form(value)
      end
    end

    def append(row)
      @rows << row
    end

    private

    def reject(value, column)
      type = column.type.to_s.upcase
      raise SqlError, "cannot store #{Value.type_name(value)} value in #{type} column #{@name}.#{column.name}"
    end

    def coerce_integer(value, column)
      case value
      when Integer then value
      when Float then Value.whole_in_int64?(value) ? value.to_i : reject(value, column)
      else reject(value, column)
      end
    end

    def coerce_real(value, column)
      case value
      when Integer then value.to_f
      when Float then value
      else reject(value, column)
      end
    end
  end

  # The in-memory database: tables by case-insensitive name.
  class Database
    def initialize
      @tables = {} # @type ivar @tables: Hash[String, Table]
    end

    def find_table(name)
      @tables[key(name)]
    end

    def fetch_table(name)
      find_table(name) || raise(SqlError, "no such table: #{name}")
    end

    def add_table(table)
      @tables[key(table.name)] = table
    end

    def remove_table(name)
      @tables.delete(key(name))
    end

    private

    def key(name)
      name.downcase(:ascii)
    end
  end
end
