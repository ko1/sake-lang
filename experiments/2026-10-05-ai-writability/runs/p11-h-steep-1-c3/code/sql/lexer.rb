# frozen_string_literal: true

require_relative "error"

module Sql
  # kind is :keyword (text upper-cased), :ident (text as written, quotes removed), :number,
  # :string, :op, :error (a character or unterminated literal the grammar lacks) or :eof.
  class Token
    attr_reader :kind, :text

    def initialize(kind, text)
      @kind = kind
      @text = text
    end

    def keyword?(word)
      @kind == :keyword && @text == word
    end

    def op?(symbol)
      @kind == :op && @text == symbol
    end
  end

  # Splits a script into statements (token lists ending in an :eof token) at each ';'
  # that is outside literals, quoted identifiers and comments.
  class Lexer
    KEYWORDS = %w[
      ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLUMN COMMIT CREATE CROSS CURRENT DEFAULT
      DELETE DESC DISTINCT DROP ELSE END EXCEPT EXISTS FIRST FOLLOWING FROM GROUP HAVING IF IN INDEX
      INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT NULL NULLS OFFSET ON OR ORDER
      OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE RENAME ROLLBACK ROW ROWS SELECT SET TABLE
      THEN TO TRANSACTION UNBOUNDED UNION UNIQUE UPDATE USING VALUES VIEW WHEN WHERE WINDOW WITH
    ].to_h { |word| [word, true] }

    TWO_CHAR_OPS = %w[|| <= >= <> != ==].freeze
    ONE_CHAR_OPS = %w[+ - * / % = < > ( ) , ; .].freeze

    def initialize(source)
      @source = source
      @pos = 0
    end

    def statements
      result = [] #: Array[Array[Token]]
      current = [] #: Array[Token]
      while (token = next_token)
        if token.op?(";")
          unless current.empty?
            current << Token.new(:eof, "")
            result << current
            current = []
          end
        else
          current << token
        end
      end
      unless current.empty?
        current << Token.new(:eof, "")
        result << current
      end
      result
    end

    private

    # The character at the offset from the cursor, or "" past the end.
    def char(offset = 0)
      @source[@pos + offset].to_s
    end

    def digit?(c)
      c.match?(/\A[0-9]\z/)
    end

    def next_token
      skip_blank
      c = char
      return nil if c.empty?

      if c.match?(/\A[A-Za-z_]\z/)
        word
      elsif digit?(c) || (c == "." && digit?(char(1)))
        number
      elsif c == "'"
        quoted("'", :string)
      elsif c == '"'
        quoted('"', :ident)
      else
        operator
      end
    end

    def skip_blank
      loop do
        c = char
        if c == " " || c == "\t" || c == "\n" || c == "\r"
          @pos += 1
        elsif c == "-" && char(1) == "-"
          @pos += 1 until char.empty? || char == "\n"
        elsif c == "/" && char(1) == "*"
          @pos += 2
          @pos += 1 until char.empty? || (char == "*" && char(1) == "/")
          @pos += 2 unless char.empty?
        else
          return
        end
      end
    end

    def word
      start = @pos
      @pos += 1 while char.match?(/\A[A-Za-z0-9_]\z/)
      text = @source[start, @pos - start].to_s
      upper = text.upcase
      KEYWORDS.key?(upper) ? Token.new(:keyword, upper) : Token.new(:ident, text)
    end

    def number
      start = @pos
      @pos += 1 while digit?(char)
      if char == "."
        @pos += 1
        @pos += 1 while digit?(char)
      end
      if char == "e" || char == "E"
        sign = char(1) == "+" || char(1) == "-" ? 1 : 0
        if digit?(char(1 + sign))
          @pos += 1 + sign
          @pos += 1 while digit?(char)
        end
      end
      Token.new(:number, @source[start, @pos - start].to_s)
    end

    # A literal or quoted identifier delimited by quote, where a doubled quote stands for one.
    def quoted(quote, kind)
      @pos += 1
      text = +""
      loop do
        c = char
        return Token.new(:error, text) if c.empty?

        if c == quote && char(1) == quote
          text << quote
          @pos += 2
        elsif c == quote
          @pos += 1
          return Token.new(kind, text)
        else
          text << c
          @pos += 1
        end
      end
    end

    def operator
      two = char + char(1)
      if TWO_CHAR_OPS.include?(two)
        @pos += 2
        return Token.new(:op, two)
      end
      one = char
      @pos += 1
      ONE_CHAR_OPS.include?(one) ? Token.new(:op, one) : Token.new(:error, one)
    end
  end
end
