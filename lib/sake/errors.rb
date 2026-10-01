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

  # An error raised while running a Sake program.
  class RunError < Error
    attr_reader :kind, :line, :frames
    attr_accessor :path

    def initialize(kind, message, line, frames = [])
      @kind = kind
      @line = line
      @frames = frames
      super(message)
    end

    # frames: [callee, call line], outermost first.
    def report
      callers = ["<main>", *frames.map(&:first)]
      s = +"#{path}:#{line}: in #{callers.last}: #{kind}: #{message}"
      frames.each_with_index.reverse_each { |(_, l), i| s << "\n  from #{path}:#{l}: in #{callers[i]}" }
      s
    end
  end
end
