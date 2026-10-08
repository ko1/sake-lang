# frozen_string_literal: true

require_relative 'errors'
require_relative 'values'

module SQL
  # A column keeps the spelling of its CREATE TABLE; `type` is :integer, :real or :text.
  Column = Struct.new(:name, :type) do
    def type_name = type.to_s.upcase

    # Convert a value for storage in this column, or raise (SPEC 1.5).
    def coerce(value, table_name)
      return nil if value.nil?

      value = Values.parse_numeric_literal(value) || value if value.is_a?(String) && type != :text
      stored =
        case type
        when :integer then to_integer(value)
        when :real then value.is_a?(String) ? nil : value.to_f
        else value.is_a?(String) ? value : Values.text_form(value)
        end
      return stored unless stored.nil?

      raise SqlError, "cannot store #{Values.type_name(value).upcase} value in #{type_name} " \
                      "column #{table_name}.#{name}"
    end

    private

    def to_integer(value)
      case value
      when Integer then value
      when Float then value == value.floor && value >= Values::INT_MIN && value < 2**63 ? value.to_i : nil
      end
    end
  end

  # A table: columns in declaration order, rows (arrays of values) in insertion order.
  class Table
    attr_reader :name, :columns, :rows

    def initialize(name, columns)
      @name = name
      @columns = columns
      @rows = []
    end

    def column_index(name)
      key = name.downcase
      @columns.index { |c| c.name.downcase == key }
    end

    # Store a row of already evaluated values in column order (all-or-nothing is the
    # caller's job: coerce every row first, then append them together).
    def coerce_row(values)
      @columns.each_with_index.map { |c, i| c.coerce(values[i], @name) }
    end

    def append_rows(rows) = @rows.concat(rows)
  end

  # All tables of the database, looked up case-insensitively.
  class Catalog
    def initialize
      @tables = {}
    end

    def find(name) = @tables[name.downcase]

    def fetch(name) = find(name) || raise(SqlError, "no such table: #{name}")

    def add(table) = @tables[table.name.downcase] = table

    def drop(name) = @tables.delete(name.downcase)
  end
end
