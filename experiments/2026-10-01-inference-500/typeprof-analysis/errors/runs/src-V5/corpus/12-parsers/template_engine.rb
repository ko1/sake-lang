class Tag
  attr_reader :kind, :name, :children

  def initialize(kind, name)
    @kind = kind
    @name = name
    @children = []
  end
end

class TemplateError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

def parse_template(src)
  root = Tag.new(:root, "")
  stack = [root]
  pos = 0
  loop do
    open = src.index("{{", pos)
    if !open    
      stack.last.children << Tag.new(:text, src[pos..]) if pos < src.size
      break
    end
    stack.last.children << Tag.new(:text, src[pos...open]) if open > pos
    raw = src[open + 2] == "{"
    closer = raw ? "}}}" : "}}"
    body_start = open + (raw ? 3 : 2)
    close = src.index(closer, body_start)
    raise TemplateError.new("unclosed tag", open) if !close    
    inner = src[body_start...close].strip
    pos = close + closer.size
    sigil = inner[0]
    name = (inner[1..] || "").strip
    current = stack.last.children
    if raw
      current << Tag.new(:raw, inner)
    elsif sigil == "#" || sigil == "^"
      tag = Tag.new(sigil == "#" ? :section : :inverted, name)
      current << tag
      stack << tag
    elsif sigil == "/"
      top = stack.pop
      raise TemplateError.new("unexpected {{/#{name}}}", open) if stack.empty? || top.name != name
    elsif sigil == "!"
      nil
    else
      raise TemplateError.new("empty tag", open) if inner.empty?
      current << Tag.new(:var, inner)
    end
  end
  raise TemplateError.new("unclosed section '#{stack.last.name}'", src.size) if stack.size > 1
  root
end

def lookup(contexts, name)
  return contexts.last if name == "."
  first, *rest = name.split(".")
  contexts.reverse_each do |ctx|
    next unless ctx.is_a?(Hash) && ctx.key?(first)
    return rest.reduce(ctx[first]) { |v, part| v.is_a?(Hash) ? v[part] : nil }
  end
  nil
end

def escape(s) = s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;")

def blank?(v) = !v     || v == false || (v.is_a?(Array) && v.empty?)

def render(tag, contexts, out)
  tag.children.each do |t|
    case t.kind
    when :text then out << t.name
    when :var then out << escape(lookup(contexts, t.name).to_s)
    when :raw then out << lookup(contexts, t.name).to_s
    when :inverted then render(t, contexts, out) if blank?(lookup(contexts, t.name))
    when :section
      v = lookup(contexts, t.name)
      if v.is_a?(Array)
        v.each do |item|
          contexts.push(item)
          render(t, contexts, out)
          contexts.pop
        end
      elsif !blank?(v)
        contexts.push(v)
        render(t, contexts, out)
        contexts.pop
      end
    end
  end
  out
end

def fill(template, data) = render(parse_template(template), [data], []).join

DATA_ = {
  "shop" => "Tea & Co",
  "user" => { "name" => "Ada <admin>", "vip" => true, "address" => { "city" => "Kyoto" } },
  "items" => [
    { "name" => "sencha", "qty" => 2, "price" => 3.5 },
    { "name" => "matcha", "qty" => 1, "price" => 12.0, "note" => "ceremonial" },
    { "name" => "hojicha", "qty" => 3, "price" => 2.25 }
  ],
  "tags" => ["green", "loose", "organic"],
  "coupons" => [],
  "footer" => "<em>thanks</em>"
}.freeze

TEMPLATES = [
  "Hello {{user.name}} from {{user.address.city}}!{{#user.vip}} (VIP){{/user.vip}}",
  "{{! receipt }}{{shop}} receipt:\n{{#items}}- {{qty}} x {{name}} @ {{price}}{{#note}} [{{note}}]{{/note}}\n{{/items}}",
  "Tags: {{#tags}}<{{.}}> {{/tags}}| coupons: {{#coupons}}{{code}}{{/coupons}}{{^coupons}}none{{/coupons}}",
  "{{footer}} vs {{{footer}}}; missing=[{{nothing}}] [{{user.zip.code}}]",
  "{{#items}}{{name}} for {{user.name}}; {{/items}}",
  "{{#items}}oops",
  "{{name}} {{/items}}",
  "Hi {{user.name",
  "{{ }}"
]

TEMPLATES.each_with_index do |t, i|
  puts "--- template #{i + 1}"
  begin
    puts fill(t, DATA_)
  rescue TemplateError => e
    puts "error at #{e.pos}: #{e.message}"
  end
end
