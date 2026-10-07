# Source positions, and the exceptions that carry Mini errors up to main.rb.

# A 1-based line and column in the source text. Every token and AST node has one.
Pos = Struct.new(:line, :col)

class Pos
  def to_s = "#{line}:#{col}"
end

# A lexical, syntax or static error: found before the program runs.
# `phase` is "lexical", "syntax" or "static".
class MiniCompileError < StandardError
  attr_reader :phase, :pos

  def initialize(phase, message, pos)
    super(message)
    @phase = phase
    @pos = pos
  end

  def report = "#{@phase} error at #{@pos}: #{message}"
end

# A runtime error raised by the interpreter, an operator or a built-in.
# `kind` is the "kind" entry a catch clause sees (see RUNTIME_ERROR_KINDS).
class MiniRuntimeError < StandardError
  attr_reader :kind, :pos

  def initialize(kind, message, pos)
    super(message)
    @kind = kind
    @pos = pos
  end

  def report = "runtime error at #{@pos}: #{message}"
end

# A value thrown by a `throw` statement on its way to the nearest enclosing `try`.
# `pos` is the position of the `throw` keyword.
class MiniThrow < StandardError
  attr_reader :value, :pos

  def initialize(value, pos)
    super("uncaught throw")
    @value = value
    @pos = pos
  end
end

# The values of the "kind" entry of a caught runtime error.
RUNTIME_ERROR_KINDS = %w[type index key zero arity value name stack assert]

module Errors
  module_function

  def lexical(message, pos)
    raise MiniCompileError.new("lexical", message, pos)
  end

  def syntax(message, pos)
    raise MiniCompileError.new("syntax", message, pos)
  end

  def static(message, pos)
    raise MiniCompileError.new("static", message, pos)
  end

  def runtime(kind, message, pos)
    raise ArgumentError, "unknown runtime error kind #{kind}" unless RUNTIME_ERROR_KINDS.include?(kind)

    raise MiniRuntimeError.new(kind, message, pos)
  end

  # The line printed for a throw that no `try` caught.
  def uncaught_throw_report(err)
    "runtime error at #{err.pos}: uncaught throw #{Format.repr(err.value)}"
  end
end
