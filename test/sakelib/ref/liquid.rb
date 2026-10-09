# Reference for sakelib/liquid.sake: the Liquid template language (Shopify's liquid gem, lax mode)
# for the subset the port covers, with the gem's API: Liquid::Template.parse(src).render(assigns),
# Liquid::SyntaxError. Where the gem's behavior is reproduced: and/or chained from the right, every
# matching `when` renders, assign writes the outermost scope, unknown filters are skipped, Integer#size
# for `size` of a number. Where it is not: numbers are Float, not BigDecimal; errors raise instead of
# rendering "Liquid error: ..."; comparing nil with a number is false.
require "time"

module Liquid
  class SyntaxError < StandardError; end

  Expr = Struct.new(:kind, :value, :name, :path, :from, :to)
  Filter = Struct.new(:name, :args)
  Cond = Struct.new(:left, :op, :right, :rel, :rest)
  Node = Struct.new(:kind, :text, :expr, :filters, :conds, :bodies, :else_body, :limit, :offset, :reversed) do
    def initialize(kind, **kw) = super(kind, "", nil, [], [], [], nil, nil, nil, false).tap { kw.each { |k, v| self[k] = v } }
  end
  Tok = Struct.new(:kind, :text, :src, :trim_left, :trim_right)

  class Template
    attr_reader :nodes

    def self.parse(src) = new(Parser.new(Parser.tokenize(src)).parse)
    def initialize(nodes) = @nodes = nodes

    def render(assigns = {})
      out = []
      Renderer.new([assigns.dup]).render_nodes(@nodes, out)
      out.join
    end
  end

  class Parser
    def self.tokenize(src)
      toks = []
      pos = 0
      while pos < src.size
        start = src.index(/\{[{%]/, pos)
        unless start
          toks << Tok.new(:text, src[pos..], src[pos..], false, false)
          break
        end
        toks << Tok.new(:text, src[pos...start], src[pos...start], false, false) if start > pos
        var = src[start, 2] == "{{"
        close = src.index(var ? "}}" : "%}", start + 2) or
          raise SyntaxError, "#{var ? "Variable" : "Tag"} '#{src[start, 2]}' was not properly terminated"
        whole = src[start..close + 1]
        inner = whole[2...-2]
        tl = inner.start_with?("-")
        tr = inner.end_with?("-")
        inner = inner[1..] if tl
        inner = inner[0...-1] if tr
        toks << Tok.new(var ? :var : :tag, inner.strip, whole, tl, tr)
        pos = close + 2
      end
      toks
    end

    def initialize(toks)
      @toks = toks
      @pos = 0
      @trim = false
      @tag = @markup = ""
    end

    def parse = parse_block("", [])

    def trim_before(nodes, t)
      last = nodes.last
      last.text = last.text.rstrip if t.trim_left && last && last.kind == :text
      @trim = t.trim_right
    end

    def split_tag(s)
      m = s.match(/\A(\w+)\s*(.*)\z/m) or raise SyntaxError, "Unknown tag '#{s}'"
      [m[1], m[2]]
    end

    def parse_block(opener, closers)
      nodes = []
      while @pos < @toks.size
        t = @toks[@pos]
        @pos += 1
        case t.kind
        when :text
          s = @trim ? t.text.lstrip : t.text
          @trim = false
          nodes << Node.new(:text, text: s) unless s.empty?
        when :var
          trim_before(nodes, t)
          nodes << parse_output(:output, t.text)
        when :tag
          trim_before(nodes, t)
          name, markup = split_tag(t.text)
          if closers.include?(name)
            @tag, @markup = name, markup
            return nodes
          end
          raise SyntaxError, "Unexpected outer '#{name}' tag" if name.start_with?("end") || %w[else elsif when].include?(name)
          nodes << parse_tag(name, markup)
        end
      end
      raise SyntaxError, "'#{opener}' tag was never closed" unless opener.empty?
      nodes
    end

    def parse_tag(name, markup)
      case name
      when "if", "unless"
        node = Node.new(name.to_sym)
        node.conds << parse_cond(markup)
        node.bodies << parse_block(name, ["elsif", "else", "end#{name}"])
        while @tag == "elsif"
          node.conds << parse_cond(@markup)
          node.bodies << parse_block(name, ["elsif", "else", "end#{name}"])
        end
        node.else_body = parse_block(name, ["end#{name}"]) if @tag == "else"
        node
      when "case"
        node = Node.new(:case, expr: parse_expr(markup))
        parse_block("case", %w[when else endcase])
        while @tag == "when"
          node.conds << when_cond(node.expr, @markup)
          node.bodies << parse_block("case", %w[when else endcase])
        end
        node.else_body = parse_block("case", %w[endcase]) if @tag == "else"
        node
      when "for"
        m = markup.match(/\A([\w\-]+)\s+in\s+(\S+)(.*)\z/m) or
          raise SyntaxError, "Syntax Error in 'for loop' - Valid syntax: for [item] in [collection]"
        node = Node.new(:for, text: m[1], expr: parse_expr(m[2]), reversed: m[3].match?(/\breversed\b/))
        m[3].scan(/(\w+)\s*:\s*("[^"]*"|'[^']*'|[^\s,]+)/) do |key, val|
          node.limit = parse_expr(val) if key == "limit"
          node.offset = parse_expr(val) if key == "offset"
        end
        node.bodies << parse_block("for", %w[else endfor])
        node.else_body = parse_block("for", %w[endfor]) if @tag == "else"
        node
      when "assign"
        m = markup.match(/\A([\w\-]+)\s*=\s*(.*)\z/m) or
          raise SyntaxError, "Syntax Error in 'assign' - Valid syntax: assign [var] = [source]"
        node = parse_output(:assign, m[2])
        node.text = m[1]
        node
      when "capture"
        node = Node.new(:capture, text: markup.strip)
        node.bodies << parse_block("capture", %w[endcapture])
        node
      when "echo" then parse_output(:output, markup)
      when "break" then Node.new(:break)
      when "continue" then Node.new(:continue)
      when "comment"
        depth = 1
        while depth > 0
          raise SyntaxError, "'comment' tag was never closed" if @pos >= @toks.size
          t = @toks[@pos]
          @pos += 1
          next unless t.kind == :tag
          tname = t.text.sub(/\s.*\z/m, "")
          depth += 1 if tname == "comment"
          depth -= 1 if tname == "endcomment"
          trim_before([], t) if depth == 0
        end
        Node.new(:comment)
      when "raw"
        buf = []
        loop do
          raise SyntaxError, "'raw' tag was never closed" if @pos >= @toks.size
          t = @toks[@pos]
          @pos += 1
          if t.kind == :tag && t.text == "endraw"
            s = buf.join
            s = s.lstrip if @trim
            s = s.rstrip if t.trim_left
            @trim = t.trim_right
            return Node.new(:text, text: s)
          end
          buf << t.src
        end
      else
        raise SyntaxError, "Unknown tag '#{name}'"
      end
    end

    def parse_output(kind, markup)
      parts = split_outside_quotes(markup, "|")
      node = Node.new(kind, expr: parse_expr(parts[0]))
      parts.drop(1).each do |f|
        m = f.strip.match(/\A(\w+)\s*(?::\s*(.*))?\z/m) or next
        args = m[2].nil? ? [] : split_outside_quotes(m[2], ",")
        node.filters << Filter.new(m[1], args.map { |a| parse_expr(a) })
      end
      node
    end

    def split_outside_quotes(s, sep)
      out = []
      cur = +""
      q = nil
      s.each_char do |c|
        if q
          q = nil if c == q
          cur << c
        elsif c == '"' || c == "'"
          q = c
          cur << c
        elsif c == sep
          out << cur
          cur = +""
        else
          cur << c
        end
      end
      out << cur
    end

    def parse_expr(s)
      s = s.strip
      if (m = s.match(/\A"(.*)"\z/m) || s.match(/\A'(.*)'\z/m))
        Expr.new(:lit, m[1])
      elsif %w[nil null].include?(s) || s.empty? then Expr.new(:lit, nil)
      elsif s == "true" then Expr.new(:lit, true)
      elsif s == "false" then Expr.new(:lit, false)
      elsif s == "empty" then Expr.new(:lit, :empty)
      elsif s == "blank" then Expr.new(:lit, :blank)
      elsif s.match?(/\A-?\d+\z/) then Expr.new(:lit, s.to_i)
      elsif s.match?(/\A-?\d+\.\d+\z/) then Expr.new(:lit, s.to_f)
      elsif (m = s.match(/\A\((\S+)\.\.(\S+)\)\z/))
        Expr.new(:range, nil, nil, nil, parse_expr(m[1]), parse_expr(m[2]))
      else
        segs = s.scan(/\[[^\]]+\]|[\w\-]+\??/)
        path = segs.drop(1).map { |seg| seg.start_with?("[") ? parse_expr(seg[1...-1]) : Expr.new(:lit, seg) }
        Expr.new(:var, nil, segs.first || s, path)
      end
    end

    OPS = %w[== != <> <= >= < > contains].freeze

    def parse_cond(markup)
      toks = markup.scan(/"[^"]*"|'[^']*'|\S+/)
      first = cur = nil
      i = 0
      while i < toks.size
        left = parse_expr(toks[i])
        i += 1
        op = ""
        right = nil
        if toks[i] && OPS.include?(toks[i])
          op = toks[i]
          right = parse_expr(toks[i + 1] || "")
          i += 2
        end
        c = Cond.new(left, op, right, :none, nil)
        cur ? cur.rest = c : first = c
        cur = c
        if %w[and or].include?(toks[i])
          c.rel = toks[i].to_sym
          i += 1
        else
          break
        end
      end
      first or raise SyntaxError, "Syntax Error in tag 'if' - Valid syntax: if [expression]"
    end

    def when_cond(subject, markup)
      vals = split_outside_quotes(markup, ",").flat_map { |part| part.split(/\s+or\s+/) }.map(&:strip).reject(&:empty?)
      first = cur = nil
      vals.each do |v|
        c = Cond.new(subject, "==", parse_expr(v), :none, nil)
        if cur
          cur.rel = :or
          cur.rest = c
        end
        first ||= c
        cur = c
      end
      first || Cond.new(subject, "==", Expr.new(:lit, nil), :none, nil)
    end
  end

  class Renderer
    def initialize(scopes)
      @scopes = scopes
      @interrupt = :none
    end

    def lookup(name)
      sc = @scopes.reverse_each.find { |s| s.key?(name) }
      sc && sc[name]
    end

    def assign(name, v) = @scopes[0][name] = v

    def truthy?(v) = !(v.nil? || v == false)
    def empty?(v) = (v.is_a?(String) || v.is_a?(Array) || v.is_a?(Hash)) && v.empty?

    def blank?(v)
      case v
      when nil, false then true
      when String then v.strip.empty?
      when Array, Hash then v.empty?
      else false
      end
    end

    def out_s(v)
      case v
      when nil, Symbol then ""
      when Array then v.map { |x| out_s(x) }.join
      else v.to_s
      end
    end

    def eval_expr(e)
      case e.kind
      when :lit then e.value
      when :range then (to_i(eval_expr(e.from))..to_i(eval_expr(e.to))).to_a
      when :var then e.path.reduce(lookup(e.name)) { |v, seg| index(v, eval_expr(seg)) }
      end
    end

    def index(v, key)
      case v
      when Hash then v.key?(key) ? v[key] : command(v, key)
      when Array then key.is_a?(Integer) ? v[key] : command(v, key)
      when String then key == "size" ? v.size : nil
      end
    end

    def command(v, key)
      case key
      when "size" then v.size
      when "first" then v.is_a?(Array) ? v.first : nil
      when "last" then v.is_a?(Array) ? v.last : nil
      end
    end

    def eval_cond(c)
      l = eval_expr(c.left)
      v = c.op.empty? ? truthy?(l) : compare(l, c.op, c.right && eval_expr(c.right))
      case c.rel
      when :none then v
      when :and then v && (c.rest ? eval_cond(c.rest) : false)
      when :or then v || (c.rest ? eval_cond(c.rest) : false)
      end
    end

    def eq?(l, r)
      return empty?(l) if r == :empty
      return blank?(l) if r == :blank
      return empty?(r) if l == :empty
      return blank?(r) if l == :blank
      l == r
    end

    def compare(l, op, r)
      case op
      when "==" then eq?(l, r)
      when "!=", "<>" then !eq?(l, r)
      when "contains"
        case l
        when String then !r.nil? && l.include?(out_s(r))
        when Array then !r.nil? && l.include?(r)
        when Hash then !r.nil? && l.key?(r)
        else false
        end
      when "<", ">", "<=", ">="
        if (l.is_a?(Numeric) && r.is_a?(Numeric)) || (l.is_a?(String) && r.is_a?(String))
          (l <=> r).send({ "<" => :<, ">" => :>, "<=" => :<=, ">=" => :>= }[op], 0)
        else
          false
        end
      else raise SyntaxError, "Unknown operator #{op}"
      end
    end

    def render_nodes(nodes, out)
      nodes.each do |node|
        break if @interrupt != :none
        case node.kind
        when :text then out << node.text
        when :output then out << out_s(eval_output(node))
        when :assign then assign(node.text, eval_output(node))
        when :capture
          buf = []
          render_nodes(node.bodies[0], buf)
          assign(node.text, buf.join)
        when :if, :unless then render_if(node, out)
        when :case
          matched = false
          node.conds.each_with_index do |c, i|
            next unless eval_cond(c)
            matched = true
            render_nodes(node.bodies[i], out)
          end
          render_nodes(node.else_body, out) if !matched && node.else_body
        when :for then render_for(node, out)
        when :comment then nil
        when :break then @interrupt = :break
        when :continue then @interrupt = :continue
        end
      end
      out
    end

    def render_if(node, out)
      node.conds.each_with_index do |c, i|
        v = eval_cond(c)
        v = !v if i == 0 && node.kind == :unless
        if v
          render_nodes(node.bodies[i], out)
          return
        end
      end
      render_nodes(node.else_body, out) if node.else_body
    end

    def render_for(node, out)
      coll = eval_expr(node.expr)
      items = case coll
              when Array then coll
              when Hash then coll.map { |k, v| [k, v] }
              when String then [coll]
              else []
              end
      items = items.drop(node.offset ? to_i(eval_expr(node.offset)) : 0)
      items = items.take(to_i(eval_expr(node.limit))) if node.limit
      items = items.reverse if node.reversed
      if items.empty?
        render_nodes(node.else_body, out) if node.else_body
        return
      end
      name = node.text
      n = items.size
      scope = {}
      @scopes.push(scope)
      items.each_with_index do |item, i|
        scope[name] = item
        scope["forloop"] = { "length" => n, "index" => i + 1, "index0" => i, "rindex" => n - i, "rindex0" => n - i - 1,
                             "first" => i == 0, "last" => i == n - 1, "name" => "#{name}-#{node.expr.name}" }
        render_nodes(node.bodies[0], out)
        intr = @interrupt
        @interrupt = :none
        break if intr == :break
      end
      @scopes.pop
    end

    def eval_output(node)
      node.filters.reduce(eval_expr(node.expr)) { |v, f| apply_filter(f.name, v, f.args.map { |a| eval_expr(a) }) }
    end

    def to_number(v)
      case v
      when Integer, Float then v
      when String then v.strip.match?(/\A-?\d+\.\d+\z/) ? v.to_f : v.to_i
      else 0
      end
    end

    def to_i(v) = to_number(v).to_i

    ESCAPES = { "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&#39;" }.freeze

    def apply_filter(name, v, args)
      a0, a1 = args
      case name
      when "upcase" then out_s(v).upcase
      when "downcase" then out_s(v).downcase
      when "capitalize" then out_s(v).capitalize
      when "strip" then out_s(v).strip
      when "lstrip" then out_s(v).lstrip
      when "rstrip" then out_s(v).rstrip
      when "strip_newlines" then out_s(v).gsub(/\r?\n/, "")
      when "newline_to_br" then out_s(v).gsub(/\r?\n/, "<br />\n")
      when "escape" then v.nil? ? nil : out_s(v).gsub(/[&<>"']/, ESCAPES)
      when "size"
        case v
        when String, Array, Hash, Integer then v.size
        else 0
        end
      when "join" then (v.is_a?(Array) ? v : [v]).map { |x| out_s(x) }.join(a0.nil? ? " " : out_s(a0))
      when "first" then v.is_a?(Array) ? v.first : nil
      when "last" then v.is_a?(Array) ? v.last : nil
      when "reverse" then v.is_a?(Array) ? v.reverse : v
      when "sort" then v.is_a?(Array) ? v.sort : v
      when "uniq" then v.is_a?(Array) ? v.uniq : v
      when "compact" then v.is_a?(Array) ? v.compact : v
      when "concat" then v.is_a?(Array) && a0.is_a?(Array) ? v + a0 : v
      when "sum" then v.is_a?(Array) ? v.sum { |x| to_number(x) } : 0
      when "split" then out_s(v).split(out_s(a0))
      when "plus" then to_number(v) + to_number(a0)
      when "minus" then to_number(v) - to_number(a0)
      when "times" then to_number(v) * to_number(a0)
      when "divided_by" then to_number(v) / to_number(a0)
      when "modulo" then to_number(v) % to_number(a0)
      when "abs" then to_number(v).abs
      when "floor" then to_number(v).floor.to_i
      when "ceil" then to_number(v).ceil.to_i
      when "default" then truthy?(v) && !empty?(v) ? v : (a0.nil? ? "" : a0)
      when "replace" then out_s(v).gsub(out_s(a0), out_s(a1))
      when "replace_first" then out_s(v).sub(out_s(a0), out_s(a1))
      when "remove" then out_s(v).gsub(out_s(a0), "")
      when "remove_first" then out_s(v).sub(out_s(a0), "")
      when "append" then out_s(v) + out_s(a0)
      when "prepend" then out_s(a0) + out_s(v)
      when "truncate"
        return nil if v.nil?
        len = a0.nil? ? 50 : to_i(a0)
        tail = a1.nil? ? "..." : out_s(a1)
        s = out_s(v)
        l = (len - tail.size).clamp(0, len)
        s.size > len ? s[0, l] + tail : s
      when "truncatewords"
        return nil if v.nil?
        n = [a0.nil? ? 15 : to_i(a0), 1].max
        tail = a1.nil? ? "..." : out_s(a1)
        words = out_s(v).split
        words.size > n ? words.take(n).join(" ") + tail : out_s(v)
      when "date" then date(v, a0)
      else v
      end
    end

    def date(v, fmt)
      return v if fmt.nil? || out_s(fmt).empty?
      t = case v
          when Time then v
          when Integer then Time.at(v)
          when String then Time.parse(v)
          end
      t ? t.strftime(out_s(fmt)) : v
    rescue ArgumentError
      v
    end
  end
end
