require "erubi"

# Ruby evals the source with the Hash's keys as local variables; Sake renders without eval
def render(engine, vars) = binding.tap { |b| vars.each { |k, v| b.local_variable_set(k, v) } }.eval(engine.src)

page = "<h1><%= title %></h1>\n<ul>\n<% items.each do |item| %>\n  <li><%== item[:name] %> <%= item[:price] %></li>\n<% end %>\n</ul>\n<%# a comment\nover two lines %>\n<% if items.empty? %>\nnone\n<% else %>\n<%= items.size %> items\n<% end %>\n"

# the generated Ruby source
engine = Erubi::Engine.new(page)
puts(engine.src)
p(engine.bufvar)
p(engine.filename)

# rendering: <%= is not escaped by default, <%== is
data = { title: "Fruits & Nuts", items: [{ name: "<apple>", price: 120 }, { name: "nut's", price: 30 }] }
print(render(engine, data))
print(render(engine, { title: "Empty", items: [] }))

# escape: true swaps the two
escaped = Erubi::Engine.new(page, { escape: true })
puts(escaped.src)
print(render(escaped, data))

# trimming: a tag alone on its line takes the line with it, unless trim is false
small = "a\n  <% if flag %>\n  b\n  <% end %>\nc <%= 1 -%>\nd <%- x = 1 -%>\n"
puts(Erubi::Engine.new(small).src)
puts(Erubi::Engine.new(small, { trim: false }).src)
print(render(Erubi::Engine.new("a\n  <% if flag %>\n  b\n  <% end %>\nc\n"), { flag: true }))
print(render(Erubi::Engine.new("a\n  <% if flag %>\n  b\n  <% end %>\nc\n", { trim: false }), { flag: false }))

# <%% is a literal <%, quotes and backslashes in text are kept
lit = "<%% x %> it's \\ <%%= y -%>\n"
puts(Erubi::Engine.new(lit).src)
print(render(Erubi::Engine.new(lit), {}))
puts(Erubi::Engine.new(lit, { literal_prefix: "{%", literal_postfix: "%}" }).src)

# options that change the source only
puts(Erubi::Engine.new("x<%= y %>z", { bufvar: "@out", freeze: true }).src)
puts(Erubi::Engine.new("x<%= y %>z", { outvar: "out", ensure: true }).src)
puts(Erubi::Engine.new("x<%= y %>z", { bufvar: "@b", ensure: true }).src)
puts(Erubi::Engine.new("x<%= y %><%= z %>w<% q %>", { chain_appends: true }).src)
puts(Erubi::Engine.new("x<%== y %>", { freeze_template_literals: false, escapefunc: "esc" }).src)
puts(Erubi::Engine.new("x", { preamble: "b = [];", postamble: "b.join\n", bufvar: "b", src: +"# hi\n" }).src)
p(Erubi::Engine.new("", { filename: "t.erb" }).filename)
p(Erubi::Engine.new("").src)

# Erubi.h escapes & < > " '
p(Erubi.h("<a href=\"x\">'&'</a>"))
p(Erubi.h(42))

# a regexp with an indicator the engine does not know
begin
  Erubi::Engine.new("<%@ x %>", { regexp: /<%(@)?(.*?)([-=])?%>([ \t]*\r?\n)?/m })
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
