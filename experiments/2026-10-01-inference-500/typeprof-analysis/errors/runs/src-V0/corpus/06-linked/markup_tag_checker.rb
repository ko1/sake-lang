require "set"

class Frame
  attr_reader :name, :line, :col, :parent

  def initialize(name, line, col, parent)
    @name = name
    @line = line
    @col = col
    @parent = parent
  end

  def path
    parts = []
    node = self
    while node
      parts.unshift(node.name)
      node = node.parent
    end
    parts.join(">")
  end
end

class Issue
  attr_reader :line, :col, :text

  def initialize(line, col, text)
    @line = line
    @col = col
    @text = text
  end
end

VOID_TAGS = Set["br", "img", "hr", "input"].freeze
TAG = /<(\/?)([a-z][a-z0-9]*)[^>]*?(\/?)>/

def check(doc)
  issues = []
  top = nil
  max_depth = 0
  depth = 0
  doc.lines.each_with_index do |line, li|
    pos = 0
    while (m = line[pos..].match(TAG))
      col = pos + m.begin(0) + 1
      closing = m[1] == "/"
      name = m[2]
      self_closing = m[3] == "/" || VOID_TAGS.include?(name)
      if closing
        if top.nil?
          issues << Issue.new(li + 1, col, "stray </#{name}>")
        elsif top.name == name
          top = top.parent
          depth -= 1
        else
          found = top
          found = found.parent while found && found.name != name
          if found
            until top.equal?(found)
              issues << Issue.new(top.line, top.col, "<#{top.name}> not closed before </#{name}>")
              top = top.parent
              depth -= 1
            end
            top = found.parent
            depth -= 1
          else
            issues << Issue.new(li + 1, col, "</#{name}> does not match <#{top.name}>")
          end
        end
      elsif !self_closing
        top = Frame.new(name, li + 1, col, top)
        depth += 1
        max_depth = depth if depth > max_depth
      end
      pos += m.end(0)
    end
  end
  while top
    issues << Issue.new(top.line, top.col, "unclosed <#{top.name}> (path #{top.path})")
    top = top.parent
  end
  [issues, max_depth]
end

docs = [
  ["good", "<html>\n<body><p>Hello <b>world</b></p>\n<img src=x><br/>\n</body>\n</html>\n"],
  ["unclosed", "<div>\n  <ul><li>one</li><li>two\n  </ul>\n"],
  ["stray", "<p>text</p></span>\n<em>ok</em>\n"],
  ["crossed", "<a><b>bold link</a></b>\n"],
  ["deep", "<a><b><c><d><e>x</e></d></c></b></a><hr>\n"],
  ["mismatch", "<section>\n<h1>Title</h2>\n</section>\n"]
]

docs.each do |label, doc|
  issues, depth = check(doc)
  if issues.empty?
    puts "#{label}: ok (max depth #{depth})"
  else
    puts "#{label}: #{issues.size} issue(s), max depth #{depth}"
    issues.sort_by { |i| [i.line, i.col] }.each { |i| puts "  #{i.line}:#{i.col} #{i.text}" }
  end
end
