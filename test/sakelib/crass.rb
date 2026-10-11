require "crass"

# one line per token: its type, the raw text, and the value when it has one
def show(tokens)
  tokens.each do |t|
    puts("#{t[:node]} #{t[:raw].inspect} #{t[:value].inspect}")
  end
end

# tokens: identifiers, hashes, strings, numbers, operators
show(Crass::Tokenizer.tokenize("#main .x-y > a:hover::before { content: 'hi\\26 there' }"))
show(Crass::Tokenizer.tokenize("12 +3.5 -.5e2 1e3 50% 2em -webkit-x --var"))
show(Crass::Tokenizer.tokenize("a ~= b |= c ^= d $= e *= f || g"))
show(Crass::Tokenizer.tokenize("<!-- @import url(foo.css) url( 'q.css' ) url(a b) -->"))
show(Crass::Tokenizer.tokenize("\"unterminated\nx #12 #-a \\41 B \\"))

# unicode ranges and number details
Crass::Tokenizer.tokenize("U+26 u+0-7F U+4?? 1.0 007 -0 1e400").each do |t|
  p([t[:node], t[:start], t[:end], t[:value], t[:type], t[:repr]])
end

# comments are dropped unless preserve_comments
show(Crass::Tokenizer.tokenize("a/* c1 */b /* open"))
show(Crass::Tokenizer.tokenize("a/* c1 */b", { preserve_comments: true }))

# a stylesheet: style rules, at-rules, !important
css = "a.b > c { color: red !important; margin: 1px 2.5em -3% }\n@media screen { p { x: y } }\n@charset \"utf-8\";"
tree = Crass.parse(css)
tree.each do |node|
  case node[:node]
  when :style_rule
    sel = node[:selector]

    puts("rule #{sel[:value].inspect}")
    children = node[:children]

    children.each do |prop|
      next unless prop[:node] == :property
      puts("  #{prop[:name]}: #{prop[:value].inspect} important=#{prop[:important]}")
    end
  when :at_rule
    puts("at #{node[:name]} prelude=#{Crass::Parser.stringify(node[:prelude])} block=#{node[:block] != nil}")
  else
    puts(node[:node])
  end
end
puts(Crass::Parser.stringify(tree))
p(Crass::Parser.stringify(tree) == css)

# the whole tree of a small rule, as Ruby prints it
p(Crass.parse("a{b:c}"))

# style attribute contents
props = Crass.parse_properties("color: blue; font: 12px/1.5 'A B', serif !IMPORTANT; ;bad; 3x: y")
props.each do |prop|
  if prop[:node] == :property
    puts("#{prop[:name]} = #{prop[:value].inspect} #{prop[:important]}")
  else
    puts("#{prop[:node]} #{prop[:value].inspect}")
  end
end

# comments in the tree, and stringify without them
with = Crass.parse("/* top */ a { b: c /* in */ }", { preserve_comments: true })
puts(Crass::Parser.stringify(with))
puts(Crass::Parser.stringify(with, { exclude_comments: true }))

# the IE * hack
show(Crass::Tokenizer.tokenize("*zoom: 1", { preserve_hacks: true }))
show(Crass::Tokenizer.tokenize("*zoom: 1"))

# functions and nested blocks; maximum_depth discards deeper nesting
rule = Crass.parse("a { width: calc(100% - (2 * var(--x))) }")
p(Crass::Parser.stringify(rule))
deep = Crass.parse_properties("x: f(g(h(1)))", { maximum_depth: 2 })
deep.each do |prop|
  p(prop[:value])
  kids = prop[:children]

  kids.each { |k| p([k[:node], k[:value]]) }
end

# Parser instance methods on a fresh parser
p(Crass::Parser.new("  @page :first { margin: 0 }  ").parse_rule[:node])
p(Crass::Parser.new("a {} b {}").parse_rule[:value])
p(Crass::Parser.new("   ").parse_rule[:value])
p(Crass::Parser.new(" color : red").parse_declaration[:name])
p(Crass::Parser.new("1px").parse_declaration[:value])
p(Crass::Parser.new(" (a) ").parse_component_value[:node])
p(Crass::Parser.new("a b").parse_component_value[:value])
p(Crass::Parser.new("a [b] c(d)").parse_component_values.size)
p(Crass::Parser.parse_rules("<!-- a{} -->").map { |r| r[:node] })
p(Crass::Parser.parse_stylesheet("<!-- a{} -->").map { |r| r[:node] })

# CRLF and form feeds become newlines; NUL becomes U+FFFD
show(Crass::Tokenizer.tokenize("a\r\nb\fc\u0000"))
