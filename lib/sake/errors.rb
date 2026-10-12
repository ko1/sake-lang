# frozen_string_literal: true

module Sake
  class Error < StandardError; end

  # A static (pre-execution) error with optional fix suggestions.
  Diagnostic = Struct.new(:path, :line, :column, :message, :hints) do
    def to_s
      s = +"#{path}:#{line}:#{column + 1}: error: #{message}"
      hints.each { |h| s << "\n  hint: #{h}" }
      s
    end
  end

  class StaticErrors < Error
    attr_reader :diagnostics

    def initialize(diagnostics)
      @diagnostics = diagnostics
      super(diagnostics.map(&:to_s).join("\n"))
    end
  end

  # An error raised while running a Sake program: by `raise` (value is the exception) or by an
  # operation (value is built from kind and message when a rescue needs it).
  class RunError < Error
    attr_reader :kind, :line, :frames, :expected, :file, :op
    attr_accessor :path, :hints

    # file: the file of line when it is not the main file (path). frames: [callee, call line, file].
    # op: the built-in operation that raised; shown in the report, not part of the message (which is what
    # `Exception.message(e)` gives a program: Ruby's text).
    def initialize(kind, message, line, frames = [], expected: nil, nil_value: false, hints: [], file: nil, op: nil)
      @kind = kind
      @file = file
      @line = line
      @frames = frames
      @expected = expected
      @nil_value = nil_value
      @hints = hints
      @op = op
      super(message)
    end

    def nil_value? = @nil_value

    attr_accessor :value
    attr_accessor :cause # the RunError being rescued when this one was raised (Ruby's cause)

    # Ruby's Exception#backtrace: innermost first, "FILE:LINE:in 'FUNCTION'".
    def backtrace(main_path)
      callers = ["<main>", *frames.map(&:first)]
      [["#{file || main_path}:#{line}", callers.last],
       *frames.each_with_index.reverse_each.map { |(_, l, f), i| ["#{f || main_path}:#{l}", callers[i]] }]
        .map { |at, fn| "#{at}:in '#{fn}'" }
    end

    MAX_FRAMES = 12

    # frames: [callee, call line], outermost first.
    def report
      callers = ["<main>", *frames.map(&:first)]
      s = +"#{file || path}:#{line}: in #{callers.last}: #{kind}: #{op ? "#{op}: " : ""}#{message}"
      shown = frames.each_with_index.reverse_each.to_a
      if shown.size > MAX_FRAMES
        omitted = shown.size - MAX_FRAMES
        shown = shown.first(MAX_FRAMES - 2) + [nil] + shown.last(2)
      end
      shown.each do |(_, l, f), i|
        s << (i ? "\n  from #{f || path}:#{l}: in #{callers[i]}" : "\n  ... #{omitted} frames omitted ...")
      end
      hints.each { |h| s << "\n  hint: #{h}" }
      s
    end
  end
end
