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

  # A column of a table. default is the value an INSERT gives it when it names no value.
  class Column
    attr_reader :name, :type, :not_null, :default

    def initialize(name, type, not_null, default)
      @name = name
      @type = type
      @not_null = not_null
      @default = default
    end

    def type_name
      type.to_s.upcase
    end

    # The same column under another name.
    def renamed(new_name)
      Column.new(new_name, @type, @not_null, @default)
    end

    # Converts a value to this column's type (spec 1.5) or raises.
    def store(value, table_name)
      return nil if value.nil?
      # A BLOB column keeps only BLOBs and no other column takes one; nothing is converted (spec 7.4).
      return store_blob(value, table_name) if @type == :blob
      return reject(value, table_name) if value.is_a?(Blob)

      value = Value.parse_numeric_text(value) || value if value.is_a?(String) && @type != :text
      case @type
      when :integer then store_integer(value, table_name)
      when :real then store_real(value, table_name)
      else Value.text_form(value)
      end
    end

    private

    def store_blob(value, table_name)
      value.is_a?(Blob) ? value : reject(value, table_name)
    end

    def store_integer(value, table_name)
      case value
      when Integer then value
      when Float then Value.integer_exact(value) || reject(value, table_name)
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
      kind =
        case value
        when Blob then "BLOB"
        when String then "TEXT"
        when Integer then "INT"
        else "REAL"
        end
      raise Error, "cannot store #{kind} value in #{type_name} column #{table_name}.#{@name}"
    end
  end
end
