# frozen_string_literal: true

require_relative "errors"
require_relative "token"

module Mini
  # Turns program text into tokens (SPEC section 2).
  #
  # Newlines become :newline tokens only where they can end a statement: not
  # inside brackets, not after a token that cannot end an expression, and never
  # two in a row. A string literal becomes one :string token whose
  # interpolations are lexed into nested token lists.
  class Lexer
    # Longest first, so that the first match is the longest one.
    OPERATORS = %w[** == != <= >= += -= *= /= %= + - * / % < > = ( ) [ ] { } , : ; .].freeze
    CONTINUATION_OPERATORS = %w[+ - * / % ** == != < <= > >= = += -= *= /= %= , .].to_set.freeze
    CONTINUATION_KEYWORDS = %w[and or not in].to_set.freeze
    OPENERS = ["(", "[", "{"].freeze
    CLOSERS = [")", "]", "}"].freeze
    ESCAPES = { "n" => "\n", "t" => "\t", "\\" => "\\", "\"" => "\"", "{" => "{", "}" => "}" }.freeze

    def initialize(source)
      @chars = source.chars
      @index = 0
      @line = 1
      @col = 1
    end

    def tokenize
      tokens = []
      nesting = 0
      loop do
        skip_blanks
        char = current
        if char.nil?
          tokens << Token.new(:eof, "", position)
          return tokens
        elsif char == "#"
          advance while current && current != "\n"
        elsif char == "\n"
          newline = Token.new(:newline, "", position)
          advance
          tokens << newline if nesting.zero? && can_end_statement?(tokens.last)
        else
          token = scan_token
          if token.op?(*OPENERS)
            nesting += 1
          elsif token.op?(*CLOSERS) && nesting.positive?
            nesting -= 1
          end
          tokens << token
        end
      end
    end

    private

    def current = @chars[@index]

    def peek_char(offset) = @chars[@index + offset]

    def position = Position.new(@line, @col)

    def advance(count = 1)
      count.times do
        if @chars[@index] == "\n"
          @line += 1
          @col = 1
        else
          @col += 1
        end
        @index += 1
      end
    end

    def skip_blanks
      advance while [" ", "\t", "\r"].include?(current)
    end

    # Whether a newline after `token` ends a statement (SPEC section 2.2).
    def can_end_statement?(token)
      return false if token.nil? || token.type == :newline
      return false if token.type == :op && CONTINUATION_OPERATORS.include?(token.text)
      return false if token.type == :keyword && CONTINUATION_KEYWORDS.include?(token.text)

      true
    end

    def digit?(char) = !char.nil? && char >= "0" && char <= "9"

    def name_start?(char) = !char.nil? && ((char >= "a" && char <= "z") || (char >= "A" && char <= "Z") || char == "_")

    def name_char?(char) = name_start?(char) || digit?(char)

    def source_since(start_index) = @chars[start_index...@index].join

    # One token starting at the current character (not white space, newline
    # or comment). `#` falls through to "unexpected character", which is
    # what an interpolation needs.
    def scan_token
      char = current
      start = position
      if digit?(char)
        scan_int(start)
      elsif name_start?(char)
        scan_word(start)
      elsif char == "\""
        scan_string(start)
      elsif (op = OPERATORS.find { |candidate| operator_here?(candidate) })
        advance(op.length)
        Token.new(:op, op, start)
      else
        raise LexicalError.new("unexpected character '#{char}'", start)
      end
    end

    def operator_here?(op) = op.each_char.with_index.all? { |c, i| peek_char(i) == c }

    # Digits with single underscores between two digits (`1_000`).
    def scan_int(start)
      start_index = @index
      loop do
        if digit?(current)
          advance
        elsif current == "_" && digit?(peek_char(1))
          advance
        else
          break
        end
      end
      text = source_since(start_index)
      Token.new(:int, text, start, text.delete("_").to_i)
    end

    def scan_word(start)
      start_index = @index
      advance while name_char?(current)
      text = source_since(start_index)
      Token.new(KEYWORDS.include?(text) ? :keyword : :name, text, start)
    end

    # The opening quote is the current character. A string must end on its
    # line; running out of line (also inside an interpolation) reports the
    # innermost string still open.
    def scan_string(quote)
      start_index = @index
      advance
      parts = []
      text = +""
      loop do
        char = current
        raise LexicalError.new("unterminated string", quote) if char.nil? || char == "\n"

        case char
        when "\""
          advance
          break
        when "\\"
          text << scan_escape(quote)
        when "{"
          advance
          parts << text unless text.empty?
          text = +""
          parts << scan_interpolation(quote)
        else
          text << char
          advance
        end
      end
      parts << text unless text.empty? && !parts.empty?
      Token.new(:string, source_since(start_index), quote, parts)
    end

    def scan_escape(quote)
      backslash = position
      advance
      char = current
      raise LexicalError.new("unterminated string", quote) if char.nil? || char == "\n"
      raise LexicalError.new("invalid escape '\\#{char}'", backslash) unless ESCAPES.key?(char)

      advance
      ESCAPES[char]
    end

    # The tokens of an interpolation, up to and including the `}` that does
    # not close a `{` opened inside it.
    def scan_interpolation(quote)
      tokens = []
      braces = 0
      loop do
        skip_blanks
        char = current
        raise LexicalError.new("unterminated string", quote) if char.nil? || char == "\n"

        if char == "}" && braces.zero?
          tokens << Token.new(:interp_end, "}", position)
          advance
          return tokens
        end
        token = scan_token
        braces += 1 if token.op?("{")
        braces -= 1 if token.op?("}")
        tokens << token
      end
    end
  end
end
