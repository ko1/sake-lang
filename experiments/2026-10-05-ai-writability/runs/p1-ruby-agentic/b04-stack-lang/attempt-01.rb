BUILTIN = %w[+ - * / mod = < > dup drop swap over . if then else : ;]

class Err < StandardError; end

def parse(toks)
  # returns AST or nil on syntax error
  i = 0
  stack = []
  in_def = false
  while i < toks.size
    t = toks[i]
    case t
    when ":"
      return nil if in_def || !stack.empty?
      i += 1
      n = toks[i]
      return nil if n.nil? || n =~ /\A-?\d+\z/ || BUILTIN.include?(n)
      in_def = true
    when ";"
      return nil if !in_def || !stack.empty?
      in_def = false
    when "if" then stack << :if
    when "else"
      return nil unless stack.last == :if
      stack[-1] = :else
    when "then"
      return nil if stack.empty?
      stack.pop
    end
    i += 1
  end
  return nil if in_def || !stack.empty?
  build(toks)
end

def build(toks)
  pos = 0
  rd = lambda do |stops|
    out = []
    while pos < toks.size
      t = toks[pos]
      break if stops.include?(t)
      pos += 1
      case t
      when ":"
        name = toks[pos]
        pos += 1
        body = rd.([";"])
        pos += 1
        out << [:def, name, body]
      when "if"
        a = rd.(%w[else then])
        b = []
        if toks[pos] == "else"
          pos += 1
          b = rd.(["then"])
        end
        pos += 1
        out << [:if, a, b]
      else
        out << [:w, t]
      end
    end
    out
  end
  rd.([])
end

$stack = []
$defs = {}
$depth = 0

def pop(n, w)
  raise Err, "stack underflow in #{w}" if $stack.size < n
  $stack.pop(n)
end

def run(items)
  items.each do |it|
    case it[0]
    when :def then $defs[it[1]] = it[2]
    when :if
      v, = pop(1, "if")
      run(v != 0 ? it[1] : it[2])
    else
      word(it[1])
    end
  end
end

def word(w)
  case w
  when /\A-?\d+\z/ then $stack << w.to_i
  when "+" then a, b = pop(2, w); $stack << a + b
  when "-" then a, b = pop(2, w); $stack << a - b
  when "*" then a, b = pop(2, w); $stack << a * b
  when "/"
    a, b = pop(2, w)
    raise Err, "division by zero" if b == 0
    q = a.abs / b.abs
    $stack << ((a < 0) != (b < 0) ? -q : q)
  when "mod"
    a, b = pop(2, w)
    raise Err, "division by zero" if b == 0
    $stack << a.remainder(b)
  when "=" then a, b = pop(2, w); $stack << (a == b ? 1 : 0)
  when "<" then a, b = pop(2, w); $stack << (a < b ? 1 : 0)
  when ">" then a, b = pop(2, w); $stack << (a > b ? 1 : 0)
  when "dup" then a, = pop(1, w); $stack.push(a, a)
  when "drop" then pop(1, w)
  when "swap" then a, b = pop(2, w); $stack.push(b, a)
  when "over" then a, b = pop(2, w); $stack.push(a, b, a)
  when "." then a, = pop(1, w); puts a
  else
    body = $defs[w]
    raise Err, "unknown word #{w}" unless body
    raise Err, "too deep" if $depth >= 100
    $depth += 1
    begin
      run(body)
    ensure
      $depth -= 1
    end
  end
end

$stdin.each_line.with_index(1) do |raw, no|
  toks = raw.chomp.split(/ +/).reject(&:empty?)
  ast = parse(toks)
  if ast.nil?
    puts "line #{no}: syntax error"
    next
  end
  saved = $stack.dup
  $depth = 0
  begin
    run(ast)
  rescue Err => e
    puts "line #{no}: error: #{e.message}"
    $stack = saved
  end
end
puts $stack.empty? ? "stack: (empty)" : "stack: #{$stack.join(" ")}"
