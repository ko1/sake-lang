# frozen_string_literal: true

module Mini
  # A place in the program text. Lines and columns are 1-based and columns
  # count characters (a tab is one column).
  Position = Struct.new(:line, :col) do
    def to_s = "#{line}:#{col}"
  end

  # Base class of everything that stops a run with a single report line
  # (SPEC section 1): `<kind> error at <line>:<col>: <message>`.
  class Error < StandardError
    attr_reader :position

    def initialize(message, position)
      super(message)
      @position = position
    end

    def phase = raise(NotImplementedError)

    def report = "#{phase} error at #{position}: #{message}"
  end

  class LexicalError < Error
    def phase = "lexical"
  end

  class ParseError < Error
    def phase = "syntax"
  end

  class StaticError < Error
    def phase = "static"
  end

  # A runtime error (SPEC section 9). `kind` is one of the kinds a `catch`
  # sees in the error map: type, index, key, zero, arity, value, name, stack,
  # assert.
  class EvalError < Error
    attr_reader :kind

    def initialize(kind, message, position)
      super(message, position)
      @kind = kind
    end

    def phase = "runtime"

    # The map a `catch` receives.
    def to_value
      { "kind" => kind.to_s, "message" => message, "line" => position.line, "col" => position.col }
    end
  end

  # A value thrown by `throw`, travelling up to the nearest `catch`.
  # `position` is the `throw` keyword, used only when nothing catches it.
  class Thrown < Error
    attr_reader :value

    def initialize(value, position)
      super("uncaught throw", position)
      @value = value
    end

    def phase = "runtime"

    def report = "runtime error at #{position}: uncaught throw #{Text.repr(value)}"
  end

  # The wording shared by the static and the runtime arity checks
  # (SPEC sections 5.2 and 6.6). `max` is nil when there is no maximum.
  def self.arity_message(name, min, max, given)
    expected =
      if max.nil? then "at least #{count_arguments(min)}"
      elsif min == max then count_arguments(min)
      else "#{min} to #{count_arguments(max)}"
      end
    "#{name} expects #{expected}, got #{given}"
  end

  def self.count_arguments(n) = n == 1 ? "1 argument" : "#{n} arguments"

  # Singular for 1: "1 element", "3 values", ...
  def self.plural(n, noun) = n == 1 ? "1 #{noun}" : "#{n} #{noun}s"
end
