# frozen_string_literal: true

require_relative "error"
require_relative "value"

module Sql
  module Names
    # Names are case-insensitive (ASCII).
    def self.fold(name)
      name.tr("A-Z", "a-z")
    end
  end

  class Column
    attr_reader :name, :type

    def initialize(name, type)
      @name = name
      @type = type
    end

    def type_name
      type.to_s.upcase
    end

    # Converts a value to this column's type (spec 1.5) or raises.
    def store(value, table_name)
      return nil if value.nil?

      value = Value.parse_numeric_text(value) || value if value.is_a?(String) && @type != :text
      case @type
      when :integer then store_integer(value, table_name)
      when :real then store_real(value, table_name)
      else Value.text_form(value)
      end
    end

    private

    def store_integer(value, table_name)
      case value
      when Integer then value
      when Float
        if value == value.floor && value >= Value::INT_MIN && value < Value::INT_MAX.to_f
          value.to_i
        else
          reject(value, table_name)
        end
      else reject(value, table_name)
      end
    end

    def store_real(value, table_name)
      case value
      when Integer then value.to_f
      when Float then value
      else reject(value, table_name)
      end
    end

    def reject(value, table_name)
      kind = value.is_a?(String) ? "TEXT" : "REAL"
      raise Error, "cannot store #{kind} value in #{type_name} column #{table_name}.#{@name}"
    end
  end

  class Table
    attr_reader :name, :columns, :rows

    def initialize(name, columns)
      @name = name
      @columns = columns
      @rows = [] #: Array[Array[value]]
    end

    def column_index(name)
      key = Names.fold(name)
      @columns.index { |column| Names.fold(column.name) == key }
    end

    def append_rows(new_rows)
      @rows.concat(new_rows)
    end
  end

  class Catalog
    def initialize
      @tables = {} #: Hash[String, Table]
    end

    def find(name)
      @tables[Names.fold(name)]
    end

    def fetch(name)
      find(name) || raise(Error, "no such table: #{name}")
    end

    def add(table)
      @tables[Names.fold(table.name)] = table
    end

    def remove(name)
      @tables.delete(Names.fold(name))
    end
  end
end
