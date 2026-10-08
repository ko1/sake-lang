module MiniSql
  # A lexical token. kind is :ident, :keyword (text upper-cased), :number, :string, :symbol,
  # :bad (a character no token starts with) or :eof.
  class Token
    attr_reader :kind, :text

    def initialize(kind, text)
      @kind = kind
      @text = text
    end

    def keyword?(word)
      @kind == :keyword && @text == word
    end

    def symbol?(text)
      @kind == :symbol && @text == text
    end
  end
end
