module MiniSql
  # A column. type is :integer, :real, :text or :blob; default is the value an INSERT that does not
  # mention the column stores (before conversion); not_null includes PRIMARY KEY columns.
  class Column
    attr_reader :name, :type, :not_null, :default

    def initialize(name, type, not_null, default)
      @name = name
      @type = type
      @not_null = not_null
      @default = default
    end

    # The affinity (SPEC 1.9) of comparisons with this column; a BLOB column has none.
    def affinity
      Column.affinity_of(@type)
    end

    def self.affinity_of(type)
      case type
      when :integer then :integer
      when :real then :real
      when :text then :text
      end
    end

    def renamed(new_name)
      Column.new(new_name, @type, @not_null, @default)
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
    def initialize(name, columns, key_index, unique_keys, rows)
      @name = name
      @columns = columns
      @key_index = key_index
      @unique_keys = unique_keys
      @rows = rows
    end

    # An independent table with the same schema and rows (rows are never changed in place).
    def copy
      Table.new(@name, @columns.dup, @key_index, @unique_keys.dup, @rows.dup)
    end

    def rename(new_name)
      @name = new_name
    end

    # Appends a column (ALTER TABLE ... ADD COLUMN): existing rows get its default, converted as by 1.5.
    def add_column(column)
      fill = coerce_for(column.default, column)
      if column.not_null && fill.nil? && !@rows.empty?
        raise SqlError, "Cannot add a NOT NULL column with default value NULL"
      end
      @rows = @rows.map { |row| row + [fill] }
      @columns += [column]
    end

    # Renames the column at index; constraints refer to columns by position, so they follow.
    def rename_column(index, new_name)
      @columns = @columns.each_with_index.map { |column, i| i == index ? column.renamed(new_name) : column }
    end

    # Adds a uniqueness constraint after the existing ones, or raises its error if the rows already conflict.
    def add_unique_key(unique)
      @rows.each_with_index do |row, i|
        raise unique_error(unique) if conflict?(@rows, i, unique.columns, row)
      end
      @unique_keys += [unique]
    end

    # Removes the constraint added by add_unique_key (the very same UniqueKey).
    def remove_unique_key(unique)
      @unique_keys = @unique_keys.reject { |other| other.equal?(unique) }
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
        raise unique_error(unique) if conflict?(rows, own, unique.columns, row)
      end
      row
    end

    def unique_error(unique)
      names = unique.columns.map { |i| "#{@name}.#{@columns.fetch(i).name}" }
      SqlError.new("UNIQUE constraint failed: #{names.join(", ")}")
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
      coerce_for(value, @columns.fetch(index))
    end

    def coerce_for(value, column)
      return nil if value.nil?
      value = Value.parse_number(value) || value if value.is_a?(String) && (column.type == :integer || column.type == :real)
      case column.type
      when :integer then coerce_integer(value, column)
      when :real then coerce_real(value, column)
      when :blob then coerce_blob(value, column)
      else coerce_text(value, column)
      end
    end

    def reject(value, column)
      type = column.type.to_s.upcase
      given = value.is_a?(Integer) ? "INT" : Value.type_name(value)
      raise SqlError, "cannot store #{given} value in #{type} column #{@name}.#{column.name}"
    end

    def coerce_integer(value, column)
      case value
      when Integer then value
      when Float then Value.whole_in_int64?(value) ? value.to_i : reject(value, column)
      else reject(value, column)
      end
    end

    def coerce_blob(value, column)
      value.is_a?(Blob) ? value : reject(value, column)
    end

    def coerce_text(value, column)
      value.is_a?(Blob) ? reject(value, column) : Value.text_form(value)
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
