# Mini values (SPEC.md, "Values").
#
# Mini      Ruby representation
# int       Integer
# string    String (never modified in place)
# bool      true / false
# nil       nil
# array     Array (shared by reference)
# map       Hash with String or Integer keys (shared by reference, insertion-ordered)
# function  Closure (a user function) or Builtin

# A user function together with the environment it was created in.
# `id` makes each closure distinct: functions are equal only to themselves.
Closure = Struct.new(:fn, :env, :id)

# A built-in function, known by its name (see Builtins).
Builtin = Struct.new(:name)

# How many arguments a function accepts, and how a mismatch is reported.
module Arity
  module_function

  # [minimum, maximum] for a user function: parameters with defaults are optional.
  def of_function(fn)
    required = fn.params.count { |param| param.default.nil? }
    [required, fn.params.length]
  end

  # A nil maximum means no limit.
  def accepts?(min, max, count) = count >= min && (max.nil? || count <= max)

  # "len expects 1 argument, got 2", "range expects 1 to 3 arguments, got 0",
  # "min expects at least 1 argument, got 0".
  def message(name, min, max, count)
    expected =
      if max.nil?
        "at least #{Format.count(min, "argument")}"
      elsif min == max
        Format.count(min, "argument")
      else
        "#{min} to #{max} arguments"
      end
    "#{name} expects #{expected}, got #{count}"
  end
end

# Deeper nesting than this is shown as "..." and cannot be compared with ==.
MAX_NESTING = 100

module Values
  module_function

  def type_name(value)
    case value
    when Integer then "int"
    when String then "string"
    when true, false then "bool"
    when nil then "nil"
    when Array then "array"
    when Hash then "map"
    when Closure, Builtin then "function"
    else raise ArgumentError, "not a Mini value: #{value.class}"
    end
  end

  # nil and false are falsy; every other value, including 0 and "", is truthy.
  def truthy?(value) = !(value.nil? || value == false)

  def key?(value) = value.is_a?(String) || value.is_a?(Integer)

  # Raises a type error unless `key` can be a map key.
  def check_key(key, pos)
    return if key?(key)

    Errors.runtime("type", "map key must be a string or int, got #{type_name(key)}", pos)
  end

  # The == of Mini: by value for ints, strings, bools and nil; element by element
  # for arrays; entry by entry (in any order) for maps; by identity for functions.
  # Values of different types are never equal.
  def equal(a, b, pos, depth = 0)
    Errors.runtime("value", "values nested too deeply to compare", pos) if depth > MAX_NESTING

    case a
    when Array then b.is_a?(Array) && arrays_equal(a, b, pos, depth)
    when Hash then b.is_a?(Hash) && maps_equal(a, b, pos, depth)
    when Closure then b.is_a?(Closure) && a.id == b.id
    when Builtin then b.is_a?(Builtin) && a.name == b.name
    else type_name(a) == type_name(b) && a == b
    end
  end

  def arrays_equal(a, b, pos, depth)
    return false unless a.length == b.length

    a.each_index { |i| return false unless equal(a[i], b[i], pos, depth + 1) }
    true
  end

  def maps_equal(a, b, pos, depth)
    return false unless a.length == b.length

    a.each { |key, value| return false unless b.key?(key) && equal(value, b[key], pos, depth + 1) }
    true
  end

  # Whether an array has an element == item, a map has the key item, or a
  # string contains the string item. The caller has checked the types.
  def contains?(collection, item, pos)
    case collection
    when Array then collection.any? { |element| equal(element, item, pos) }
    when Hash then key?(item) && collection.key?(item)
    else collection.include?(item)
    end
  end

  # The map a catch clause receives for a runtime error.
  def error_map(err)
    { "kind" => err.kind, "message" => err.message, "line" => err.pos.line, "col" => err.pos.col,
      "function" => err.function }
  end
end
