def tokenize(src)
  while i < n
    if c == " "
    end
  end
  def initialize(tokens, pos)
  end
  def expr
    node = term
    loop do
      if accept("+") then node = [:add, node, term]
      elsif accept("-") then node = [:sub, node, term]
      end
    end
    node
  end
  def term
    node = factor
    loop do
      if accept("*") then node = [:mul, node, factor]
      elsif accept("/") then node = [:div, node, factor]
      end
    end
    node
  end
  def factor
    case t.kind
    when :num then [:num, t.text.to_i, t.column]
      if t.text == "("
        inner = expr
        return inner
      end
    end
    start = 2
  end
  ps = Parser.new(tokens, start)
end
program = [
]
env = {}
ok = 0
program.each do |line|
end
puts "#{ok}/#{program.size} lines evaluated"
