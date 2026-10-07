# The operators of Mini (SPEC.md, "Operators"): arithmetic, comparison,
# equality, membership, unary minus, reading and writing through a[i], and
# slicing with a[i:j].
module Operators
  module_function

  def binary(op, a, b, pos)
    case op
    when "+" then add(a, b, pos)
    when "-", "*", "/", "%" then arithmetic(op, a, b, pos)
    when "**" then power(a, b, pos)
    when "==" then Values.equal(a, b, pos)
    when "!=" then !Values.equal(a, b, pos)
    when "<", "<=", ">", ">=" then compare(op, a, b, pos)
    when "in" then member(a, b, pos)
    else raise ArgumentError, "unknown operator #{op}"
    end
  end

  def operand_error(op, a, b, pos)
    Errors.runtime("type", "cannot apply '#{op}' to #{Values.type_name(a)} and #{Values.type_name(b)}", pos)
  end

  def num?(v) = v.is_a?(Integer) || v.is_a?(Float)

  def float_result(r, pos)
    Errors.runtime("value", "float result out of range", pos) if !r.is_a?(Float) || r.nan? || r.infinite?
    r
  end

  # int + int, float arithmetic, string + string (concatenation), array + array (a new array).
  def add(a, b, pos)
    if a.is_a?(Integer) && b.is_a?(Integer)
      a + b
    elsif num?(a) && num?(b)
      float_result(a.to_f + b.to_f, pos)
    elsif (a.is_a?(String) && b.is_a?(String)) || (a.is_a?(Array) && b.is_a?(Array))
      a + b
    else
      operand_error("+", a, b, pos)
    end
  end

  # Integer division and remainder round toward negative infinity, as Ruby's do:
  # -7 / 2 is -4 and -7 % 2 is 1. With a float operand: float arithmetic.
  def arithmetic(op, a, b, pos)
    operand_error(op, a, b, pos) unless num?(a) && num?(b)

    if a.is_a?(Integer) && b.is_a?(Integer)
      case op
      when "-" then return a - b
      when "*" then return a * b
      else
        Errors.runtime("zero", "division by zero", pos) if b == 0
        return op == "/" ? a / b : a % b
      end
    end

    x = a.to_f
    y = b.to_f
    case op
    when "-" then float_result(x - y, pos)
    when "*" then float_result(x * y, pos)
    when "/"
      Errors.runtime("zero", "division by zero", pos) if y == 0
      float_result(x / y, pos)
    else
      Errors.runtime("zero", "division by zero", pos) if y == 0
      float_result(float_mod(x, y), pos)
    end
  end

  def float_mod(x, y)
    m = x.remainder(y)
    m += y if m != 0 && (m < 0) != (y < 0)
    m = x.to_s.start_with?("-") ? -0.0 : 0.0 if m == 0
    m
  end

  def power(a, b, pos)
    operand_error("**", a, b, pos) unless num?(a) && num?(b)
    if a.is_a?(Integer) && b.is_a?(Integer)
      Errors.runtime("value", "negative exponent", pos) if b < 0

      return a**b
    end
    float_result(a.to_f**b.to_f, pos)
  end

  # `item in collection`: an element of an array, a key of a map, or a
  # substring of a string.
  def member(item, collection, pos)
    unless collection.is_a?(Array) || collection.is_a?(Hash) || (collection.is_a?(String) && item.is_a?(String))
      operand_error("in", item, collection, pos)
    end

    Values.contains?(collection, item, pos)
  end

  # Ints compare by value, strings character by character (by code point).
  def compare(op, a, b, pos)
    unless (num?(a) && num?(b)) || (a.is_a?(String) && b.is_a?(String))
      operand_error(op, a, b, pos)
    end

    case op
    when "<" then a < b
    when "<=" then a <= b
    when ">" then a > b
    when ">=" then a >= b
    end
  end

  def negate(value, pos)
    Errors.runtime("type", "cannot negate #{Values.type_name(value)}", pos) unless num?(value)

    -value
  end

  # a[i] for arrays and strings (negative i counts from the end) and m[k] for maps.
  def index_get(target, key, pos)
    case target
    when Array
      target[position(target, key, "array", pos)]
    when String
      target[position(target, key, "string", pos)]
    when Hash
      Values.check_key(key, pos)
      Errors.runtime("key", "key #{Format.repr(key)} not found", pos) unless target.key?(key)
      target[key]
    else
      Errors.runtime("type", "cannot index #{Values.type_name(target)}", pos)
    end
  end

  # a[i] = v replaces an existing element; m[k] = v adds or replaces an entry.
  def index_set(target, key, value, pos)
    case target
    when Array
      target[position(target, key, "array", pos)] = value
    when Hash
      Values.check_key(key, pos)
      target[key] = value
    when String
      Errors.runtime("type", "strings are immutable", pos)
    else
      Errors.runtime("type", "cannot index #{Values.type_name(target)}", pos)
    end
    nil
  end

  # a[start:stop] once the operands are checked: the elements (or characters)
  # start..stop-1, as a new array (or string). A nil start is 0 and a nil stop
  # the length; a negative bound counts from the end; bounds are clamped to
  # 0..length; stop <= start gives an empty result.
  def slice(target, start, stop)
    length = target.length
    first = start.nil? ? 0 : clamp_bound(start, length)
    last = stop.nil? ? length : clamp_bound(stop, length)
    return target.is_a?(String) ? "" : [] if last <= first

    target[first...last]
  end

  def clamp_bound(bound, length)
    bound += length if bound < 0
    bound.clamp(0, length)
  end

  # a[start:stop] as an expression: checks the operands, then slices.
  def slice_expression(target, start, stop, pos)
    unless target.is_a?(Array) || target.is_a?(String)
      Errors.runtime("type", "cannot slice #{Values.type_name(target)}", pos)
    end
    [start, stop].each do |bound|
      next if bound.nil? || bound.is_a?(Integer)

      Errors.runtime("type", "slice bound must be an int, got #{Values.type_name(bound)}", pos)
    end
    slice(target, start, stop)
  end

  # The 0-based position `index` designates in an array or string of that kind.
  def position(target, index, kind, pos)
    unless index.is_a?(Integer)
      Errors.runtime("type", "#{kind} index must be an int, got #{Values.type_name(index)}", pos)
    end

    i = index < 0 ? index + target.length : index
    if i < 0 || i >= target.length
      Errors.runtime("index", "index #{index} out of range for #{kind} of length #{target.length}", pos)
    end
    i
  end
end
