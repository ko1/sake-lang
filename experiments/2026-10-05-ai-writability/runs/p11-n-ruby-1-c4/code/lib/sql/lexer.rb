# frozen_string_literal: true

require "strscan"

module Sql
  # type: :kw (value = upper-case keyword), :ident (value = name without quotes), :int, :float,
  # :str, :op (value = the operator text), :bad (a character or literal that cannot start a
  # token; the parser reports it as a syntax error), :eof.
  Token = Data.define(:type, :value)

  module Lexer
    KEYWORDS = %w[ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLUMN COMMIT CREATE CROSS CURRENT
                  DEFAULT DELETE DESC DISTINCT DROP ELSE END EXCEPT EXISTS FIRST FOLLOWING FROM GROUP
                  HAVING IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT
                  NULL NULLS OFFSET ON OR ORDER OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE
                  RENAME ROLLBACK ROW ROWS SELECT SET TABLE THEN TO TRANSACTION UNBOUNDED UNION UNIQUE
                  UPDATE USING VALUES VIEW WHEN WHERE WINDOW WITH].to_h { |k| [k, true] }.freeze

    SKIP = %r{(?:[ \t\n\r]+|--[^\n]*|/\*.*?(?:\*/|\z))}m
    WORD = /[A-Za-z_][A-Za-z0-9_]*/
    NUMBER = /(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/
    STRING = /'(?:[^']|'')*'/m
    QUOTED = /"(?:[^"]|"")*"/m
    OPERATOR = %r{\|\||<=|>=|==|!=|<>|[-+*/%<>=(),;.]}

    module_function

    # Whole script -> array of tokens (without a final :eof).
    def tokenize(source)
      scanner = StringScanner.new(source)
      tokens = []
      until scanner.eos?
        next if scanner.skip(SKIP)
        tokens << next_token(scanner)
      end
      tokens
    end

    def next_token(scanner)
      if (word = scanner.scan(WORD))
        upper = word.upcase
        KEYWORDS.key?(upper) ? Token.new(:kw, upper) : Token.new(:ident, word)
      elsif (text = scanner.scan(NUMBER))
        if text.match?(/[.eE]/)
          Token.new(:float, text.to_f)
        else
          n = text.to_i
          n <= 2**63 ? Token.new(:int, n) : Token.new(:float, text.to_f)
        end
      elsif (text = scanner.scan(STRING))
        Token.new(:str, text[1...-1].gsub("''", "'"))
      elsif (text = scanner.scan(QUOTED))
        Token.new(:ident, text[1...-1].gsub('""', '"'))
      elsif (text = scanner.scan(OPERATOR))
        Token.new(:op, text)
      else
        # unterminated literal or a stray character: consume one character
        Token.new(:bad, scanner.getch)
      end
    end

    # Splits tokens at `;` into statements (arrays of tokens); empty statements are dropped.
    def split_statements(tokens)
      statements = []
      current = []
      tokens.each do |t|
        if t.type == :op && t.value == ";"
          statements << current unless current.empty?
          current = []
        else
          current << t
        end
      end
      statements << current unless current.empty?
      statements
    end
  end
end
