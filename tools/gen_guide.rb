# frozen_string_literal: true

# Builds docs/guide.html (the one-page guide published as an artifact) from docs/guide.src.html.
#   <!--@example NAME [FLAGS...]-->  highlighted source of docs/examples/NAME.sake, then its actual output
#   <!--@run NAME [FLAGS...]-->      only the output of `sake FLAGS NAME.sake`
# usage: ruby tools/gen_guide.rb [--check]   (--check: exit 1 if docs/guide.html is stale)
require "cgi/escape"
require "prism"
require_relative "gen_tutorial"

TOKEN_CLASS = {
  CONSTANT: "c", INTEGER: "n", FLOAT: "n", INSTANCE_VARIABLE: "e",
  STRING_BEGIN: "s", STRING_CONTENT: "s", STRING_END: "s", SYMBOL_BEGIN: "s",
  EMBEXPR_BEGIN: "s", EMBEXPR_END: "s"
}.freeze

def highlight(src)
  result = Prism.lex(src)
  spans = result.value.map { |tok, _| tok }.reject { _1.type == :EOF }.map do |tok|
    cls = tok.type.start_with?("KEYWORD_") ? "k" : TOKEN_CLASS[tok.type]
    [tok.location.start_offset, tok.location.end_offset, cls]
  end
  spans += result.comments.map { [_1.location.start_offset, _1.location.end_offset, "m"] }
  # A symbol is SYMBOL_BEGIN followed by its name.
  spans.sort_by!(&:first)
  spans.each_cons(2) { |a, b| b[2] = "s" if a[2] == "s" && src.byteslice(a[0], a[1] - a[0]) == ":" && b[0] == a[1] }
  html = +""
  pos = 0
  spans.each do |s, e, cls|
    next if s < pos
    html << CGI.escapeHTML(src.byteslice(pos, s - pos))
    text = CGI.escapeHTML(src.byteslice(s, e - s))
    html << (cls ? %(<span class="t#{cls}">#{text}</span>) : text)
    pos = e
  end
  html << CGI.escapeHTML(src.byteslice(pos, src.bytesize - pos))
  html.force_encoding("UTF-8")
end

def output_html(name, flags)
  lines = example_output(name, flags).lines.map do |line|
    text = CGI.escapeHTML(line.chomp)
    cls =
      case line
      when /\A\$ / then "prompt"
      when /: error: / then "err"
      when /\A\S+:\d+: in .*: \w+(::\w+)?: / then "err"
      when /\A  hint: / then "hint"
      when /\A  (from |\.\.\.)/, /\A\(exit status/ then "dim"
      end
    cls ? %(<span class="o#{cls}">#{text}</span>) : text
  end
  %(<pre class="out" aria-label="output">#{lines.join("\n")}</pre>)
end

def build_guide
  File.read(File.join(ROOT, "docs/guide.src.html")).gsub(/<!--@(example|run) (\S+)(.*?)-->/) do
    kind = $1
    name = $2
    flags = $3.split
    code = File.read(File.join(EXAMPLES, "#{name}.sake"))
    src = kind == "example" ? %(<pre class="src"><code>#{highlight(code)}</code></pre>) : ""
    %(<figure class="ex">#{src}#{output_html(name, flags)}</figure>)
  end
end

if __FILE__ == $0
  generated = build_guide
  path = File.join(ROOT, "docs/guide.html")
  exit(File.exist?(path) && File.read(path) == generated ? 0 : 1) if ARGV.include?("--check")
  File.write(path, generated)
end
