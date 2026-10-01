class Doc
  attr_reader :kind, :text, :indent, :parts

  def initialize(kind, text, indent, parts)
    @kind = kind
    @text = text
    @indent = indent
    @parts = parts
  end

  def +(other) = Doc.new(:concat, "", 0, [self, other])
end

def text(s) = Doc.new(:text, s, 0, [])
def line = Doc.new(:line, " ", 0, [])
def softline = Doc.new(:line, "", 0, [])
def nest(n, d) = Doc.new(:nest, "", n, [d])
def group(d) = Doc.new(:group, "", 0, [d])

def join(docs, sep)
  docs.reduce { |acc, d| acc + sep + d } || text("")
end

def bracket(open, docs, close)
  group(text(open) + nest(2, softline + join(docs, text(",") + line)) + softline + text(close))
end

def fits?(width, items)
  stack = items.reverse
  remaining = width
  while remaining >= 0
    item = stack.pop
    return true if item.nil?
    indent, flat, doc = item
    case doc.kind
    when :text
      remaining -= doc.text.size
    when :line
      return true unless flat
      remaining -= doc.text.size
    when :concat
      doc.parts.reverse_each { |p| stack << [indent, flat, p] }
    when :nest
      stack << [indent + doc.indent, flat, doc.parts[0]]
    when :group
      stack << [indent, true, doc.parts[0]]
    end
  end
  false
end

def render(doc, width)
  out = +""
  col = 0
  stack = [[0, false, doc]]
  until stack.empty?
    indent, flat, d = stack.pop
    case d.kind
    when :text
      out << d.text
      col += d.text.size
    when :line
      if flat
        out << d.text
        col += d.text.size
      else
        out << "\n" << " " * indent
        col = indent
      end
    when :concat
      d.parts.reverse_each { |p| stack << [indent, flat, p] }
    when :nest
      stack << [indent + d.indent, flat, d.parts[0]]
    when :group
      inner = d.parts[0]
      fit = flat || fits?(width - col, [[indent, true, inner]] + stack.reverse)
      stack << [indent, fit, inner]
    end
  end
  out
end

def to_doc(value)
  case value
  when Integer, Float, true, false, nil, String then text(value.inspect)
  when Symbol then text(value.to_s)
  when Array then bracket("[", value.map { |v| to_doc(v) }, "]")
  when Hash
    pairs = value.map { |k, v| group(text("#{k}:") + nest(2, line + to_doc(v))) }
    bracket("{", pairs, "}")
  end
end

def call_doc(name, args) = group(text(name) + bracket("(", args, ")"))

def sample_data
  {
    "name" => "sake",
    "version" => [0, 4, 1],
    "authors" => ["ko1", "a very long contributor name that will not fit", "third"],
    "deps" => { "prism" => ">= 1.0", "racc" => nil },
    "flags" => [true, false, nil],
    "matrix" => [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
  }
end

data = to_doc(sample_data)
[120, 60, 30].each do |w|
  puts "=" * w
  puts render(data, w)
end
puts "=" * 40
expr = call_doc("assert_equal", [
  call_doc("String.upcase", [call_doc("String.strip", [text("name")])]),
  text("\"SAKE\""),
  call_doc("format", [text("\"%s at %d\""), text("where"), text("line_number")])
])
[100, 40, 24].each do |w|
  puts "-- width #{w}"
  puts render(expr, w)
end
