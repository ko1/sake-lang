BUILTINS = %w[+ - * / mod = < > dup drop swap over . if else then : ;]
NUM = /\A-?\d+\z/

class RunError < StandardError; end

# returns nodes or nil on syntax error
def parse_line(toks)
  i = 0
  stack = [[]] # each: nodes list
  ctx = []     # frames: [:if, thenNodes, elseNodes or nil] / [:def, name]
  while i < toks.size
    t = toks[i]
    case t
    when ":"
      return nil unless ctx.empty?
      i += 1
      name = toks[i]
      return nil if name.nil? || name =~ NUM || BUILTINS.include?(name)
      ctx << [:def, name]
      stack << []
    when ";"
      return nil unless ctx.size == 1 && ctx[0][0] == :def
      fr = ctx.pop
      body = stack.pop
      stack.last << [:def, fr[1], body]
    when "if"
      ctx << [:if, nil]
      stack << []
    when "else"
      return nil if ctx.empty? || ctx.last[0] != :if || ctx.last[1]
      ctx.last[1] = stack.pop
      stack << []
    when "then"
      return nil if ctx.empty? || ctx.last[0] != :if
      fr = ctx.pop
      if fr[1]
        th = fr[1]
        el = stack.pop
      else
        th = stack.pop
        el = []
      end
      stack.last << [:if, th, el]
    else
      stack.last << (t =~ NUM ? [:num, t.to_i] : [:word, t])
    end
    i += 1
  end
  return nil unless ctx.empty?
  stack[0]
end

class Interp
  def initialize
    @st = []
    @dict = {}
    @depth = 0
  end
  attr_accessor :st

  def need(n, w)
    raise RunError, "stack underflow in #{w}" if @st.size < n
  end

  def run(nodes)
    nodes.each do |nd|
      case nd[0]
      when :num then @st.push(nd[1])
      when :def then @dict[nd[1]] = nd[2]
      when :if
        need(1, "if")
        c = @st.pop
        run(c != 0 ? nd[1] : nd[2])
      when :word then word(nd[1])
      end
    end
  end

  def word(w)
    case w
    when "+", "-", "*", "=", "<", ">"
      need(2, w)
      b = @st.pop
      a = @st.pop
      @st.push(
        case w
        when "+" then a + b
        when "-" then a - b
        when "*" then a * b
        when "=" then a == b ? 1 : 0
        when "<" then a < b ? 1 : 0
        else a > b ? 1 : 0
        end
      )
    when "/", "mod"
      need(2, w)
      raise RunError, "division by zero" if @st[-1] == 0
      b = @st.pop
      a = @st.pop
      q = a.abs / b.abs
      q = -q if (a < 0) != (b < 0)
      @st.push(w == "/" ? q : a - q * b)
    when "dup"
      need(1, w)
      @st.push(@st[-1])
    when "drop"
      need(1, w)
      @st.pop
    when "swap"
      need(2, w)
      @st[-1], @st[-2] = @st[-2], @st[-1]
    when "over"
      need(2, w)
      @st.push(@st[-2])
    when "."
      need(1, w)
      puts @st.pop
    else
      body = @dict[w]
      raise RunError, "unknown word #{w}" if body.nil?
      raise RunError, "too deep" if @depth >= 100
      @depth += 1
      begin
        run(body)
      ensure
        @depth -= 1
      end
    end
  end
end

it = Interp.new
$stdin.each_line.with_index(1) do |raw, n|
  toks = raw.chomp.split(" ")
  nodes = parse_line(toks)
  if nodes.nil?
    puts "line #{n}: syntax error"
    next
  end
  saved = it.st.dup
  begin
    it.run(nodes)
  rescue RunError => e
    it.st = saved
    puts "line #{n}: error: #{e.message}"
  end
end
puts it.st.empty? ? "stack: (empty)" : "stack: #{it.st.join(' ')}"
