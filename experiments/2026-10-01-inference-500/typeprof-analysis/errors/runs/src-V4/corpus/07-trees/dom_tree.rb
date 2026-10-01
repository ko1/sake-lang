class Element
  attr_reader :tag, :attrs, :children, :parent

  def initialize(tag, attrs, children, parent)
    @tag = tag
    @attrs = attrs
    @children = children
    @parent = parent
  end
end

class Text
  attr_reader :content

  def initialize(content)
    @content = content
  end
end

class MarkupError < StandardError
  attr_reader :offset

  def initialize(message, offset)
    super(message)
    @offset = offset
  end
end

VOID_TAGS = %w[br img hr input].freeze

def void_tag?(tag) = VOID_TAGS.include?(tag)

def parse_attrs(src)
  src.scan(/([a-z-]+)="([^"]*)"/).to_h
end

def parse(html)
  root = Element.new("#document", {}, [], nil)
  current = root
  pos = 0
  while pos < html.size
    m = %r{<(/?)([a-z0-9]+)([^>]*)>}.match(html[pos..])
    if !m    
      text = html[pos..].strip
      current.children << Text.new(text) unless text.empty?
      break
    end
    before = m.pre_match.strip
    current.children << Text.new(before) unless before.empty?
    tag = m[2]
    if m[1] == "/"
      if current.tag != tag
        raise MarkupError.new("</#{tag}> does not close <#{current.tag}>", pos + m.begin(0))
      end
      current = current.parent
    else
      el = Element.new(tag, parse_attrs(m[3]), [], current)
      current.children << el
      current = el unless void_tag?(tag) || m[3].end_with?("/")
    end
    pos += m.end(0)
  end
  raise MarkupError.new("unclosed <#{current.tag}>", html.size) if current != root
  root
end

def classes(el)
  c = el.attrs["class"]
  !c     ? [] : c.split(" ")
end

def matches?(el, simple)
  m = simple.match(/\A([a-z0-9]*)(?:\.([a-z-]+))?(?:#([a-z-]+))?\z/)
  raise ArgumentError, "bad selector #{simple}" if !m    
  tag, klass, id = m.captures
  return false if tag != "" && el.tag != tag
  return false if klass && !classes(el).include?(klass)
  return false if id && el.attrs["id"] != id
  true
end

def each_element(node, &block)
  node.children.each do |c|
    next unless c.is_a?(Element)
    yield c
    each_element(c, &block)
  end
end

def has_ancestor?(el, simple)
  p = el.parent
  while p
    return true if matches?(p, simple)
    p = p.parent
  end
  false
end

# descendant selectors only: "ul.menu li a"
def select(root, selector)
  *parts, last = selector.split(" ")
  found = []
  each_element(root) do |el|
    next unless matches?(el, last)
    anchor = el
    ok = parts.reverse.all? do |part|
      p = anchor.parent
      p = p.parent while p && !matches?(p, part)
      anchor = p
      !!p    
    end
    found << el if ok
  end
  found
end

def text_of(node)
  case node
  when Text then node.content
  when Element then node.children.map { |c| text_of(c) }.join(" ")
  end
end

def dump(node, depth)
  pad = "  " * depth
  case node
  when Text then puts "#{pad}\"#{node.content}\""
  when Element
    attrs = node.attrs.keys.sort.map { |k| " #{k}=#{node.attrs[k]}" }
    puts "#{pad}<#{node.tag}#{attrs.join}>"
    node.children.each { |c| dump(c, depth + 1) }
  end
end

page = <<~HTML
  <html><body>
    <div id="nav"><ul class="menu main">
      <li><a href="/">Home</a></li>
      <li class="active"><a href="/docs">Docs</a></li>
      <li><a href="/blog">Blog</a></li>
    </ul></div>
    <div class="content">
      <h1>Trees</h1>
      <p class="lead">A <b>tree</b> is a graph<br/>without cycles.</p>
      <p>See <a href="/docs/graphs">graphs</a> and <a href="https://example.org">more</a>.</p>
      <img src="tree.png" alt="tree">
    </div>
  </body></html>
HTML

doc = parse(page)
dump(doc.children.first, 0)
count = 0
depth_max = 0
each_element(doc) do |el|
  count += 1
  d = 0
  p = el.parent
  while p
    d += 1
    p = p.parent
  end
  depth_max = [depth_max, d].max
end
puts "elements: #{count}, max depth: #{depth_max}"
tags = Hash.new(0)
each_element(doc) { |el| tags[el.tag] += 1 }
puts "tags: #{tags.sort_by { |t, n| [-n, t] }.map { |t, n| "#{t}=#{n}" }.join(" ")}"

["a", "ul.menu li a", "div.content a", "li.active", "p.lead b", "#nav a", "div p", "span"].each do |sel|
  hits = select(doc, sel)
  desc = hits.map do |el|
    href = el.attrs["href"]
    href ? "#{text_of(el)}->#{href}" : text_of(el)
  end
  puts format("%-14s %d: %s", sel, hits.size, desc.join(" | "))
end
links = select(doc, "a")
external = links.count { |a| a.attrs["href"].start_with?("http") }
puts "links: #{links.size}, external: #{external}, inside nav: #{links.count { |a| has_ancestor?(a, "#nav") }}"

["<div><p>x</div>", "<ul><li>a</li>", "<p>ok</p>"].each do |bad|
  d = parse(bad)
  puts "#{bad} -> ok (#{text_of(d)})"
rescue MarkupError => e
  puts "#{bad} -> error at #{e.offset}: #{e.message}"
end
