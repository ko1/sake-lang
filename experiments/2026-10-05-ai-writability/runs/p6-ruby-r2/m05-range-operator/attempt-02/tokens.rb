# Tokens, and the tables of words and operators the lexer and parser share.

# type:  :int, :str, :interp, :ident, :kw, :op, :newline or :eof.
# text:  the source spelling; for :eof, "" at the end of the input and "}" at the
#        end of a string interpolation; "" for :str and :interp.
# value: the Integer of an :int, the String of a :str, and for an :interp the parts:
#        Strings and token Arrays (each ending with a "}" :eof token); nil otherwise.
# pos:   the position of the token's first character.
Token = Struct.new(:type, :text, :value, :pos)

KEYWORDS = %w[
  and assert break catch const continue do elif else end false finally fn for if in
  let match nil not or return then throw true try when while
]

THREE_CHAR_OPERATORS = ["..<"]
RANGE_OPERATORS = ["..", "..<"]
TWO_CHAR_OPERATORS = ["..", "**", "==", "!=", "<=", ">=", "+=", "-=", "*=", "/=", "%="]
ONE_CHAR_OPERATORS = ["+", "-", "*", "/", "%", "(", ")", "[", "]", "{", "}", ",", ":", ";", "=", "<", ">", "."]

ASSIGNMENT_OPERATORS = ["=", "+=", "-=", "*=", "/=", "%="]
# `in` is a keyword, but it is also a comparison operator (`x in xs`).
COMPARISON_OPERATORS = ["==", "!=", "<", "<=", ">", ">=", "in"]
ADDITIVE_OPERATORS = ["+", "-"]
MULTIPLICATIVE_OPERATORS = ["*", "/", "%"]

# Keywords that close a statement list; a statement may end right before one.
BLOCK_END_KEYWORDS = %w[end elif else catch finally when]

# A line that ends with one of these continues on the next line.
CONTINUATION_OPERATORS = [
  "+", "-", "*", "/", "%", "**", "==", "!=", "<", "<=", ">", ">=",
  "=", "+=", "-=", "*=", "/=", "%=", ",", ".", "..", "..<"
]
CONTINUATION_KEYWORDS = %w[and or not in]

OPENING_BRACKETS = ["(", "[", "{"]
CLOSING_BRACKETS = [")", "]", "}"]

module Tokens
  module_function

  def op?(tok, text) = tok.type == :op && tok.text == text

  def kw?(tok, word) = tok.type == :kw && tok.text == word

  # How a syntax error message names a token: "'then'", "'+'", "string", "end of line".
  def describe(tok)
    case tok.type
    when :eof then tok.text == "" ? "end of input" : "'}'"
    when :newline then "end of line"
    when :str, :interp then "string"
    else "'#{tok.text}'"
    end
  end
end
