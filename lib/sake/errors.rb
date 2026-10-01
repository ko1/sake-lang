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
    attr_reader :kind, :line, :frames, :expected
    attr_accessor :path, :hints

    def initialize(kind, message, line, frames = [], expected: nil, nil_value: false, hints: [])
      @kind = kind
      @line = line
      @frames = frames
      @expected = expected
      @nil_value = nil_value
      @hints = hints
      super(message)
    end

    def nil_value? = @nil_value

    attr_accessor :value

    MAX_FRAMES = 12

    # frames: [callee, call line], outermost first.
    def report
      callers = ["<main>", *frames.map(&:first)]
      s = +"#{path}:#{line}: in #{callers.last}: #{kind}: #{message}"
      shown = frames.each_with_index.reverse_each.to_a
      if shown.size > MAX_FRAMES
        omitted = shown.size - MAX_FRAMES
        shown = shown.first(MAX_FRAMES - 2) + [nil] + shown.last(2)
      end
      shown.each do |(_, l), i|
        s << (i ? "\n  from #{path}:#{l}: in #{callers[i]}" : "\n  ... #{omitted} frames omitted ...")
      end
      hints.each { |h| s << "\n  hint: #{h}" }
      s
    end
  end
end
