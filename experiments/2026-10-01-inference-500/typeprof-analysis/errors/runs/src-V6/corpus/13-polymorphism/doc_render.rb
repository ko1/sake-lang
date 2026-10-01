module Block
  def render(width) = raise("render not implemented")
  def plain_text = ""
  def kind = "block"

  def word_count = plain_text.split(" ").size
  def height(width) = render(width).size
end

def wrap(text, width, indent)
  lines = []
  line = ""
  text.split(" ").each do |w|
    if line.empty?
      line = w
    elsif line.size + 1 + w.size <= width - indent.size
      line = line + " " + w
    else
      lines << indent + line
      line = w
    end
  end
  lines << indent + line unless line.empty?
  lines
end

class Heading
  include Block
  attr_reader :level, :title
  def initialize(level, title)
    @level = level
    @title = title
  end
  def kind = "h#{@level}"
  def plain_text = @title
  def render(width)
    text = @level == 1 ? @title.upcase : @title
    rule = @level == 1 ? "=" : "-"
    [text, rule * [text.size, width].min]
  end
end

class Paragraph
  include Block
  attr_reader :text
  def initialize(text)
    @text = text
  end
  def kind = "p"
  def plain_text = @text
  def render(width) = wrap(@text, width, "")
end

class Bullets
  include Block
  attr_reader :items
  def initialize(items)
    @items = items
  end
  def kind = "ul"
  def plain_text = @items.join(" ")
  def render(width)
    out = []
    @items.each do |item|
      lines = wrap(item, width, "  ")
      first = lines[0]
      lines[0] = "* " + first.lstrip if first
      out.concat(lines)
    end
    out
  end
end

class Table
  include Block
  attr_reader :header, :rows
  def initialize(header, rows)
    @header = header
    @rows = rows
  end
  def kind = "table"
  def plain_text = @rows.map { |r| r.join(" ") }.join(" ")
  def render(width)
    all = [@header]
    all.concat(@rows)
    widths = (0...@header.size).map { |i| all.map { |r| r[i].size }.max }
    fmt_row = all.map { |r| (0...r.size).map { |i| r[i].ljust(widths[i]) }.join(" | ") }
    sep = widths.map { |w| "-" * w }.join("-+-")
    lines = [fmt_row[0], sep]
    lines.concat(fmt_row.drop(1))
    lines.map { |l| l.size > width ? l[0...width - 1] + ">" : l }
  end
end

class Code
  include Block
  attr_reader :lang, :source
  def initialize(lang, source)
    @lang = lang
    @source = source
  end
  def kind = "code"
  def render(width)
    body = @source.lines.map { |l| "    " + l.chomp }
    ["    [#{@lang}]"].concat(body)
  end
end

def toc(blocks)
  n1 = 0
  n2 = 0
  out = []
  blocks.each do |b|
    next unless b.is_a?(Heading)
    if b.level == 1
      n1 += 1
      n2 = 0
      out << "#{n1}. #{b.title}"
    else
      n2 += 1
      out << "   #{n1}.#{n2} #{b.title}"
    end
  end
  out
end

def render_doc(blocks, width)
  puts "+" + "-" * width + "+"
  blocks.each_with_index do |b, i|
    puts "|" + "".ljust(width) + "|" if i > 0
    b.render(width).each { |l| puts "|" + l.ljust(width) + "|" }
  end
  puts "+" + "-" * width + "+"
end

doc = [
  Heading.new(1, "Sake release notes"),
  Paragraph.new("This release makes operators on user types dispatch through modules, so a type joins Arithmetic or Comparable by including it and defining the operator."),
  Heading.new(2, "Highlights"),
  Bullets.new(["Mixin functions dispatch on the first argument at run time.", "Indexing is an operator too.", "Struct equality compares fields recursively."]),
  Heading.new(2, "Numbers"),
  Table.new(["area", "tests", "status"], [["operators", "212", "pass"], ["modules", "87", "pass"], ["inference", "1290", "3 skipped"]]),
  Heading.new(1, "Example"),
  Code.new("sake", "class Money < {reader: [cents]}\n  include Arithmetic\nend\n"),
  Paragraph.new("Thanks to everyone who reported issues.")
]

puts "== contents =="
toc(doc).each { |l| puts l }

[60, 34].each do |w|
  puts "== width #{w} =="
  render_doc(doc, w)
end

puts "== stats =="
doc.each do |b|
  puts format("%-6s words %3d  height@60 %2d  height@34 %2d", b.kind, b.word_count, b.height(60), b.height(34))
end
total_words = doc.sum(&:word_count)
puts "total words: #{total_words}"
tallest = doc.max_by { |b| b.height(34) }
puts "tallest at 34: #{tallest.kind}" if tallest
kinds = doc.map(&:kind).tally
puts "blocks: #{kinds.map { |k, n| "#{k}=#{n}" }.join(" ")}"
