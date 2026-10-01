class Token
  attr_reader :kind, :text, :pos

  def initialize(kind, text, pos)
    @kind = kind
    @text = text
    @pos = pos
  end

  def to_s = "#{@kind}(#{@text})"
end

class LexError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

def char_class(c)
  if !c    
    :eof
  elsif c.match?(/[0-9]/)
    :digit
  elsif c.match?(/[A-Za-z_]/)
    :alpha
  elsif c == "."
    :dot
  elsif "+-*/^%=<>!".include?(c)
    :op
  elsif c == "(" || c == ")"
    :paren
  elsif c == " " || c == "\t"
    :space
  else
    :other
  end
end

TWO_CHAR_OPS = ["<=", ">=", "==", "!=", "**"]

def lex(src)
  tokens = []
  state = :start
  start = 0
  i = 0
  while i <= src.size
    c = src[i]
    cls = char_class(c)
    case state
    in :start
      start = i
      case cls
      in :digit then state = :int
      in :alpha then state = :ident
      in :dot then state = :frac
      in :op
        pair = src[i..i + 1]
        if pair && TWO_CHAR_OPS.include?(pair)
          tokens << Token.new(:op, pair, i)
          i += 1
        else
          tokens << Token.new(:op, c, i)
        end
      in :paren then tokens << Token.new(c == "(" ? :lparen : :rparen, c, i)
      in :space then nil
      in :eof then tokens << Token.new(:eof, "", i)
      in :other then raise LexError.new("unexpected #{c.inspect}", i)
      end
      i += 1
    in :int
      if cls == :digit
        i += 1
      elsif cls == :dot
        state = :frac
        i += 1
      elsif cls == :alpha
        raise LexError.new("letter in number", i)
      else
        tokens << Token.new(:int, src[start...i], start)
        state = :start
      end
    in :frac
      if cls == :digit
        i += 1
      elsif cls == :dot || cls == :alpha
        raise LexError.new("malformed number", i)
      else
        text = src[start...i]
        raise LexError.new("lonely dot", start) if text == "."
        tokens << Token.new(:float, text, start)
        state = :start
      end
    in :ident
      if cls == :alpha || cls == :digit
        i += 1
      else
        text = src[start...i]
        kind = %w[and or not].include?(text) ? :keyword : :ident
        tokens << Token.new(kind, text, start)
        state = :start
      end
    end
  end
  tokens
end

inputs = [
  "x1 = 3.25 * (rate + 12)",
  "a<=b and c!=d",
  "2**10 % 7",
  "count_2 >= .5",
  "1.2.3",
  "total = 4x",
  "price # comment",
  "  ( ( y ) )  "
]
kinds = Hash.new(0)
inputs.each do |src|
  begin
    toks = lex(src)
    toks.each { |t| kinds[t.kind] += 1 }
    puts "#{src.inspect} => #{toks.join(" ")}"
  rescue LexError => e
    puts "#{src.inspect} => error at #{e.pos}: #{e.message}"
    puts "  #{src}"
    puts "  #{" " * e.pos}^"
  end
end
puts "token kinds:"
kinds.keys.sort_by(&:to_s).each { |k| puts format("  %-8s %2d", k, kinds[k]) }
