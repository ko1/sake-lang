# frozen_string_literal: true

module Sake
  # Literal `[a, b]`. Ruby Arrays are used as Sake Arrays (`Array[a, b]`).
  class Tuple
    attr_reader :elems

    def initialize(elems)
      @elems = elems.freeze
    end
  end

  DataType = Struct.new(:name, :fields)

  # An instance of a Data.define type; fields are mutable.
  class Record
    attr_reader :type, :values

    def initialize(type, values)
      @type = type
      @values = values
    end
  end

  module Values
    module_function

    def type_of(v)
      case v
      when Integer then "Integer"
      when Float then "Float"
      when String then "String"
      when true, false then "Boolean"
      when nil then "Nil"
      when Tuple then "Tuple"
      when Array then "Array"
      when Record then v.type.name
      else raise "BUG: not a Sake value: #{v.inspect}"
      end
    end

    # For messages: nil/true/false are shown as themselves, other values by type name.
    def describe(v) = [nil, true, false].include?(v) ? v.inspect : type_of(v)

    # For messages about table rows keyed by internal type names.
    def display_type(t) = { "Nil" => "nil", "Boolean" => "true|false" }.fetch(t, t)

    def truthy?(v) = !(v.nil? || v == false)

    # Same output as Ruby's #inspect so that expected outputs match Ruby versions of a task.
    def inspect(v)
      case v
      when Tuple then "[#{v.elems.map { inspect(_1) }.join(", ")}]"
      when Array then "[#{v.map { inspect(_1) }.join(", ")}]"
      when Record
        fs = v.type.fields.zip(v.values).map { |f, x| "#{f}=#{inspect(x)}" }
        "#<data #{v.type.name} #{fs.join(", ")}>"
      else v.inspect
      end
    end

    def to_s(v)
      case v
      when String then v
      when nil then ""
      when Tuple, Array, Record then inspect(v)
      else v.to_s
      end
    end

    # Lines written by Ruby's `puts v`.
    def puts_lines(v)
      case v
      when Array then v.empty? ? [""] : v.flat_map { puts_lines(_1) }
      when Tuple then v.elems.empty? ? [""] : v.elems.flat_map { puts_lines(_1) }
      else [to_s(v)]
      end
    end
  end
end
