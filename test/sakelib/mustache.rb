require_relative "ref/mustache"

def show(label, s)
  puts("#{label}: #{s.inspect}")
end

def try(t, view = {})
  show(t.inspect, Mustache.render(t, view))
rescue Mustache::SyntaxError => e
  puts("MustacheSyntaxError: #{e.message}")
end

puts("== variables")
show("hello", Mustache.render("Hello {{planet}}!", {"planet" => "World"}))
show("symbol keys", Mustache.render("{{a}} and {{ b }}", {a: 1, b: 2.5}))
show("escape", Mustache.render("{{x}} {{{x}}} {{& x}}", {"x" => "<a href=\"q\">&'</a>"}))
show("missing", Mustache.render("[{{nope}}][{{{nope}}}]"))
show("nil false", Mustache.render("[{{n}}][{{f}}]", {"n" => nil, "f" => false}))
show("dotted", Mustache.render("{{person.name.first}} / {{person.age}} / {{person.none.x}}",
                               {"person" => {"name" => {"first" => "Ann"}, "age" => 30}}))
show("no view", Mustache.render("plain text"))
show("array value", Mustache.render("{{list}}", {"list" => [1, 2]}))

puts("== sections")
view = {
  "name" => "Chris", "value" => 10000, "in_ca" => true, "taxed" => 6000.0,
  "repo" => [{"name" => "resque"}, {"name" => "hub"}, {"name" => "rip"}],
  "empty" => [], "person?" => {"name" => "Jon"}, "nums" => [1, 2, 3],
}
tmpl = <<~T
  Hello {{name}}
  You have just won {{value}} dollars!
  {{#in_ca}}
  Well, {{taxed}} dollars, after taxes.
  {{/in_ca}}
  {{#repo}}
    <b>{{name}}</b>
  {{/repo}}
  {{^empty}}
  No repos :(
  {{/empty}}
  {{#person?}}Hi {{name}}!{{/person?}}
  {{#nums}}{{.}},{{/nums}}
  {{! a comment
      over lines }}
  done
T
print(Mustache.render(tmpl, view))
show("falsy section", Mustache.render("[{{#f}}x{{/f}}][{{#n}}x{{/n}}][{{#e}}x{{/e}}]", {"f" => false, "e" => []}))
show("truthy scalar", Mustache.render("{{#s}}<{{.}}>{{/s}}", {"s" => "str"}))
show("inverted", Mustache.render("{{^f}}no{{/f}}{{^t}}yes{{/t}}{{^missing}}!{{/missing}}", {"f" => false, "t" => true}))
show("outer scope", Mustache.render("{{#a}}{{b}}{{c}}{{/a}}", {"a" => {"b" => 1}, "c" => 2}))
show("nested", Mustache.render("{{#rows}}{{#cells}}{{.}}{{/cells}};{{/rows}}",
                               {"rows" => [{"cells" => [1, 2]}, {"cells" => [3]}]}))
show("dotted section", Mustache.render("{{#a.b}}{{c}}{{/a.b}}", {"a" => {"b" => {"c" => "deep"}}}))

puts("== standalone")
show("lines", Mustache.render("| a\n  {{#s}}\n  x\n  {{/s}}\n| b\n", {"s" => true}))
show("indented inline", Mustache.render(" {{#s}}x{{/s}}\n", {"s" => true}))
show("comment line", Mustache.render("a\n  {{! c }}  \nb"))
show("crlf", Mustache.render("a\r\n{{#s}}\r\nx\r\n{{/s}}\r\n", {"s" => true}))
show("at end", Mustache.render("a\n{{#s}}\n{{/s}}", {"s" => true}))

puts("== partials")
partials = {"user" => "<{{name}}>", "list" => "{{#items}}\n- {{> user}}\n{{/items}}", "rec" => "{{#kids}}({{n}}{{> rec}}){{/kids}}"}
show("partial", Mustache.render("Users: {{> user}}", {"name" => "ann"}, partials:))
show("in section", Mustache.render("{{> list}}", {"items" => [{"name" => "a"}, {"name" => "b"}]}, partials:))
show("indented", Mustache.render("x\n  {{> list}}\ny", {"items" => [{"name" => "a"}]}, partials:))
show("recursive", Mustache.render("{{> rec}}", {"kids" => [{"n" => 1, "kids" => [{"n" => 2, "kids" => false}]}, {"n" => 3, "kids" => false}]}, partials:))
show("missing partial", Mustache.render("[{{> nope}}]", {}, partials:))
show("symbol partials", Mustache.render("{{>p}}", {"v" => 1}, partials: {p: "v={{v}}"}))

puts("== errors")
try("{{#a}}x")
try("x{{/a}}")
try("{{#a}}{{/b}}")
try("{{#a}}{{#b}}{{/a}}{{/b}}")
try("{{name")
try("{{{name}}", {"name" => 1})
