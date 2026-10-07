# Errors reported to the user, and the signals used to unwind evaluation.
module Mini
  # An error that stops the run with one line:
  #   <phase> error at <line>:<col>: <message>
  # `phase` is "lexical", "syntax", "static" or "runtime".
  class Error < StandardError
    attr_reader :phase, :line, :col

    def initialize(phase, message, line, col)
      super(message)
      @phase = phase
      @line = line
      @col = col
    end

    def report
      "#{phase} error at #{line}:#{col}: #{message}"
    end
  end

  class LexicalError < Error
    def initialize(message, line, col) = super("lexical", message, line, col)
  end

  class SyntaxError < Error
    def initialize(message, line, col) = super("syntax", message, line, col)
  end

  class StaticError < Error
    def initialize(message, line, col) = super("static", message, line, col)
  end

  # Everything that unwinds the evaluator: control flow and exceptions.
  # A `finally` block intercepts all of them.
  class Unwind < StandardError; end

  class BreakSignal < Unwind; end
  class ContinueSignal < Unwind; end

  class ReturnSignal < Unwind
    attr_reader :value

    def initialize(value)
      super("return")
      @value = value
    end
  end

  # A runtime error (section 9). `kind` is "type", "index", "key", ...
  # A `catch` receives it as an error map.
  class RuntimeError < Unwind
    attr_reader :kind, :line, :col

    def initialize(kind, message, line, col)
      super(message)
      @kind = kind
      @line = line
      @col = col
    end

    def to_map
      { "kind" => kind, "message" => message, "line" => line, "col" => col }
    end

    def report
      "runtime error at #{line}:#{col}: #{message}"
    end
  end

  # `throw v`: the position is that of the `throw` keyword.
  class ThrowSignal < Unwind
    attr_reader :value, :line, :col

    def initialize(value, line, col)
      super("throw")
      @value = value
      @line = line
      @col = col
    end
  end

  # Raised by code that knows the kind and message of a runtime error but not
  # where it is reported; the caller adds the position (see Interpreter#at).
  class Fault < StandardError
    attr_reader :kind

    def initialize(kind, message)
      super(message)
      @kind = kind
    end

    def at(line, col) = RuntimeError.new(kind, message, line, col)
  end
end
