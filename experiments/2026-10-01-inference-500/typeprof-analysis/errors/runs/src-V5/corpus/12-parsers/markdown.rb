class Block
  attr_reader :kind, :lines, :level

  def initialize(kind, lines, level = 0)
    @kind = kind
    @lines = lines
    @level = level
  end
end

def escape_html(s) = s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")

def inline(s)
  out = +""
  i = 0
  while i < s.size
    c = s[i]
    if c == "`"
      if (close = s.index("`", i + 1)) && close
        out << "<code>#{escape_html(s[(i + 1)...close])}</code>"
        i = close + 1
        next
      end
    elsif c == "*" && s[i + 1] == "*"
      if (close = s.index("**", i + 2)) && close
        out << "<strong>#{inline(s[(i + 2)...close])}</strong>"
        i = close + 2
        next
      end
    elsif c == "*"
      if (close = s.index("*", i + 1)) && close
        out << "<em>#{inline(s[(i + 1)...close])}</em>"
        i = close + 1
        next
      end
    elsif c == "["
      mid = s.index("](", i + 1)
      close = mid && s.index(")", mid + 2)
      if close
        out << "<a href=\"#{s[(mid + 2)...close]}\">#{inline(s[(i + 1)...mid])}</a>"
        i = close + 1
        next
      end
    end
    out << escape_html(c)
    i += 1
  end
  out
end

def parse_blocks(text)
  blocks = []
  current = nil
  fence = nil
  text.each_line(chomp: true) do |line|
    if fence
      if line.start_with?("```")
        fence = nil
        current = nil
      else
        fence.lines << line
      end
      next
    end
    content = line
    if line.start_with?("```")
      fence = Block.new(:code, [])
      blocks << fence
      current = nil
      next
    elsif line.strip.empty?
      current = nil
      next
    elsif (m = line.match(/\A(\#{1,6})\s+(.*)\z/)) && m
      blocks << Block.new(:heading, [m[2]], m[1].size)
      current = nil
      next
    elsif (m = line.match(/\A[-*]\s+(.*)\z/)) && m
      kind = :ul
      content = m[1]
    elsif (m = line.match(/\A\d+\.\s+(.*)\z/)) && m
      kind = :ol
      content = m[1]
    elsif (m = line.match(/\A>\s?(.*)\z/)) && m
      kind = :quote
      content = m[1]
    else
      kind = :para
    end
    if current&.kind == kind
      current.lines << content
    elsif current && current.kind != :para && kind == :para && line.start_with?("  ")
      current.lines[-1] += " " + content.strip
    else
      current = Block.new(kind, [content])
      blocks << current
    end
  end
  blocks
end

def render(blocks)
  blocks.map do |b|
    case b.kind
    when :heading then "<h#{b.level}>#{inline(b.lines[0])}</h#{b.level}>"
    when :para then "<p>#{inline(b.lines.join(" "))}</p>"
    when :quote then "<blockquote>#{inline(b.lines.join(" "))}</blockquote>"
    when :code then "<pre><code>#{escape_html(b.lines.join("\n"))}</code></pre>"
    when :ul, :ol
      items = b.lines.map { |l| "  <li>#{inline(l)}</li>" }
      "<#{b.kind}>\n#{items.join("\n")}\n</#{b.kind}>"
    end
  end.join("\n")
end

DOCUMENT = <<~MD
  # Sake *notes*

  Sake writes the type on **every operation**, e.g. `String.upcase(s)`.
  It keeps Ruby's syntax & semantics where it can.

  ## Checklist
  - parse **headings** and *lists*
  - inline `code <tags>` stays escaped
    and continuation lines join
  * links like [the spec](docs/spec.md)

  1. tokenize
  2. parse
  3. render

  > Quotes can span
  > two lines with a [link](http://example.com/?a=1&b=2).

  ```
  def f(x) = x * 2   # <not> **markup**
  ```

  Unclosed *emphasis and a lone ` backtick, plus 2 * 3 * 4 = 24.
  ###### Deep heading
MD

blocks = parse_blocks(DOCUMENT)
puts "#{blocks.size} blocks: #{blocks.map(&:kind).join(" ")}"
puts render(blocks)
