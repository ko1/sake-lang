gem "actionview", "8.1.3"
require "action_view"

view = ActionView::Base.empty

# truncate
p view.truncate("Once upon a time in a world far far away")
p view.truncate("Once upon a time in a world far far away", length: 17)
p view.truncate("Once upon a time in a world far far away", length: 17, separator: " ")
p view.truncate("And they found that many people were sleeping better.", length: 25, omission: "... (continued)")
p view.truncate("<p>Once upon a time in a world far far away</p>")
p view.truncate("<p>Once upon a time in a world far far away</p>", escape: false)
p view.truncate("Once upon a time in a world far far away") { "!" }
p view.truncate(nil)
# highlight
p view.highlight("You searched for: rails", "rails")
p view.highlight("You searched for: rails", /for|rails/)
p view.highlight("You searched for: ruby, rails, dhh", "actionpack")
p view.highlight("You searched for: rails", ["for", "rails"], highlighter: '<em>\1</em>')
p view.highlight("You searched for: rails", "rails", highlighter: '<a href="search?q=\1">\1</a>')
p view.highlight("You searched for: rails", "rails") { |match| "<b>#{match}</b>" }
p view.highlight("<a href=\"javascript:alert('no!')\">ruby</a> on rails", "rails", sanitize: false)
p view.highlight("<p>rails <script>x</script></p>", "rails")
p view.highlight("", "rails")
# excerpt
p view.excerpt("This is an example", "an", radius: 5)
p view.excerpt("This is an example", "is", radius: 5)
p view.excerpt("This is an example", "is")
p view.excerpt("This next thing is an example", "ex", radius: 2)
p view.excerpt("This is also an example", "an", radius: 8, omission: "<chop> ")
p view.excerpt("This is a very beautiful morning", "very", separator: " ", radius: 1)
p view.excerpt("This is a very beautiful morning", "nothing")
# pluralize
p view.pluralize(1, "person")
p view.pluralize(2, "person")
p view.pluralize(3, "person", plural: "users")
p view.pluralize(0, "person")
p view.pluralize(1.0, "comment")
p view.pluralize("1", "comment")
p view.pluralize(2, "child", "kids")
p view.pluralize(nil, "post")
# word_wrap
p view.word_wrap("Once upon a time")
p view.word_wrap("Once upon a time", line_width: 8)
p view.word_wrap("Once upon a time", line_width: 1)
p view.word_wrap("Once upon a time", line_width: 1, break_sequence: "</br>")
p view.word_wrap("")
# simple_format
p view.simple_format("Here is some basic text...\n...with a line break.")
p view.simple_format("We want to put a paragraph...\n\n...right there.")
p view.simple_format("Look ma! A class!", { class: "description" })
p view.simple_format("<blink>Unblinkable.</blink>")
p view.simple_format("<blink>Blinkable!</blink> It's true.", {}, sanitize: false)
p view.simple_format("<a target=\"_blank\" href=\"http://example.com\">Continue</a>", {}, sanitize_options: { attributes: %w[target href] })
p view.simple_format("one\r\ntwo\r\n\r\nthree", {}, wrapper_tag: "div")
p view.simple_format(nil)
# cycle
r = []
4.times { r << view.cycle("odd", "even") }
p r
r = []
3.times { r << view.cycle(["a", "b", "c"], name: "letters") }
p r
p view.current_cycle("letters")
view.reset_cycle("letters")
p view.cycle(["a", "b", "c"], name: "letters")
p view.cycle(1, 2)
p view.current_cycle("nope")
# concat / safe_concat
view.output_buffer = ActionView::OutputBuffer.new
view.concat("<b>x</b>")
view.safe_concat("<i>y</i>")
p view.output_buffer.to_s
# javascript
p view.escape_javascript("</script>\n'quotes' \"double\" `tick` $x \\  ")
p view.j("ab")
p view.escape_javascript(nil)
p view.escape_javascript("<b>".html_safe).html_safe?
p view.javascript_tag("alert('All is good')")
p view.javascript_tag("alert(1)", type: "module")
p view.javascript_tag(nonce: false) { "x = 1" }
p view.javascript_cdata_section("y")
