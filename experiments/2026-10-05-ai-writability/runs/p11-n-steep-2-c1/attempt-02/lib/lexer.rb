module MiniSql
  # Splits a script into statements of tokens, ending each statement at a `;` that is outside
  # literals and comments. A character that starts no token becomes a :bad token.
  module Lexer
    KEYWORDS = %w[ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLLATE COLUMN COMMIT CREATE
                  CROSS CURRENT DEFAULT DELETE DESC DISTINCT DROP ELSE END EXCEPT EXISTS FIRST FOLLOWING FROM GROUP
                  HAVING IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT NULL NULLS OFFSET
                  ON OR ORDER OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE RENAME ROLLBACK ROW ROWS SELECT
                  SET TABLE THEN TO TRANSACTION UNBOUNDED UNION UNIQUE UPDATE USING VALUES VIEW WHEN WHERE WINDOW
                  WITH].freeze

    SKIP = %r{\G(?:[ \t\r\n]+|--[^\n]*|/\*.*?(?:\*/|\z))}m
    WORD = /\G[A-Za-z_][A-Za-z0-9_]*/
    NUMBER = /\G(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/
    STRING = /\G'((?:[^']|'')*)'/m
    QUOTED = /\G"((?:[^"]|"")*)"/m
    OPERATOR = %r{\G(?:\|\||<=|>=|<>|!=|==|[-+*/%<>=(),.])}

    def self.statements(source)
      statements = [] # @type var statements: Array[Array[Token]]
      current = [] # @type var current: Array[Token]
      position = 0
      while position < source.length
        if (match = SKIP.match(source, position))
          position += match.to_s.length
        elsif source[position] == ";"
          statements << (current + [Token.new(:eof, "")]) unless current.empty?
          current = []
          position += 1
        else
          token, length = token_at(source, position)
          current << token
          position += length
        end
      end
      statements << (current + [Token.new(:eof, "")]) unless current.empty?
      statements
    end

    # The token starting at position and the number of characters it spans.
    def self.token_at(source, position)
      if (match = WORD.match(source, position))
        word = match.to_s
        upper = word.upcase(:ascii)
        token = KEYWORDS.include?(upper) ? Token.new(:keyword, upper) : Token.new(:ident, word)
        [token, word.length]
      elsif (match = NUMBER.match(source, position))
        [Token.new(:number, match.to_s), match.to_s.length]
      elsif (match = STRING.match(source, position))
        [Token.new(:string, match[1].to_s.gsub("''", "'")), match.to_s.length]
      elsif (match = QUOTED.match(source, position))
        [Token.new(:ident, match[1].to_s.gsub('""', '"')), match.to_s.length]
      elsif (match = OPERATOR.match(source, position))
        [Token.new(:symbol, match.to_s), match.to_s.length]
      else
        [Token.new(:bad, source[position].to_s), 1]
      end
    end
  end
end
