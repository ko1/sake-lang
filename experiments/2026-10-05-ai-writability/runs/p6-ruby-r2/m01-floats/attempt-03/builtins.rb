# The built-in functions (SPEC.md, "Built-in functions"). Each checks its
# argument count, then its arguments one by one (type, then value), and reports
# the first problem it finds as a runtime error at the position of the call.
# `map` and `filter` run Mini functions, so the interpreter carries them out
# (Interpreter#call_higher_order) with the checks defined here.
module Builtins
  module_function

  # name => [minimum, maximum] number of arguments; a nil maximum means no limit.
  ARITY = {
    "print" => [0, nil],
    "len" => [1, 1],
    "push" => [2, 2],
    "pop" => [1, 1],
    "keys" => [1, 1],
    "values" => [1, 1],
    "has" => [2, 2],
    "get" => [2, 3],
    "del" => [2, 2],
    "str" => [1, 1],
    "int" => [1, 1],
    "float" => [1, 1],
    "type" => [1, 1],
    "range" => [1, 3],
    "join" => [2, 2],
    "split" => [2, 2],
    "slice" => [2, 3],
    "sort" => [1, 1],
    "contains" => [2, 2],
    "min" => [1, nil],
    "max" => [1, nil],
    "upper" => [1, 1],
    "lower" => [1, 1],
    "reverse" => [1, 1],
    "map" => [2, 2],
    "filter" => [2, 2]
  }

  def names = ARITY.keys

  # [minimum, maximum] number of arguments of the built-in `name`.
  def arity(name) = ARITY[name]

  def check_arity(name, args, pos)
    min, max = arity(name)
    return if Arity.accepts?(min, max, args.length)

    Errors.runtime("arity", Arity.message(name, min, max, args.length), pos)
  end

  # Runs every built-in except `map` and `filter`.
  def call(name, args, pos)
    check_arity(name, args, pos)
    case name
    when "print" then builtin_print(args)
    when "len" then builtin_len(args, pos)
    when "push" then builtin_push(args, pos)
    when "pop" then builtin_pop(args, pos)
    when "keys" then map_arg(name, args, 1, pos).keys
    when "values" then map_arg(name, args, 1, pos).values
    when "has" then builtin_has(args, pos)
    when "get" then builtin_get(args, pos)
    when "del" then builtin_del(args, pos)
    when "str" then Format.show(args[0])
    when "int" then builtin_int(args, pos)
    when "float" then builtin_float(args, pos)
    when "type" then Values.type_name(args[0])
    when "range" then builtin_range(args, pos)
    when "join" then builtin_join(args, pos)
    when "split" then builtin_split(args, pos)
    when "slice" then builtin_slice(args, pos)
    when "sort" then builtin_sort(args, pos)
    when "contains" then builtin_contains(args, pos)
    when "min", "max" then builtin_min_max(name, args, pos)
    when "upper" then string_arg(name, args, 1, pos).upcase
    when "lower" then string_arg(name, args, 1, pos).downcase
    when "reverse" then builtin_reverse(args, pos)
    else raise ArgumentError, "unknown built-in #{name}"
    end
  end

  # ---- argument checks ----

  # Argument `n` (1-based) of a call to `name` is not of the `expected` kind.
  def arg_error(name, n, expected, value, pos)
    Errors.runtime("type", "#{name}: argument #{n} must be #{expected}, got #{Values.type_name(value)}", pos)
  end

  def int_arg(name, args, n, pos)
    value = args[n - 1]
    arg_error(name, n, "an int", value, pos) unless value.is_a?(Integer)
    value
  end

  def string_arg(name, args, n, pos)
    value = args[n - 1]
    arg_error(name, n, "a string", value, pos) unless value.is_a?(String)
    value
  end

  def array_arg(name, args, n, pos)
    value = args[n - 1]
    arg_error(name, n, "an array", value, pos) unless value.is_a?(Array)
    value
  end

  def map_arg(name, args, n, pos)
    value = args[n - 1]
    arg_error(name, n, "a map", value, pos) unless value.is_a?(Hash)
    value
  end

  def function_arg(name, args, n, pos)
    value = args[n - 1]
    arg_error(name, n, "a function", value, pos) unless value.is_a?(Closure) || value.is_a?(Builtin)
    value
  end

  def key_arg(name, args, n, pos)
    value = args[n - 1]
    arg_error(name, n, "a string or int", value, pos) unless Values.key?(value)
    value
  end

  # ---- the built-ins ----

  def builtin_print(args)
    print("#{args.map { |arg| Format.show(arg) }.join(" ")}\n")
    nil
  end

  def builtin_len(args, pos)
    value = args[0]
    case value
    when String, Array, Hash then value.length
    else arg_error("len", 1, "a string, array or map", value, pos)
    end
  end

  def builtin_push(args, pos)
    array_arg("push", args, 1, pos).push(args[1])
    nil
  end

  def builtin_pop(args, pos)
    array = array_arg("pop", args, 1, pos)
    Errors.runtime("value", "pop: array is empty", pos) if array.empty?
    array.pop
  end

  def builtin_has(args, pos)
    map = map_arg("has", args, 1, pos)
    map.key?(key_arg("has", args, 2, pos))
  end

  def builtin_get(args, pos)
    map = map_arg("get", args, 1, pos)
    key = key_arg("get", args, 2, pos)
    map.key?(key) ? map[key] : args[2]
  end

  def builtin_del(args, pos)
    map = map_arg("del", args, 1, pos)
    key = key_arg("del", args, 2, pos)
    Errors.runtime("key", "key #{Format.repr(key)} not found", pos) unless map.key?(key)
    map.delete(key)
  end

  def builtin_int(args, pos)
    value = args[0]
    case value
    when Integer then value
    when Float then value.truncate
    when String
      n = parse_int(value)
      Errors.runtime("value", "int: cannot convert #{Format.repr(value)} to int", pos) if n.nil?
      n
    else arg_error("int", 1, "an int, float or string", value, pos)
    end
  end

  def builtin_float(args, pos)
    value = args[0]
    result =
      case value
      when Float then value
      when Integer then value.to_f
      when String then value.match?(/\A-?[0-9]+(\.[0-9]+)?\z/) ? Float(value) : nil
      else arg_error("float", 1, "an int, float or string", value, pos)
      end
    if result.nil? || result.infinite?
      Errors.runtime("value", "float: cannot convert #{Format.repr(value)} to float", pos)
    end
    result
  end

  # An optional "-" followed by one or more decimal digits, and nothing else; nil otherwise.
  def parse_int(text)
    digits = text.start_with?("-") ? text[1..] : text
    return nil if digits.empty?
    return nil unless digits.chars.all? { |c| c >= "0" && c <= "9" }

    n = digits.to_i
    text.start_with?("-") ? -n : n
  end

  def builtin_range(args, pos)
    args.each_index { |i| int_arg("range", args, i + 1, pos) }
    start, stop, step =
      case args.length
      when 1 then [0, args[0], 1]
      when 2 then [args[0], args[1], 1]
      else args
      end
    Errors.runtime("value", "range: step must not be zero", pos) if step == 0
    result = []
    i = start
    while step > 0 ? i < stop : i > stop
      result.push(i)
      i += step
    end
    result
  end

  def builtin_join(args, pos)
    array = array_arg("join", args, 1, pos)
    separator = string_arg("join", args, 2, pos)
    array.map { |element| Format.show(element) }.join(separator)
  end

  # Unlike Ruby's String#split, keeps every empty field: split(",a,", ",") is ["", "a", ""].
  def builtin_split(args, pos)
    text = string_arg("split", args, 1, pos)
    separator = string_arg("split", args, 2, pos)
    Errors.runtime("value", "split: separator must not be empty", pos) if separator.empty?
    fields = []
    start = 0
    while true
      found = text.index(separator, start)
      break if found.nil?

      fields.push(text[start...found])
      start = found + separator.length
    end
    fields.push(text[start..])
    fields
  end

  # slice(x, start, stop) is x[start:stop] (see Operators.slice); stop defaults to the end.
  def builtin_slice(args, pos)
    target = args[0]
    arg_error("slice", 1, "an array or string", target, pos) unless target.is_a?(Array) || target.is_a?(String)
    start = int_arg("slice", args, 2, pos)
    stop = args.length == 3 ? int_arg("slice", args, 3, pos) : nil
    Operators.slice(target, start, stop)
  end

  # A new array, in ascending order; the elements must be all ints or all strings.
  def builtin_sort(args, pos)
    array = array_arg("sort", args, 1, pos)
    array.each_index do |i|
      next if i == 0

      a = array[0]
      b = array[i]
      next if (Operators.number?(a) && Operators.number?(b)) || (a.is_a?(String) && b.is_a?(String))

      Errors.runtime("type", "sort: cannot compare #{Values.type_name(a)} and #{Values.type_name(b)}", pos)
    end
    array.each_with_index.sort_by { |v, i| [v, i] }.map(&:first)
  end

  def builtin_contains(args, pos)
    collection = args[0]
    item = args[1]
    case collection
    when Array, Hash then nil
    when String then arg_error("contains", 2, "a string", item, pos) unless item.is_a?(String)
    else arg_error("contains", 1, "an array, map or string", collection, pos)
    end
    Values.contains?(collection, item, pos)
  end

  def builtin_min_max(name, args, pos)
    args.each_index do |i|
      arg_error(name, i + 1, "an int or float", args[i], pos) unless Operators.number?(args[i])
    end
    best = args[0]
    args.each do |v|
      best = v if name == "min" ? v < best : v > best
    end
    best
  end

  def builtin_reverse(args, pos)
    value = args[0]
    case value
    when Array, String then value.reverse
    else arg_error("reverse", 1, "an array or string", value, pos)
    end
  end
end
