class Paragraph
  attr_reader :indent, :bullet, :words

  def initialize(indent, bullet, words)
    @indent = indent
    @bullet = bullet
    @words = words
  end
end

def sample_text
  "Sake keeps the syntax of Ruby but writes the type on every operation.\n" \
  "This makes the program a little longer, yet every call says exactly which code runs.\n" \
  "\n" \
  "* Wrapping text is a classic exercise that is surprisingly full of corner cases.\n" \
  "* Extraordinarily-long-hyphenated-identifiers-must-be-split-somewhere when they exceed the width.\n" \
  "\n" \
  "  An indented paragraph keeps its indentation on every wrapped line, which matters for quoted text."
end

def parse_paragraphs(text)
  paras = []
  current = nil
  text.split("\n").each do |line|
    if line.strip.empty?
      current = nil
      next
    end
    stripped = line.lstrip
    indent = line.size - stripped.size
    bullet = stripped.start_with?("* ")
    body = bullet ? stripped[2..].lstrip : stripped
    if current.nil? || bullet
      current = Paragraph.new(indent, bullet, [])
      paras << current
    end
    current.words.concat(body.split(" "))
  end
  paras
end

def split_long(word, width)
  pieces = []
  rest = word
  while rest.size > width
    pieces << rest[0...width]
    rest = rest[width..]
  end
  pieces << rest unless rest.empty?
  pieces
end

def wrap_words(words, width)
  lines = []
  line = ""
  words.each do |w|
    split_long(w, width).each do |piece|
      if line.empty?
        line = piece
      elsif line.size + 1 + piece.size <= width
        line = line + " " + piece
      else
        lines << line
        line = piece
      end
    end
  end
  lines << line unless line.empty?
  lines
end

def render(paras, width)
  out = []
  paras.each_with_index do |para, i|
    out << "" if i > 0 && !para.bullet
    pad = " " * para.indent
    first_prefix = para.bullet ? pad + "* " : pad
    rest_prefix = para.bullet ? pad + "  " : pad
    inner = width - first_prefix.size
    lines = wrap_words(para.words, inner)
    lines.each_with_index do |l, j|
      out << (j == 0 ? first_prefix : rest_prefix) + l
    end
  end
  out
end

def ruler(width)
  marks = +""
  1.upto(width) { |i| marks << (i % 10 == 0 ? (i / 10 % 10).to_s : ".") }
  marks
end

paras = parse_paragraphs(sample_text)
puts "paragraphs: #{paras.size}"
[28, 45].each do |width|
  puts ruler(width)
  lines = render(paras, width)
  lines.each { |l| puts l.rstrip }
  longest = lines.map(&:size).max
  puts "-- width #{width}: #{lines.size} lines, longest #{longest}"
end
