def escape_html(s) = s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")

def inline(s)
  t = escape_html(s)
  t = t.gsub(/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
  t = t.gsub(/`([^`]+)`/, "<code>\\1</code>")
  t.gsub(/_(.+?)_/, "<em>\\1</em>")
end

class Renderer
  attr_reader :state, :out, :para, :counts

  def initialize
    @state = :normal
    @out = []
    @para = []
    @counts = Hash.new(0)
  end

  def emit(html, kind)
    @out << html
    @counts[kind] += 1
  end

  def close_block
    case @state
    in :paragraph
      emit("<p>#{@para.map { inline(it) }.join(" ")}</p>", :p)
      @para = []
    in :ulist then @out << "</ul>"
    in :olist then @out << "</ol>"
    in :quote
      emit("<blockquote>#{@para.map { inline(it) }.join(" ")}</blockquote>", :quote)
      @para = []
    in :normal | :code then nil
    end
    @state = :normal
  end

  def line(raw)
    if @state == :code
      if raw.start_with?("```")
        @out << "</code></pre>"
        @state = :normal
      else
        @out << escape_html(raw)
      end
      return
    end
    text = raw.rstrip
    heading = text.match(/\A(\#{1,6}) +(.*)\z/)
    bullet = text.match(/\A[-*] +(.*)\z/)
    numbered = text.match(/\A\d+\. +(.*)\z/)
    if text.empty?
      close_block
    elsif text.start_with?("```")
      close_block
      lang = text[3..].strip
      @out << (lang.empty? ? "<pre><code>" : "<pre><code class=\"#{lang}\">")
      @counts[:code] += 1
      @state = :code
    elsif heading
      close_block
      level = heading[1].size
      emit("<h#{level}>#{inline(heading[2])}</h#{level}>", :heading)
    elsif bullet
      if @state != :ulist
        close_block
        @out << "<ul>"
        @state = :ulist
      end
      emit("  <li>#{inline(bullet[1])}</li>", :item)
    elsif numbered
      if @state != :olist
        close_block
        @out << "<ol>"
        @state = :olist
      end
      emit("  <li>#{inline(numbered[1])}</li>", :item)
    elsif text.start_with?(">")
      close_block if @state != :quote
      @state = :quote
      @para << text[1..].strip
    else
      close_block if @state != :paragraph
      @state = :paragraph
      @para << text.strip
    end
  end

  def finish
    if @state == :code
      @out << "</code></pre>"
      @state = :normal
    end
    close_block
    @out
  end
end

doc = "# Release notes\n\nThis release adds **state machines** and\nfixes _many_ bugs.\n\n## Changes\n- faster `lexer`\n- new <parser> API\n* fewer allocations\n1. read the docs\n2. upgrade\n\n> Simple things should be simple,\n> complex things possible.\n\n```ruby\nif a < b && c\n  puts \"x\"\n```\nTrailing paragraph with a_b and 3 * 4.\n```\nunterminated block\n"

r = Renderer.new
doc.each_line { |l| r.line(l.chomp) }
html = r.finish
html.each { puts it }
puts "--"
counts = r.counts
puts counts.keys.sort_by(&:to_s).map { |k| "#{k}=#{counts[k]}" }.join(" ")
