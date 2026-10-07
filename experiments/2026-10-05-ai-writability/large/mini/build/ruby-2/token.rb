# Tokens produced by the lexer.
module Mini
  KEYWORDS = %w[
    and assert break catch const continue do elif else end false finally fn for
    if in let match nil not or return then throw true try when while
  ].freeze

  # Keywords at which a block (and so a statement) ends (section 3.1).
  BLOCK_END_KEYWORDS = %w[end elif else catch finally when].freeze

  # Operators and punctuation, longest first so the longest match wins.
  OPERATORS = %w[
    ** == != <= >= += -= *= /= %=
    + - * / % < > = ( ) [ ] { } , : ; .
  ].freeze

  # `type` is one of:
  #   :int      text is the literal as written, `value` its Integer
  #   :name, :keyword, :op
  #   :string   `parts` is a list of Strings (literal text) and token lists
  #             (interpolations; each list ends with the closing '}' token)
  #   :newline, :eof
  Token = Struct.new(:type, :text, :line, :col, :value, :parts) do
    def keyword?(word) = type == :keyword && text == word
    def op?(symbol) = type == :op && text == symbol

    def block_end?
      type == :keyword && BLOCK_END_KEYWORDS.include?(text)
    end

    def separator? = type == :newline || op?(";")

    # How the token is named in syntax error messages (section 3.3).
    def describe
      case type
      when :string then "string"
      when :newline then "end of line"
      when :eof then "end of input"
      else "'#{text}'"
      end
    end
  end
end
