# frozen_string_literal: true

module Mini
  KEYWORDS = %w[
    and assert break catch const continue do elif else end false finally fn for
    if in let match nil not or return then throw true try when while
  ].to_set.freeze

  # A lexical token.
  #
  # type is one of
  #   :int        value is the Integer
  #   :string     value is an Array of parts: Strings (literal text) and
  #               Arrays of Tokens (an interpolation, ending in :interp_end)
  #   :name, :keyword, :op
  #   :newline    a statement-ending newline
  #   :interp_end the `}` that closes an interpolation
  #   :eof
  # text is the source text of the token.
  Token = Struct.new(:type, :text, :position, :value) do
    def op?(*texts) = type == :op && texts.include?(text)

    def keyword?(*texts) = type == :keyword && texts.include?(text)

    # How the token is named in syntax error messages (SPEC section 3.3).
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
