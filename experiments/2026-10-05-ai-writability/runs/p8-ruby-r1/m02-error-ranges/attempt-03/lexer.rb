# Turns Mini source text into tokens (SPEC.md, "Lexical structure").
#
# Newlines end statements, so they are tokens too, but only outside brackets
# (inside ( [ { a newline is just white space) and not after a token that
# needs something to follow it, such as a binary operator or a comma. Several
# newlines in a row make one :newline token. A string with interpolations becomes one :interp token whose
# parts hold the tokens of each embedded expression.
class Lexer
  attr_reader :chars, :tokens
  attr_accessor :index, :line, :col, :nesting

  def initialize(source)
    @chars = source.chars
    @tokens = []
    @index = 0
    @line = 1
    @col = 1
    @nesting = 0
    @prev_line = 1
    @prev_col = 1
  end

  # All tokens of the source, ending with an :eof token whose text is "".
  def run
    while true
      skip_blanks_and_comments
      break if at_end?

      if peek == "\n"
        scan_newline
      else
        tok = scan_token
        track_nesting(tok)
        @tokens.push(tok)
      end
    end
    @tokens.push(Token.new(:eof, "", nil, here))
    @tokens
  end

  private

  def at_end? = @index >= @chars.length

  # The character `offset` places ahead, or "" past the end.
  def peek(offset = 0)
    i = @index + offset
    i < @chars.length ? @chars[i] : ""
  end

  def advance
    c = @chars[@index]
    @prev_line = @line
    @prev_col = @col
    @index += 1
    if c == "\n"
      @line += 1
      @col = 1
    else
      @col += 1
    end
    c
  end

  def here = Pos.new(@line, @col, @line, @col)

  # The range from `pos` to the last character consumed.
  def span_to_last(pos) = Pos.new(pos.line, pos.col, @prev_line, @prev_col)

  def unterminated(start) = Errors.lexical("unterminated string", span_to_last(start))

  def digit?(c) = c >= "0" && c <= "9"

  def ident_start?(c) = (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_"

  def ident_char?(c) = ident_start?(c) || digit?(c)

  def blank?(c) = c == " " || c == "\t" || c == "\r"

  def skip_blanks_and_comments
    until at_end?
      c = peek
      if blank?(c)
        advance
      elsif c == "#"
        advance until at_end? || peek == "\n"
      else
        break
      end
    end
  end

  def skip_blanks
    advance while blank?(peek)
  end

  def scan_newline
    pos = here
    advance
    return if @nesting > 0 || @tokens.empty? || @tokens.last.type == :newline
    return if continues_line?(@tokens.last)

    @tokens.push(Token.new(:newline, "\n", nil, span_to_last(pos)))
  end

  def continues_line?(tok)
    (tok.type == :op && CONTINUATION_OPERATORS.include?(tok.text)) ||
      (tok.type == :kw && CONTINUATION_KEYWORDS.include?(tok.text))
  end

  def track_nesting(tok)
    return unless tok.type == :op

    if OPENING_BRACKETS.include?(tok.text)
      @nesting += 1
    elsif CLOSING_BRACKETS.include?(tok.text) && @nesting > 0
      @nesting -= 1
    end
  end

  # One token starting at the current character, which is not blank or a newline.
  def scan_token
    pos = here
    c = peek
    tok =
      if digit?(c)
        scan_int(pos)
      elsif ident_start?(c)
        scan_word(pos)
      elsif c == "\""
        scan_string(pos)
      else
        scan_operator(pos)
      end
    tok.pos = span_to_last(pos)
    tok
  end

  # Digits, with single underscores allowed between them: 1_000_000.
  def scan_int(pos)
    digits = []
    while digit?(peek) || (peek == "_" && digit?(peek(1)))
      c = advance
      digits.push(c) unless c == "_"
    end
    Token.new(:int, digits.join, digits.join.to_i, pos)
  end

  def scan_word(pos)
    letters = []
    letters.push(advance) while ident_char?(peek)
    word = letters.join
    Token.new(KEYWORDS.include?(word) ? :kw : :ident, word, nil, pos)
  end

  def scan_operator(pos)
    two = peek + peek(1)
    if TWO_CHAR_OPERATORS.include?(two)
      advance
      advance
      Token.new(:op, two, nil, pos)
    elsif ONE_CHAR_OPERATORS.include?(peek)
      Token.new(:op, advance, nil, pos)
    else
      Errors.lexical("unexpected character '#{peek}'", pos)
    end
  end

  # A string literal starting at `start` (its opening quote).
  def scan_string(start)
    advance
    parts = []
    text = []
    while true
      c = peek
      unterminated(start) if c == "" || c == "\n"
      if c == "\""
        advance
        break
      elsif c == "\\"
        text.push(scan_escape(start))
      elsif c == "{"
        advance
        parts.push(text.join) unless text.empty?
        text = []
        parts.push(scan_interpolation(start))
      else
        text.push(advance)
      end
    end
    parts.push(text.join) unless text.empty?
    if parts.all? { |part| part.is_a?(String) }
      Token.new(:str, "", parts.empty? ? "" : parts[0], start)
    else
      Token.new(:interp, "", parts, start)
    end
  end

  def scan_escape(string_start)
    pos = here
    advance
    c = peek
    unterminated(string_start) if c == "" || c == "\n"
    advance
    case c
    when "n" then "\n"
    when "t" then "\t"
    when "\\", "\"", "{", "}" then c
    else Errors.lexical("invalid escape '\\#{c}'", span_to_last(pos))
    end
  end

  # The tokens of one "{...}" inside a string, after its "{". The closing "}"
  # becomes an :eof token with text "}", so the parser can stop there.
  def scan_interpolation(string_start)
    toks = []
    level = 0
    while true
      skip_blanks
      c = peek
      unterminated(string_start) if c == "" || c == "\n"
      if c == "}" && level == 0
        toks.push(Token.new(:eof, "}", nil, here))
        advance
        return toks
      end
      tok = scan_token
      level += 1 if Tokens.op?(tok, "{")
      level -= 1 if Tokens.op?(tok, "}")
      toks.push(tok)
    end
  end
end
