require "rexml/document"

src = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <!-- top comment -->
  <library name="City" open='yes'>
    <book id="b1" lang="en">
      <title>Ruby &amp; Sake</title>
      <author>Matz</author>
      <year>1995</year>
    </book>
    <book id="b2">
      <title><![CDATA[<Types> & Operations]]></title>
      <author>Ko1</author>
      <tags><tag>lang</tag><tag>types</tag></tags>
    </book>
    <!-- a note -->
    <magazine id="m1"><title>Weekly &#65;&#x42;</title></magazine>
    <empty/>
  </library>
XML

doc = REXML::Document.new(src)
p(doc.version)
p(doc.encoding)
root = doc.root
p(root.name)
p(root["name"])
p(root.attributes["open"])
root.attributes.each { |k, v| puts("#{k}=#{v}") }
p(root.has_attributes?)
p(root.has_elements?)

puts("== elements")
es = root.elements
p(es.size)
p(es.to_a.map(&:name))
first = es[1]
p(first["id"])
p(first.text("title"))
p(first.text)
b2 = es["book[@id='b2']"]
p(b2.text("title"))
p(b2.elements["title"].cdatas.map(&:value))
mt = es["magazine/title"]
p(mt ? mt.text : nil)
p(es[9])
p(es["nothing"])
es.each("book") { |b| puts("book #{b["id"]}: #{b.text("author")}") }
root.each_element { |e| print(e.name, " ") }
puts
p(root.comments.map(&:string))
p(root.texts.size)
p(REXML::Element.new("x").has_text?)
p(es["empty"].text)

puts("== xpath")
def names(es) = es.map { |e| "#{e.name}#{e["id"] ? "#" + e["id"] : ""}" }
p(names(REXML::XPath.match(doc, "/library/book")))
p(names(REXML::XPath.match(doc, "//title")))
p(names(REXML::XPath.match(doc, "//tag")))
p(names(REXML::XPath.match(doc, "/library/*")))
p(names(REXML::XPath.match(doc, "//book[2]/author")))
p(names(REXML::XPath.match(doc, "//book[last()]")))
p(names(REXML::XPath.match(doc, "//*[@id]")))
p(names(REXML::XPath.match(doc, "//book[@lang='en']")))
p(names(REXML::XPath.match(doc, "//book[tags]")))
p(names(REXML::XPath.match(doc, "//tags/tag[1]")))
p(names(REXML::XPath.match(root, "book/title")))
p(names(REXML::XPath.match(root, "/library/magazine")))
p(names(REXML::XPath.match(root, ".")))
p(names(REXML::XPath.match(first, "..")))
p(names(REXML::XPath.match(doc, "/nothing")))
t = REXML::XPath.first(doc, "//tag[2]")
p(t ? t.text : nil)
REXML::XPath.each(doc, "//author") { |a| p(a.text) }
p(names(root.get_elements("book")))

puts("== children")
p(root.children.size)
p(doc.children.map(&:to_s))

puts("== to_s")
puts(first.to_s)
puts(REXML::Document.new("<a x=\"1\"><b>t &lt; u</b><c/><!--c--><![CDATA[d]]></a>").to_s)
p(REXML::Document.new("<a><b/></a>").to_s)
p(REXML::Document.new("<a>\n<b>x</b>\n</a>").root.text)
p(REXML::Document.new("").root)
p(REXML::Document.new("<a>&foo; &lt;</a>").root.text)

puts("== building")
e = REXML::Element.new("new")
e.add_attribute("k", "a&b<c\"d'e")
e.add_text("x < y > z & w")
c = e.add_element("child", { "a" => "1" })
c.add_attribute("b", "2")
puts(e.to_s)
p(e.text)
p(e.attributes["k"])
p(c.parent.name)
p(c.root.name)
p((REXML::XPath.first(doc, "//tag") || e).root.name)

puts("== errors")
["<a><b></a>", "<a>", "<a/><b/>", "<a x=1/>", "<a x=\"1\" x=\"2\"/>", "text", "<a></b>", "<a><!-- x</a>", "</a>"].each do |s|
  begin
    REXML::Document.new(s)
    puts("ok: #{s}")
  rescue REXML::ParseException
    puts("ParseException: #{s}")
  end
end
