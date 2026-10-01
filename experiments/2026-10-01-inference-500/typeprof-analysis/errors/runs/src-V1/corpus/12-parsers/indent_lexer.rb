class Tok
  attr_reader :kind, :text, :line

  def initialize(kind, text, line)
    @kind = kind
    @text = text
    @line = line
  end
end

class Outline
  attr_reader :header, :children

  def initialize(header)
    @header = header
    @children = []
  end

  def depth = children.empty? ? 0 : 1 + children.map(&:depth).max
end

class IndentError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

def lex(src)
  tokens = []
  levels = [0]
  src.each_line(chomp: true).with_index(1) do |line, lineno|
    next if line.strip.empty? || line.lstrip.start_with?("#")
    lead = line.size - line.lstrip.size
    raise IndentError.new("tab in indentation", lineno) if line[0...lead].include?("\t")
    if lead > levels.last
      levels.push(lead)
      tokens << Tok.new(:indent, "", lineno)
    else
      while lead < levels.last
        levels.pop
        tokens << Tok.new(:dedent, "", lineno)
      end
      raise IndentError.new("dedent to column #{lead} matches no outer level", lineno) if lead != levels.last
    end
    tokens << Tok.new(:line, line.strip, lineno)
  end
  (levels.size - 1).times { tokens << Tok.new(:dedent, "", 0) }
  tokens
end

def build(tokens)
  root = Outline.new("<root>")
  stack = [root]
  last = nil
  tokens.each do |t|
    case t.kind
    when :line
      last = Outline.new(t.text)
      stack.last.children << last
    when :indent
      raise IndentError.new("unexpected indent", t.line) if last.nil?
      stack.push(last)
      last = nil
    when :dedent
      stack.pop
    end
  end
  root
end

def print_outline(node, depth)
  node.children.each do |child|
    n = child.children.size
    puts "#{"  " * depth}- #{child.header}#{n > 0 ? " (#{n})" : ""}"
    print_outline(child, depth + 1)
  end
end

SOURCES = [
  ["config", "server:\n  host: example.org\n  ports:\n    - 80\n    - 443\n  # comment\n\nclient:\n  retries: 3\n"],
  ["code", "def main():\n    for x in xs:\n        if x:\n            print(x)\n    return 0\nmain()\n"],
  ["bad dedent", "a:\n    b\n  c\n"],
  ["tabs", "a:\n\tb\n"],
  ["orphan", "  starts indented\nnext\n"]
]

SOURCES.each do |name, src|
  puts "== #{name}"
  begin
    tokens = lex(src)
    kinds = tokens.map { |t| t.kind == :line ? "L#{t.line}" : t.kind.to_s }
    puts "tokens: #{kinds.join(" ")}"
    root = build(tokens)
    print_outline(root, 0)
    puts "depth: #{root.depth}"
  rescue IndentError => e
    puts "indent error on line #{e.line}: #{e.message}"
  end
end
