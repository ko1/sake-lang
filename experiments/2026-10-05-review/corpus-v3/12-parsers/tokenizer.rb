require "set"

class Token
  attr_reader :kind, :text, :line, :col

  def initialize(kind, text, line, col)
    @kind = kind
    @text = text
    @line = line
    @col = col
  end

  def to_s = "#{@line}:#{@col} #{@kind.to_s.ljust(8)} #{@text.inspect}"
end

KEYWORDS = Set["if", "else", "while", "return", "let", "fn"]
TWO_CHAR_OPS = ["==", "!=", "<=", ">=", "&&", "||", "->"]
ONE_CHAR_OPS = "+-*/%<>=!(){},;"

def digit?(c) = !c.nil? && c.match?(/\A[0-9]\z/)
def ident_start?(c) = !c.nil? && c.match?(/\A[A-Za-z_]\z/)
def ident_char?(c) = !c.nil? && c.match?(/\A[A-Za-z0-9_]\z/)

def tokenize(src)
  tokens = []
  errors = []
  i = 0
  line = 1
  col = 1
  n = src.size
  while i < n
    c = src[i]
    if c == "\n"
      line += 1
      col = 1
      i += 1
    elsif c == " " || c == "\t"
      i += 1
      col += 1
    elsif c == "/" && src[i + 1] == "/"
      i += 1 while i < n && src[i] != "\n"
    elsif digit?(c)
      start = i
      i += 1 while digit?(src[i])
      kind = :int
      if src[i] == "." && digit?(src[i + 1])
        i += 1
        i += 1 while digit?(src[i])
        kind = :float
      end
      tokens << Token.new(kind, src[start...i], line, col)
      col += i - start
    elsif ident_start?(c)
      start = i
      i += 1 while ident_char?(src[i])
      text = src[start...i]
      kind = KEYWORDS.include?(text) ? :keyword : :ident
      tokens << Token.new(kind, text, line, col)
      col += i - start
    elsif c == "\""
      start = i
      i += 1
      i += 1 while i < n && src[i] != "\"" && src[i] != "\n"
      if src[i] == "\""
        i += 1
        tokens << Token.new(:string, src[(start + 1)...(i - 1)], line, col)
      else
        errors << "#{line}:#{col}: unterminated string"
      end
      col += i - start
    else
      pair = src[i..(i + 1)]
      if TWO_CHAR_OPS.include?(pair)
        tokens << Token.new(:op, pair, line, col)
        i += 2
        col += 2
      elsif ONE_CHAR_OPS.include?(c)
        tokens << Token.new(:op, c, line, col)
        i += 1
        col += 1
      else
        errors << "#{line}:#{col}: unexpected character #{c.inspect}"
        i += 1
        col += 1
      end
    end
  end
  tokens << Token.new(:eof, "", line, col)
  [tokens, errors]
end

def report(name, src)
  puts "== #{name}"
  tokens, errors = tokenize(src)
  tokens.each { |t| puts "  #{t}" }
  errors.each { |e| puts "  error #{e}" }
  kinds = tokens.map(&:kind).tally
  summary = kinds.sort_by { |k, _| k.to_s }.map { |k, v| "#{k}=#{v}" }
  puts "  summary: #{summary.join(" ")}"
end

SOURCES = [
  ["assign", "let x = 42;\nlet y = x * 3.14; // area\n"],
  ["function", "fn max(a, b) {\n  if (a >= b) { return a; } else { return b; }\n}"],
  ["strings", "let s = \"hello\";\nlet t = \"oops\nlet u = s;"],
  ["junk", "x = 1 @ 2 # 3\nwhile (x != 0 && y) -> z"]
]

SOURCES.each { |name, src| report(name, src) }
