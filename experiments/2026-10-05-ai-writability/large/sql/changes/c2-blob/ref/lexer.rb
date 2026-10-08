require_relative "errors"
require_relative "values"

# Splits a script into statements and a statement into tokens (spec 1.2).
module Lexer
  KEYWORDS = %w[
    ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLUMN COMMIT CREATE CROSS CURRENT DEFAULT
    DELETE DESC DISTINCT DROP ELSE END EXCEPT EXISTS FIRST FOLLOWING FROM GROUP HAVING IF IN INDEX
    INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT NULL NULLS OFFSET ON OR ORDER
    OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE RENAME ROLLBACK ROW ROWS SELECT SET TABLE
    THEN TO TRANSACTION UNBOUNDED UNION UNIQUE UPDATE USING VALUES VIEW WHEN WHERE WINDOW WITH
  ].to_h { |k| [k, true] }.freeze

  # kind: :keyword (value: upper-case word), :ident (value: the name as written, unquoted),
  # :integer / :real (value: the number), :string (value: the text), :blob (value: a Values::Blob),
  # :op (value: the operator), :eof
  Token = Struct.new(:kind, :value) do
    def keyword?(word) = kind == :keyword && value == word
    def op?(op) = kind == :op && value == op
  end

  OPERATORS = %w[|| == != <> <= >= + - * / % = < > ( ) , .].freeze
  NUMBER = /\G(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?/
  WORD = /\G[A-Za-z_][A-Za-z0-9_]*/
  WORD_CHAR = /\G[A-Za-z0-9_]/

  module_function

  # The statements of a script, each without its ';'. Text after the last ';' is ignored.
  def split_statements(text)
    statements = []
    start = 0
    i = 0
    while i < text.length
      case text[i]
      when "'", '"'
        i = closing_quote(text, i) || text.length
      when "-"
        i = text[i + 1] == "-" ? (text.index("\n", i) || text.length) : i + 1
      when "/"
        i = text[i + 1] == "*" ? comment_end(text, i) : i + 1
      when ";"
        statements << text[start...i]
        start = i + 1
        i += 1
      else
        i += 1
      end
    end
    statements
  end

  # The index just past the quoted text starting at i, or nil if the quote is not closed.
  def closing_quote(text, i)
    quote = text[i]
    j = i + 1
    while j < text.length
      if text[j] == quote
        return j + 1 unless text[j + 1] == quote
        j += 1
      end
      j += 1
    end
    nil
  end

  def comment_end(text, i)
    j = text.index("*/", i + 2)
    j ? j + 2 : text.length
  end

  # The tokens of one statement, ending with an :eof token. Raises SqlError on text that is no token.
  def tokenize(source)
    tokens = []
    i = 0
    while i < source.length
      ch = source[i]
      if " \t\n\r".include?(ch)
        i += 1
      elsif source[i, 2] == "--"
        i = source.index("\n", i) || source.length
      elsif source[i, 2] == "/*"
        i = comment_end(source, i)
      elsif ch == "'" || ch == '"'
        j = closing_quote(source, i) or raise SqlError.syntax
        text = source[i + 1...j - 1].gsub(ch * 2, ch)
        tokens << (ch == "'" ? Token.new(:string, text) : Token.new(:ident, text))
        i = j
      elsif "xX".include?(ch) && source[i + 1] == "'"
        j = closing_quote(source, i + 1) or raise SqlError.syntax
        digits = source[i + 2...j - 1]
        raise SqlError.syntax unless digits.match?(/\A(?:\h\h)*\z/)
        tokens << Token.new(:blob, Values::Blob.of([digits].pack("H*")))
        i = j
      elsif (m = NUMBER.match(source, i)) && (ch =~ /\d/ || m[0].length > 1)
        i += m[0].length
        raise SqlError.syntax if WORD_CHAR.match?(source, i)
        tokens << number_token(m[0])
      elsif (m = WORD.match(source, i))
        word = m[0]
        upper = word.upcase
        tokens << (KEYWORDS[upper] ? Token.new(:keyword, upper) : Token.new(:ident, word))
        i += word.length
      elsif (op = OPERATORS.find { |o| source[i, o.length] == o })
        tokens << Token.new(:op, op)
        i += op.length
      else
        raise SqlError.syntax
      end
    end
    tokens << Token.new(:eof, nil)
  end

  def number_token(text)
    value = Values.literal_number(text)
    Token.new(value.is_a?(Integer) ? :integer : :real, value)
  end
end
