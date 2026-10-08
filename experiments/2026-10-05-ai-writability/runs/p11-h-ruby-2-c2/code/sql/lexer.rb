# frozen_string_literal: true

require 'strscan'
require_relative 'errors'
require_relative 'values'

module SQL
  Token = Struct.new(:type, :value)
  # types: :kw (value upcased), :id (value as written, unquoted), :int, :real, :str, :blob, :op

  module Lexer
    KEYWORDS = %w[
      ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLUMN COMMIT CREATE CROSS CURRENT DEFAULT
      DELETE DESC DISTINCT DROP ELSE END EXCEPT EXISTS FIRST FOLLOWING FROM GROUP HAVING IF IN INDEX
      INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT NULL NULLS OFFSET ON OR ORDER
      OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE RENAME ROLLBACK ROW ROWS SELECT SET TABLE
      THEN TO TRANSACTION UNBOUNDED UNION UNIQUE UPDATE USING VALUES VIEW WHEN WHERE WINDOW WITH
    ].to_h { |k| [k, true] }.freeze

    SKIP = %r{(?:[ \t\n\r]+|--[^\n]*|/\*.*?\*/)+}m
    NUMBER = /(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/
    OPERATORS = /\|\||<=|>=|==|!=|<>|[-+*\/%=<>(),;.]/

    module_function

    # Cut a script into statement texts at each `;` outside literals, quoted names and comments.
    def split_statements(script)
      ss = StringScanner.new(script)
      stmts = []
      start = 0
      until ss.eos?
        if ss.skip(/'(?:[^']|'')*'|"(?:[^"]|"")*"|--[^\n]*|\/\*.*?\*\/|[^;'"\-\/]+|[-\/]/m)
          next
        elsif ss.skip(/;/)
          stmts << script[start...ss.pos]
          start = ss.pos
        else
          ss.getch # unterminated literal or comment: the rest is one broken statement
        end
      end
      stmts << script[start..] unless script[start..].strip.empty?
      stmts
    end

    # Tokens of one statement text (without a trailing `;` token). Raises a syntax error
    # on a character that starts no token.
    def tokenize(text)
      ss = StringScanner.new(text)
      tokens = []
      until ss.eos?
        next if ss.skip(SKIP)

        if (s = ss.scan(/[xX]'[^']*'/))
          tokens << blob_token(s)
        elsif (s = ss.scan(/[A-Za-z_][A-Za-z0-9_]*/))
          up = s.upcase
          tokens << (KEYWORDS[up] ? Token.new(:kw, up) : Token.new(:id, s))
        elsif (s = ss.scan(NUMBER))
          tokens << number_token(s)
        elsif (s = ss.scan(/'(?:[^']|'')*'/m))
          tokens << Token.new(:str, s[1..-2].gsub("''", "'"))
        elsif (s = ss.scan(/"(?:[^"]|"")*"/m))
          tokens << Token.new(:id, s[1..-2].gsub('""', '"'))
        elsif (s = ss.scan(OPERATORS))
          tokens << Token.new(:op, s)
        else
          raise SqlError.syntax
        end
      end
      tokens.pop if tokens.last&.type == :op && tokens.last.value == ';'
      tokens
    end

    # X'<hex digits>': an even number of hexadecimal digits, two per byte (7.1).
    def blob_token(s)
      digits = s[2..-2]
      raise SqlError.syntax unless digits.match?(/\A(?:\h\h)*\z/)

      Token.new(:blob, Blob.new([digits].pack('H*')))
    end

    def number_token(s)
      if s.match?(/[.eE]/)
        Token.new(:real, Values.number_from_literal(s))
      else
        n = Integer(s, 10)
        Values.int64?(n) ? Token.new(:int, n) : Token.new(:real, n.to_f)
      end
    end
  end
end

