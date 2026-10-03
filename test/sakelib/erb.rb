require "erb"
include ERB::Util

page = <<~T
  <h1><%= h(title) %></h1>
  <%# a comment %>
  <p>Hello, <%= h(user[:name]) %>!<% if user[:admin] %> (admin)<% end %></p>
  <% unless items.empty? %>
  <ul>
  <% items.each do |item| %>
    <li><%= h(item[:name]) %>: <%= item[:price] %> yen<% if item[:tags].any? %> [<%= item[:tags].join(", ") %>]<% end %></li>
  <% end %>
  </ul>
  <% else %>
  <p>no items</p>
  <% end %>
  <p><%= items.size %> items<% if items.any? %>, first: <%= items.first[:name] %><% end %></p>
  <%% literal %> and <%= "str" %> <%= 'single' %> <%= 42 %> <%= nil %>|<%= ratio %> <%= list %>
  <a href="/search?q=<%= u(query) %>">search</a>
T

data = {
  title: "Tom & Jerry's <Shop>",
  user: {name: "<script>alert(1)</script>", admin: true},
  items: [
    {name: "Apple", price: 120, tags: ["fruit", "red"]},
    {name: "Bread \"fresh\"", price: 250, tags: []},
    {name: "日本酒", price: 1800, tags: ["drink"]}
  ],
  query: "sake & rice/日本",
  ratio: 0.5,
  list: [1, "two", :three, nil]
}
puts(ERB.new(page).result_with_hash(data))

puts("-- empty list")
puts(ERB.new(page).result_with_hash({title: "", user: {name: "x", admin: false},
  items: [], query: "", ratio: 1, list: []}))

puts("-- each_with_index, Hash each, elsif, nesting, operators")
t = <<~T
  <% rows.each_with_index do |row, i| %><%= i %>:<% row.each do |cell| %> <%= cell %><% end %>
  <% end %><% scores.each do |name, score| %><%= name %>=<% if score >= 90 %>A<% elsif score >= 70 %>B<% elsif score >= 50 %>C<% else %>F<% end %> <% end %>
  <% if !hidden && word != "" %>shown<% end %> <% pairs.each do |a, b| %>(<%= a %>,<%= b %>)<% end %> <%= nested[:a]["b"][-1] %>
  <%= word.upcase %> <%= word.size %> <%= word[0] %> <%= hidden || "fallback" %> <%= word == "sake" %> <%= 1 < 2 %>
T
puts(ERB.new(t).result_with_hash({
  rows: [[1, 2], ["a"], []],
  scores: {"ann" => 95, "bob" => 70, "cy" => 55, "dee" => 10},
  hidden: false, word: "sake",
  pairs: [[1, "one"], [2, "two"]],
  nested: {a: {"b" => [10, 20, 30]}}
}))

puts("-- trim_mode -")
t = <<~T
  <ul>
    <%- items.each do |x| -%>
    <li><%= x %></li>
    <%- end -%>
  </ul>
  a <%- if true -%> b <%- end -%>
  <%# comment -%>
  end
T
p(ERB.new(t, trim_mode: "-").result_with_hash({items: ["a", "b"]}))

puts("-- trim_mode >")
t = <<~T
  <% items.each do |x| %>
  <%= x %>
  <% end %>
  tail
T
p(ERB.new(t, trim_mode: ">").result_with_hash({items: ["a", "b"]}))

puts("-- trim_mode <>")
p(ERB.new(t, trim_mode: "<>").result_with_hash({items: ["a", "b"]}))
p(ERB.new("x <%= 1 %>\n<%= 2 %>\ny\n", trim_mode: "<>").result_with_hash({}))

puts("-- no trim_mode")
p(ERB.new(t).result_with_hash({items: ["a", "b"]}))
p(ERB.new("").result_with_hash({}))
p(ERB.new("no tags, %> and %%> stay").result_with_hash({}))
p(ERB.new("<%= '%%>' %>").result_with_hash({}))

puts("-- ERB::Util")
p(ERB::Util.h("<a href='x'>&\"</a>"))
p(ERB::Util.html_escape(1))
p(ERB::Util.url_encode("a b&c/~é"))
p(ERB::Util.u(""))

puts("-- errors")
begin
  ERB.new("<%= missing %>").result_with_hash({})
rescue NameError
  puts("error: undefined name")
end
begin
  ERB.new("<% if x %>open").result_with_hash({x: true})
rescue SyntaxError
  puts("error: missing end")
end
