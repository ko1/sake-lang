gem "actionview", "8.1.3"
require "action_view"
require "bigdecimal"
require "active_support/core_ext/object/json"
view = ActionView::Base.empty


# content_tag
puts view.content_tag(:p, "Hello world!")
puts view.content_tag(:div, view.content_tag(:p, "Hello world!"), class: "strong")
puts view.content_tag(:div, "Hello world!", class: ["strong", "highlight"])
puts view.content_tag(:div, "Hello world!", class: ["strong", { highlight: true, muted: false }])
puts view.content_tag("select", "", multiple: true)
puts view.content_tag(:p, "<script>alert(1)</script>")
puts view.content_tag(:p, "<b>raw</b>", nil, false)
puts view.content_tag(:div, class: "box") { "inside <block>" }
puts view.content_tag(:textarea, "text")
puts view.content_tag(:div, "x", data: { controller: "hello", turbo_confirm: "Sure?", count: 3, list: [1, 2] })
puts view.content_tag(:div, "x", aria: { label: "Close", describedby: ["a", "b"], hidden: true })
puts view.content_tag(:a, "x", href: "/a?b=1&c=\"2\"", title: nil, disabled: false, checked: true)
# tag (legacy)
puts view.tag(:br)
puts view.tag(:br, nil, true)
puts view.tag(:input, { type: "text", disabled: true })
puts view.tag(:img, { src: "open & shut.png" })
puts view.tag(:img, { src: "open &amp; shut.png" }, false, false)
# tag builder
tb = view.tag
puts tb.div("Hello", class: "greeting")
puts tb.br
puts tb.input(type: "text", value: "<x>")
puts tb.p("Escaped <b>")
puts tb.p("Not escaped <b>", escape: false)
puts tb.span(id: "s") { "block" }
puts tb.circle(cx: 10)
puts tb.circle("c")
puts tb.animate_motion(dur: "10s")
puts tb.my_widget("custom", data: { x: 1 })
puts tb.attributes({ id: "a", class: ["b", "c"], required: true })
# token_list / class_names
puts view.token_list("foo", { bar: true, baz: false }, ["qux", nil], "foo")
puts view.class_names("btn", { "btn-primary": true })
puts view.cdata_section("<hello world>")
puts view.escape_once("1 < 2 &amp; 3")
begin
  view.content_tag("bad tag", "x")
rescue ArgumentError => e
  puts e.message
end
# capture, content_for, provide
c = view.capture { "<em>captured</em>" }
puts c, c.html_safe?
puts view.capture { "<em>safe</em>".html_safe }
view.content_for(:title, "Hello")
view.content_for(:title, " <World>")
puts view.content_for(:title)
p(view.content_for?(:title), view.content_for?(:nothing))
view.content_for(:title, "Replaced", flush: true)
puts view.content_for(:title)
view.content_for(:sidebar) { "side" }
puts view.content_for(:sidebar)
view.provide(:head, "provided")
puts view.content_for(:head)
# output safety
puts view.raw("<b>raw</b>")
puts view.safe_join(["<p>foo</p>", "<p>bar</p>".html_safe], "<br />".html_safe)
puts view.safe_join(["a", ["b", "c"]], " & ")
puts view.to_sentence(["one", "<two>", "<b>three</b>".html_safe])
puts view.to_sentence(["a", "b"])
puts view.to_sentence(["a", "b", "c"], last_word_connector: " or ")
