class Node
  attr_reader :title, :pages, :children

  def initialize(title, pages, children)
    @title = title
    @pages = pages
    @children = children
  end

  def total_pages
    children.empty? ? pages : children.sum(&:total_pages)
  end
end

class OutlineError < StandardError
  attr_reader :line_no

  def initialize(message, line_no)
    super(message)
    @line_no = line_no
  end
end

def parse_outline(text)
  root = Node.new("(root)", 0, [])
  stack = [root]
  text.lines.each_with_index do |raw, i|
    line = raw.chomp
    next if line.strip.empty?
    spaces = line.size - line.lstrip.size
    raise OutlineError.new("odd indentation (#{spaces} spaces)", i + 1) if spaces.odd?
    level = spaces / 2 + 1
    raise OutlineError.new("jumps from level #{stack.size - 1} to #{level}", i + 1) if level > stack.size
    m = line.strip.match(/\A(.*?)\s*\((\d+)p\)\z/)
    title = m ? m[1] : line.strip
    pages = m ? m[2].to_i : 1
    node = Node.new(title, pages, [])
    stack.pop while stack.size > level
    stack.last.children << node
    stack << node
  end
  root
end

def roman(n)
  out = +""
  rest = n
  [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]].each do |v, s|
    while rest >= v
      out << s
      rest -= v
    end
  end
  out
end

def label(scheme, path)
  case scheme
  when :decimal then path.join(".") + "."
  when :legal then "§" + path.join(".")
  when :classic
    n = path.last
    case path.size % 4
    when 1 then roman(n) + "."
    when 2 then (64 + n).chr + "."
    when 3 then n.to_s + "."
    when 0 then (96 + n).chr + ")"
    end
  end
end

def walk(node, path, depth, &block)
  node.children.each_with_index do |child, i|
    child_path = path + [i + 1]
    yield child, child_path, depth
    walk(child, child_path, depth + 1, &block)
  end
end

def toc(root, scheme, width, max_depth)
  lines = []
  page = 1
  walk(root, [], 0) do |node, path, depth|
    if depth < max_depth
      head = "  " * depth + label(scheme, path) + " " + node.title
      num = page.to_s
      dots = width - head.size - num.size - 2
      leader = dots > 0 ? " " + "." * dots + " " : " "
      lines << head + leader + num
    end
    page += node.pages if node.children.empty?
  end
  lines << "-" * width
  lines << "#{page - 1} pages".rjust(width)
  lines
end

def outline_text
  "Introduction (2p)\n" \
  "Language\n" \
  "  Syntax (3p)\n" \
  "  Types\n" \
  "    Values (2p)\n" \
  "    Operations (4p)\n" \
  "      Arithmetic (1p)\n" \
  "      Indexing (1p)\n" \
  "  Errors (2p)\n" \
  "Runtime\n" \
  "  Interpreter (5p)\n" \
  "  Standard library (6p)\n" \
  "Appendix (1p)\n"
end

root = parse_outline(outline_text)
puts "sections: #{root.children.size}, pages: #{root.total_pages}"
[[:decimal, 99], [:classic, 99], [:legal, 2]].each do |scheme, depth|
  puts
  puts "[#{scheme}]"
  toc(root, scheme, 44, depth).each { |l| puts l }
end

puts
["A\n    B\n", "A\n   B\n", "A\n  B\nC\n      D\n"].each do |bad|
  r = parse_outline(bad)
  puts "ok: #{r.children.size} top-level"
rescue OutlineError => e
  puts "line #{e.line_no}: #{e.message}"
end
