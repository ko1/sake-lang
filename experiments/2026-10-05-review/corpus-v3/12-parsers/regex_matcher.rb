class Node
  attr_accessor :kind, :chars, :negate, :quant

  def initialize(kind, chars, negate, quant)
    @kind = kind
    @chars = chars
    @negate = negate
    @quant = quant
  end

  def single?(c)
    return false if c.nil?
    case @kind
    when :char then @chars == c
    when :any then c != "\n"
    when :class then @chars.include?(c) != @negate
    end
  end

  def to_s
    body = case @kind
           when :char then @chars
           when :any then "."
           when :bol then "^"
           when :eol then "$"
           when :class then "[#{@negate ? "^" : ""}#{@chars}]"
           end
    suffix = { one: "", star: "*", plus: "+", opt: "?" }[@quant]
    body + suffix
  end
end

class PatternError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

def expand_range(a, b) = (a.ord..b.ord).map(&:chr).join

def compile(pat)
  nodes = []
  i = 0
  n = pat.size
  while i < n
    c = pat[i]
    if c == "^" && i == 0
      nodes << Node.new(:bol, "", false, :one)
    elsif c == "$" && i == n - 1
      nodes << Node.new(:eol, "", false, :one)
    elsif c == "."
      nodes << Node.new(:any, "", false, :one)
    elsif c == "["
      start = i
      i += 1
      negate = pat[i] == "^"
      i += 1 if negate
      chars = +""
      while pat[i] != "]"
        raise PatternError.new("unterminated character class", start) if pat[i].nil?
        if pat[i + 1] == "-" && pat[i + 2] && pat[i + 2] != "]"
          chars << expand_range(pat[i], pat[i + 2])
          i += 3
        else
          chars << pat[i]
          i += 1
        end
      end
      nodes << Node.new(:class, chars, negate, :one)
    elsif c == "\\"
      i += 1
      e = pat[i]
      raise PatternError.new("trailing backslash", i - 1) if e.nil?
      nodes << case e
               when "d" then Node.new(:class, "0123456789", false, :one)
               when "w" then Node.new(:class, expand_range("a", "z") + expand_range("A", "Z") + expand_range("0", "9") + "_", false, :one)
               else Node.new(:char, e, false, :one)
               end
    elsif "*+?".include?(c)
      last = nodes.last
      if last.nil? || last.quant != :one || last.kind == :bol
        raise PatternError.new("nothing to repeat", i)
      end
      last.quant = { "*" => :star, "+" => :plus, "?" => :opt }[c]
    else
      nodes << Node.new(:char, c, false, :one)
    end
    i += 1
  end
  nodes
end

def match_here(nodes, ni, s, si)
  return si if ni == nodes.size
  node = nodes[ni]
  case node.kind
  when :bol then return si == 0 ? match_here(nodes, ni + 1, s, si) : nil
  when :eol then return si == s.size ? match_here(nodes, ni + 1, s, si) : nil
  end
  q = node.quant
  if q == :one
    return nil unless node.single?(s[si])
    return match_here(nodes, ni + 1, s, si + 1)
  end
  max = q == :opt ? 1 : s.size - si
  k = 0
  k += 1 while k < max && node.single?(s[si + k])
  min = q == :plus ? 1 : 0
  k.downto(min) do |len|
    e = match_here(nodes, ni + 1, s, si + len)
    return e if e
  end
  nil
end

def search(nodes, s)
  (0..s.size).each do |start|
    e = match_here(nodes, 0, s, start)
    return [start, e] if e
  end
  nil
end

def builtin(pat, s)
  m = s.match(Regexp.new(pat))
  m ? [m.begin(0), m.end(0)] : nil
end

CASES = [
  ["abc", "xxabcxx"], ["a.c", "abc adc"], ["^ab*", "abbbc"], ["^ab*", "cab"],
  ["colou?r", "my color"], ["colou?r", "colour!"], ["\\d+", "order 66 now"],
  ["[a-c]+x", "zzbcax"], ["[^aeiou ]+", "a quiet rhythm"], ["\\w+@\\w+\\.com", "mail bob@example.com!"],
  ["a*a*a*b", "aaaaaaaaaaaaaaac"], ["end$", "the end"], ["end$", "endless"], ["x*", ""],
  ["a+b+", "aaabbbccc"], ["\\.\\*", "1.*2"], ["[0-9][0-9]:[0-5][0-9]", "at 23:59 or 7:5"],
  ["*a", "a"], ["ab[cd", "abc"], ["a**", "aa"]
]

agree = 0
CASES.each do |pat, s|
  nodes = compile(pat)
  found = search(nodes, s)
  shape = nodes.map(&:to_s).join(" ")
  result = if found
             a, b = found
             "#{a}..#{b} #{s[a...b].inspect}"
           else
             "no match"
           end
  same = found == builtin(pat, s)
  agree += 1 if same
  puts format("%-24s %-24s %-28s %s", pat, s.inspect, result, same ? "ok" : "DIFFERS [#{shape}]")
rescue PatternError => e
  puts format("%-24s %-24s error at %d: %s", pat, s.inspect, e.pos, e.message)
end
puts "#{agree} results agree with the built-in engine"
