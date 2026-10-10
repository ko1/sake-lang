# Reference implementation for sakelib/mustache.sake: Mustache.render(template, view, partials:) after
# the mustache gem, with the spec's standalone lines and partial indentation.
module Mustache
  Node = Struct.new(:kind, :name, :text, :indent, :children) do
    def initialize(kind, name, text = "", indent = "") = super(kind, name, text, indent, [])
  end

  SIGILS = { "&" => :raw, "#" => :section, "^" => :inverted, "/" => :close, "!" => :comment, ">" => :partial }.freeze
  STANDALONE = %i[section inverted close comment partial].freeze
  ESCAPES = { "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;", "'" => "&#39;" }.freeze

  class Parser
    class SyntaxError < StandardError; end

    def initialize(tmpl)
      @tmpl = tmpl
      @pos = 0
    end

    def parse
      root = Node.new(:root, "")
      stack = [root]
      len = @tmpl.size
      while @pos < len
        start = @tmpl.index("{{", @pos)
        unless start
          add_text(stack, @tmpl[@pos..])
          break
        end
        triple = @tmpl[start, 3] == "{{{"
        close = @tmpl.index(triple ? "}}}" : "}}", start + 2) or raise SyntaxError, "Unclosed tag at #{start}"
        finish = close + (triple ? 3 : 2)
        inner = @tmpl[(start + 2)...close].strip
        kind = :var
        name = inner
        if triple
          kind = :raw
          name = inner.delete_prefix("{").strip
        elsif (k = SIGILS[inner[0]])
          kind = k
          name = inner[1..].strip
        end
        text = @tmpl[@pos...start]
        indent = ""
        @pos = finish
        if STANDALONE.include?(kind)
          before = text.match(/(?:\A|\n)([ \t]*)\z/)
          line_start = text.include?("\n") || start - text.size == 0 || @tmpl[start - text.size - 1] == "\n"
          after = @tmpl.match(/\G[ \t]*(?:\r?\n|\z)/, finish)
          if before && line_start && after
            indent = before[1]
            text = text[0, text.size - indent.size]
            @pos = finish + after[0].size
          end
        end
        add_text(stack, text)
        top = stack.last
        case kind
        when :comment then nil
        when :section, :inverted
          node = Node.new(kind, name)
          top.children << node
          stack << node
        when :close
          raise SyntaxError, "Unopened section '#{name}'" if top.equal?(root)
          raise SyntaxError, "Unclosed section '#{top.name}'" unless top.name == name
          stack.pop
        else
          top.children << Node.new(kind, name, "", indent)
        end
      end
      raise SyntaxError, "Unclosed section '#{stack.last.name}'" unless stack.last.equal?(root)
      root.children
    end

    private

    def add_text(stack, s)
      stack.last.children << Node.new(:text, "", s) unless s.empty?
    end
  end

  module_function

  def render(template, view = {}, partials: {})
    out = []
    render_nodes(out, Parser.new(template).parse, [view], partials)
    out.join
  end

  def escape(s) = s.gsub(/[&<>"']/, ESCAPES)

  def fetch(ctx, key)
    return nil unless ctx.is_a?(Hash)
    return ctx[key] if ctx.key?(key)
    ctx.key?(key.to_sym) ? ctx[key.to_sym] : nil
  end

  def lookup(stack, name)
    return stack.last if name == "."
    first, *rest = name.split(".")
    ctx = stack.reverse_each.find { |c| c.is_a?(Hash) && (c.key?(first) || c.key?(first.to_sym)) }
    rest.reduce(fetch(ctx, first)) { |v, k| fetch(v, k) }
  end

  def falsy?(v) = v.nil? || v == false || (v.is_a?(Array) && v.empty?)

  def render_nodes(out, nodes, stack, partials)
    nodes.each do |node|
      case node.kind
      when :text then out << node.text
      when :var
        v = lookup(stack, node.name)
        out << escape(v.to_s) unless v.nil?
      when :raw
        v = lookup(stack, node.name)
        out << v.to_s unless v.nil?
      when :section
        v = lookup(stack, node.name)
        next if falsy?(v)
        (v.is_a?(Array) ? v : [v]).each do |item|
          stack.push(item)
          render_nodes(out, node.children, stack, partials)
          stack.pop
        end
      when :inverted
        render_nodes(out, node.children, stack, partials) if falsy?(lookup(stack, node.name))
      when :partial
        t = partials[node.name] || partials[node.name.to_sym] or next
        t = t.gsub(/^(?=.)/, node.indent) unless node.indent.empty?
        render_nodes(out, Parser.new(t).parse, stack, partials)
      end
    end
    out
  end
end
