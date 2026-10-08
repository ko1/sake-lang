module MiniSql
  # A column. type is :integer, :real or :text; default is the value an INSERT that does not
  # mention the column stores (before conversion); not_null includes PRIMARY KEY columns.
  class Column
    attr_reader :name, :type, :not_null, :default

    def initialize(name, type, not_null, default)
      @name = name
      @type = type
      @not_null = not_null
      @default = default
    end
  end

  # A UNIQUE constraint (or a PRIMARY KEY that is not the row key) over columns, by position.
  class UniqueKey
    attr_reader :columns

    def initialize(columns)
      @columns = columns
    end
  end

  # A table: its schema and its rows (arrays of stored values, in insertion order).
  # Every change goes through insert_rows / replace_rows / delete_rows, which enforce the
  # constraints of SPEC 2.1 and either apply completely or raise SqlError and change nothing.
  class Table
    attr_reader :name, :columns, :rows

    # key_index: position of the INTEGER PRIMARY KEY column, or nil.
    # unique_keys: in declaration order.
    def initialize(name, columns, key_index, unique_keys)
      @name = name
      @columns = columns
      @key_index = key_index
      @unique_keys = unique_keys
      @rows = [] # @type ivar @rows: Array[Array[sql_value]]
    end

    # Position of the column with this name (case-insensitive), or nil.
    def column_index(name)
      wanted = name.downcase(:ascii)
      @columns.index { |column| column.name.downcase(:ascii) == wanted }
    end

    # The values an INSERT starts from: each column's default (NULL for the row key, whose
    # default is ignored).
    def default_row
      @columns.each_with_index.map { |column, i| i == @key_index ? nil : column.default }
    end

    # Appends the rows (full-width, unconverted values), checking each against the table
    # as it is after the previous ones.
    def insert_rows(new_rows)
      stored = @rows.dup
      new_rows.each { |row| stored << check_row(row, stored, nil) }
      @rows = stored
    end

    # Replaces rows by position with new unconverted values, one at a time in the given order.
    def replace_rows(changes)
      stored = @rows.dup
      changes.each { |index, row| stored[index] = check_row(row, stored, index) }
      @rows = stored
    end

    def delete_rows(indexes)
      @rows = @rows.each_with_index.reject { |_, i| indexes.include?(i) }.map(&:first)
    end

    private

    # The row as stored, or SqlError; `own` is the position of the row being replaced in
    # `rows` (nil for a new row). The checks run in the order SPEC 2.1 gives.
    def check_row(raw, rows, own)
      row = raw.dup
      key = @key_index
      key_value = nil # @type var key_value: Integer?
      if key
        key_value = key_of(row.fetch(key, nil), rows, own.nil?)
        row[key] = key_value
      end
      @columns.each_with_index do |column, i|
        raise SqlError, "NOT NULL constraint failed: #{@name}.#{column.name}" if column.not_null && row.fetch(i, nil).nil?
      end
      if key && key_value && conflict?(rows, own, [key], row)
        raise SqlError, "UNIQUE constraint failed: #{@name}.#{@columns.fetch(key).name}"
      end
      @columns.each_index { |i| row[i] = coerce(row.fetch(i, nil), i) unless i == key }
      @unique_keys.reverse_each do |unique|
        next unless conflict?(rows, own, unique.columns, row)
        names = unique.columns.map { |i| "#{@name}.#{@columns.fetch(i).name}" }
        raise SqlError, "UNIQUE constraint failed: #{names.join(", ")}"
      end
      row
    end

    # The INTEGER PRIMARY KEY's value: NULL becomes the next key when inserting.
    def key_of(value, rows, inserting)
      if value.nil?
        raise SqlError, "datatype mismatch" unless inserting
        position = @key_index || 0
        largest = nil # @type var largest: Integer?
        rows.each do |row|
          existing = row.fetch(position, nil)
          largest = existing if existing.is_a?(Integer) && (largest.nil? || existing > largest)
        end
        return largest ? largest + 1 : 1
      end
      value = Value.parse_number(value) || value if value.is_a?(String)
      case value
      when Integer then value
      when Float then Value.whole_in_int64?(value) ? value.to_i : raise(SqlError, "datatype mismatch")
      else raise SqlError, "datatype mismatch"
      end
    end

    # Whether another row equals `row` on all of these columns (NULLs never conflict).
    def conflict?(rows, own, positions, row)
      return false if positions.any? { |i| row.fetch(i, nil).nil? }
      rows.each_with_index.any? do |other, j|
        j != own && positions.all? { |i| Value.compare(other.fetch(i, nil), row.fetch(i, nil)).zero? }
      end
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
end
