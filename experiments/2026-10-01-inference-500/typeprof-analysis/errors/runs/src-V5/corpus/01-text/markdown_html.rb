class Block
  attr_reader :kind, :lines, :level

  def initialize(kind, lines, level)
    @kind = kind
    @lines = lines
    @level = level
  end
end

def escape_html(s)
  s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end

def inline(text)
  out = +""
  rest = text
  while (m = rest.match(/`([^`]+)`/)) && m
    out << format_spans(m.pre_match) << "<code>" << escape_html(m[1]) << "</code>"
    rest = m.post_match
  end
  out << format_spans(rest)
end

def format_spans(text)
  escape_html(text)
    .gsub(/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    .gsub(/\*(.+?)\*/, "<em>\\1</em>")
    .gsub(/\[([^\]]+)\]\(([^)\s]+)\)/, "<a href=\"\\2\">\\1</a>")
end

def classify(line)
  case line
  when /\A```/ then :fence
  when /\A\#{1,6} / then :heading
  when /\A\s*[-*] / then :bullet
  when /\A\s*\d+\. / then :numbered
  when /\A> ?/ then :quote
  when /\A\s*\z/ then :blank
  else :text
  end
end

LIST_KINDS = { bullet: :ul, numbered: :ol, quote: :quote, text: :para }.freeze

def blocks_of(source)
  blocks = []
  in_code = false
  prev_blank = false
  source.split("\n").each do |line|
    kind = classify(line)
    current = blocks.last
    if in_code
      if kind == :fence
        in_code = false
      else
        current.lines << line
      end
      next
    end
    after_blank = prev_blank
    prev_blank = kind == :blank
    case kind
    when :fence
      in_code = true
      blocks << Block.new(:code, [], 0)
    when :heading
      hashes = line[/\A(#+) /, 1]
      blocks << Block.new(:heading, [line[hashes.size..].strip], hashes.size)
    when :blank
      nil
    else
      item = line.sub(/\A\s*([-*]|\d+\.|>) ?/, "")
      list_kind = LIST_KINDS[kind]
      if current && current.kind == list_kind && kind != :text
        current.lines << item
      elsif current && current.kind == :para && kind == :text && !after_blank
        current.lines << item
      else
        blocks << Block.new(list_kind, [item], 0)
      end
    end
  end
  blocks
end

def render(block)
  lines = block.lines
  case block.kind
  when :heading then "<h#{block.level}>#{inline(lines[0])}</h#{block.level}>"
  when :para then "<p>#{inline(lines.join(" "))}</p>"
  when :quote then "<blockquote>#{inline(lines.join(" "))}</blockquote>"
  when :code then "<pre><code>" + escape_html(lines.join("\n")) + "</code></pre>"
  when :ul, :ol
    items = lines.map { |l| "  <li>#{inline(l)}</li>" }
    "<#{block.kind}>\n" + items.join("\n") + "\n</#{block.kind}>"
  end
end

def document
  "# Release *notes* for v2\n" \
  "\n" \
  "This release makes **operations** carry their type & removes `x.y` calls.\n" \
  "See [the tutorial](docs/tutorial.md) for <details>.\n" \
  "\n" \
  "## Changes\n" \
  "- Added `Array.tally`\n" \
  "- Fixed **nil** hints\n" \
  "* Faster *startup*\n" \
  "\n" \
  "1. Install\n" \
  "2. Run `sake --strict=0 a.sake`\n" \
  "\n" \
  "> Types belong on operations,\n" \
  "> not on variables.\n" \
  "\n" \
  "```\n" \
  "puts(String.upcase(\"<b>\"))\n" \
  "  # indented & kept\n" \
  "```\n" \
  "Final words."
end

blocks = blocks_of(document)
blocks.each { |b| puts render(b) }
counts = blocks.map(&:kind).tally
puts "<!-- " + counts.map { |k, n| "#{k}:#{n}" }.join(" ") + " -->"
