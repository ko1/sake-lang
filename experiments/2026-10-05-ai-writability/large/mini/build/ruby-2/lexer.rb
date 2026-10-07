require_relative "token"
require_relative "errors"

module Mini
  # Turns program text into tokens (section 2).
  #
  # Newline tokens are already filtered here: they are dropped inside brackets,
  # after a token that cannot end an expression, when repeated, and before the
  # first token. The token list always ends with an :eof token.
  class Lexer
    # Tokens after which an expression continues on the next line.
    CONTINUATION_OPS = %w[+ - * / % ** == != < <= > >= = += -= *= /= %= , .].freeze
    CONTINUATION_KEYWORDS = %w[and or not in].freeze

    OPENERS = ["(", "[", "{"].freeze
    CLOSERS = [")", "]", "}"].freeze

    ESCAPES = { "n" => "\n", "t" => "\t", "\\" => "\\", "\"" => "\"", "{" => "{", "}" => "}" }.freeze

    def self.tokenize(source) = new(source).tokenize

    def initialize(source)
      @chars = source.chars
      @pos = 0
      @line = 1
      @col = 1
    end

    def tokenize
      tokens = []
      nesting = 0
      loop do
        skip_blanks_and_comment
        if eof?
          tokens << Token.new(:eof, "", @line, @col)
          return tokens
        end
        if peek == "\n"
          newline = Token.new(:newline, "\n", @line, @col)
          advance
          tokens << newline if newline_counts?(tokens, nesting)
          next
        end
        token = next_token
        if token.type == :op
          nesting += 1 if OPENERS.include?(token.text)
          nesting -= 1 if CLOSERS.include?(token.text) && nesting > 0
        end
        tokens << token
      end
    end

    private

    def newline_counts?(tokens, nesting)
      return false if nesting > 0
      last = tokens.last
      return false if last.nil? || last.type == :newline
      return false if last.type == :op && CONTINUATION_OPS.include?(last.text)
      return false if last.type == :keyword && CONTINUATION_KEYWORDS.include?(last.text)
      true
    end

    def eof? = @pos >= @chars.length
    def peek(offset = 0) = @chars[@pos + offset]

    def advance
      char = @chars[@pos]
      @pos += 1
      if char == "\n"
        @line += 1
        @col = 1
      else
        @col += 1
      end
      char
    end

    def skip_blanks_and_comment
      advance while !eof? && [" ", "\t", "\r"].include?(peek)
      advance while !eof? && peek != "\n" if peek == "#"
    end

    def digit?(char) = char && char >= "0" && char <= "9"
    def name_start?(char) = char && (char.match?(/\A[A-Za-z_]\z/))
    def name_char?(char) = char && (char.match?(/\A[A-Za-z0-9_]\z/))

    # One token that is not a newline; the current character is not blank.
    def next_token
      line = @line
      col = @col
      char = peek
      if digit?(char)
        lex_int(line, col)
      elsif name_start?(char)
        text = +""
        text << advance while name_char?(peek)
        Token.new(KEYWORDS.include?(text) ? :keyword : :name, text, line, col)
      elsif char == "\""
        lex_string
      else
        op = OPERATORS.find { |candidate| @chars[@pos, candidate.length].join == candidate }
        raise LexicalError.new("unexpected character '#{char}'", line, col) unless op
        op.length.times { advance }
        Token.new(:op, op, line, col)
      end
    end

    # Digits, with single underscores allowed between two digits.
    def lex_int(line, col)
      text = +""
      loop do
        text << advance while digit?(peek)
        break unless peek == "_" && digit?(peek(1))
        text << advance
      end
      Token.new(:int, text, line, col, text.delete("_").to_i)
    end

    # A string literal; the current character is its opening quote.
    def lex_string
      line = @line
      col = @col
      start = @pos
      advance
      parts = []
      literal = +""
      loop do
        char = peek
        raise LexicalError.new("unterminated string", line, col) if char.nil? || char == "\n"
        if char == "\""
          advance
          break
        elsif char == "\\"
          escape_line = @line
          escape_col = @col
          advance
          escaped = peek
          raise LexicalError.new("unterminated string", line, col) if escaped.nil? || escaped == "\n"
          unless ESCAPES.key?(escaped)
            raise LexicalError.new("invalid escape '\\#{escaped}'", escape_line, escape_col)
          end
          advance
          literal << ESCAPES[escaped]
        elsif char == "{"
          advance
          parts << literal unless literal.empty?
          literal = +""
          parts << lex_interpolation(line, col)
        else
          literal << advance
        end
      end
      parts << literal unless literal.empty?
      Token.new(:string, @chars[start...@pos].join, line, col, nil, parts)
    end

    # The tokens of an interpolation, up to and including the '}' that ends it.
    # (line, col) is the opening quote of the enclosing string.
    def lex_interpolation(line, col)
      tokens = []
      depth = 0
      loop do
        advance while !eof? && [" ", "\t", "\r"].include?(peek)
        raise LexicalError.new("unterminated string", line, col) if eof? || peek == "\n"
        raise LexicalError.new("unexpected character '#'", @line, @col) if peek == "#"
        token = next_token
        tokens << token
        next unless token.type == :op
        depth += 1 if token.text == "{"
        if token.text == "}"
          return tokens if depth == 0
          depth -= 1
        end
      end
    end
  end
end
