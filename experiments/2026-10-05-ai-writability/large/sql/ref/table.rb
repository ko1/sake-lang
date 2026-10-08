require_relative "errors"
require_relative "values"

# A table: columns in declaration order, rows (arrays of values) in insertion order.
class Table
  Column = Struct.new(:name, :type)

  attr_reader :name, :columns, :rows

  def initialize(name, columns)
    @name = name
    @columns = columns
    @rows = []
  end

  def column_index(name)
    key = name.downcase
    @columns.index { |column| column.name.downcase == key }
  end

  # The value as stored in the column: converted to the column's type, or SqlError (spec 1.5).
  def convert(value, column)
    return nil if value.nil?
    if value.is_a?(String) && column.type != "TEXT"
      value = Values.parse_number(value) || (raise storage_error("TEXT", column))
    end
    case column.type
    when "INTEGER"
      return value if value.is_a?(Integer)
      whole = value.finite? && value == value.truncate && value.truncate.between?(Values::INT_MIN, Values::INT_MAX)
      whole ? value.truncate : raise(storage_error("REAL", column))
    when "REAL"
      value.to_f
    when "TEXT"
      Values.to_text(value)
    end
  end

  private

  def storage_error(value_type, column)
    SqlError.new("cannot store #{value_type} value in #{column.type} column #{@name}.#{column.name}")
  end
end
