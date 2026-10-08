require_relative "errors"
require_relative "values"

# A table: columns in declaration order, rows (arrays of values) in insertion order, and the
# constraints of spec 2.1. `store` turns proposed values into a row as stored, or raises SqlError.
class Table
  # default: the DEFAULT value as written (nil without one).
  Column = Struct.new(:name, :type, :not_null, :default)
  # A UNIQUE or (non-INTEGER) PRIMARY KEY constraint over column indexes; index: the name of the
  # UNIQUE index it is (5.7), else nil.
  Unique = Struct.new(:columns, :index)
  # The <T> of a storage error by typeof (7.6).
  STORED_TYPE_NAMES = { "integer" => "INT", "real" => "REAL", "text" => "TEXT", "blob" => "BLOB" }.freeze

  attr_reader :columns, :key_index
  # The current name (ALTER TABLE ... RENAME TO changes it), which messages use.
  attr_accessor :name

  # uniques: in declaration order; key_index: the INTEGER PRIMARY KEY column's index, or nil.
  def initialize(name, columns, uniques, key_index)
    @name = name
    @columns = columns
    @uniques = uniques
    @key_index = key_index
    @rows = []
  end

  # As a source (FromClause): a table is its own relation; its rows do not depend on the enclosing row.
  def bind(_outer) = self
  def rows(_outer = nil) = @rows
  def column_names = @columns.map(&:name)
  # A BLOB column has no affinity (7.3).
  def affinities = @columns.map { |column| column.type == "BLOB" ? nil : column.type }

  def column_index(name)
    key = name.downcase
    @columns.index { |column| column.name.downcase == key }
  end

  def replace_rows(rows)
    @rows = rows
  end

  # A copy that later changes to either leave the other as it is (rows are never changed in place).
  def initialize_copy(source)
    super
    @columns = source.columns.map(&:dup)
    @uniques = @uniques.dup
  end

  # ALTER TABLE ... ADD COLUMN (5.6): every row gets `value`, already converted.
  def add_column(column, value)
    @columns += [column]
    @rows = @rows.map { |row| row + [value] }
  end

  # A UNIQUE index (5.7): a uniqueness constraint declared after the others, so checked first. Rows
  # that already conflict are the constraint's error.
  def add_unique_index(name, indexes)
    unique = Unique.new(indexes, name)
    @rows.each_with_index do |row, i|
      raise constraint_error("UNIQUE", indexes) if @rows[0...i].any? { |other| conflict?(unique, row, other) }
    end
    @uniques += [unique]
  end

  def drop_unique_index(name)
    @uniques = @uniques.reject { |unique| unique.index&.casecmp?(name) }
  end

  # The values an INSERT stores in the columns it does not name (the INTEGER PRIMARY KEY ignores its
  # DEFAULT: NULL there gets a key).
  def default_row
    @columns.each_with_index.map { |column, i| i == @key_index ? nil : column.default }
  end

  # The row as stored for `values` (one per column), checked in the order of spec 2.1 against
  # `others`, the other rows of the table at this moment. inserting: an INSERT (a NULL key gets the
  # next key) rather than an UPDATE (a NULL key is a datatype mismatch).
  def store(values, others, inserting:)
    @columns.each_with_index do |column, i|
      next unless column.not_null && values[i].nil?
      next if i == @key_index && inserting
      raise constraint_error("NOT NULL", [i])
    end
    row = values.dup
    if @key_index
      row[@key_index] = key_value(values[@key_index], others, inserting)
      raise constraint_error("UNIQUE", [@key_index]) if others.any? { |other| other[@key_index] == row[@key_index] }
    end
    @columns.each_with_index do |column, i|
      row[i] = convert(values[i], column) unless i == @key_index
    end
    @uniques.reverse_each do |unique|
      raise constraint_error("UNIQUE", unique.columns) if others.any? { |other| conflict?(unique, row, other) }
    end
    row
  end

  # The value as stored in the column: converted to the column's type, or SqlError (spec 1.5).
  def convert(value, column)
    return nil if value.nil?
    if column.type == "BLOB" || value.is_a?(Values::Blob)
      return value if column.type == "BLOB" && value.is_a?(Values::Blob)
      raise storage_error(STORED_TYPE_NAMES.fetch(Values.type_name(value)), column)
    end
    if value.is_a?(String) && column.type != "TEXT"
      value = Values.parse_number(value) || (raise storage_error("TEXT", column))
    end
    case column.type
    when "INTEGER"
      Table.whole_number(value) || raise(storage_error("REAL", column))
    when "REAL"
      value.to_f
    when "TEXT"
      Values.to_text(value)
    end
  end

  # The INTEGER a number stands for, if it is whole and within 64 bits, else nil.
  def self.whole_number(value)
    return value if value.is_a?(Integer)
    whole = value.finite? && value == value.truncate && value.truncate.between?(Values::INT_MIN, Values::INT_MAX)
    whole ? value.truncate : nil
  end

  private

  def key_value(value, others, inserting)
    if value.nil?
      raise SqlError, "datatype mismatch" unless inserting
      return others.empty? ? 1 : others.map { |other| other[@key_index] }.max + 1
    end
    value = Values.parse_number(value) if value.is_a?(String)
    raise SqlError, "datatype mismatch" if value.is_a?(Values::Blob)
    (value && Table.whole_number(value)) or raise SqlError, "datatype mismatch"
  end

  # Rows conflict when every listed value is non-NULL and equal (spec 1.9 order).
  def conflict?(unique, row, other)
    unique.columns.all? do |i|
      !row[i].nil? && !other[i].nil? && Values.compare(row[i], other[i]).zero?
    end
  end

  def constraint_error(kind, indexes)
    SqlError.new("#{kind} constraint failed: #{indexes.map { |i| "#{@name}.#{@columns[i].name}" }.join(", ")}")
  end

  def storage_error(value_type, column)
    SqlError.new("cannot store #{value_type} value in #{column.type} column #{@name}.#{column.name}")
  end
end
