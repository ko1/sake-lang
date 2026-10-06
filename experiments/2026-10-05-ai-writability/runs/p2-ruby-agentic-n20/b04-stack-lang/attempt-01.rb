BUILTIN = %w[+ - * / mod = < > dup drop swap over . if else then : ;].freeze
ARITY = { "+" => 2, "-" => 2, "*" => 2, "/" => 2, "mod" => 2, "=" => 2, "<" => 2, ">" => 2,
          "dup" => 1, "drop" => 1, "swap" => 2, "over" => 2, "." => 1 }.freeze

class RunError < StandardError; end

# Returns tree or nil on syntax error. Tree items: Integer, String(word), [:if, then, else], [:def, name, body]
def parse(tokens)
  stack = [[:top, []]] # frames: [kind, items, extra...]
  tokens.each_with_index do |t, i|
    top = stack.last
    case t
    when "if"
      stack << [:if, [], nil, false] # kind, then-items, else-items, in_else
    when "else"
      return nil unless top[0] == :if && !top[3]
      top[2] = []
      top[3] = true
    when "then"
      return nil unless top[0] == :if
      stack.pop
      stack.last[1 + 0] # no-op
      item = [:if, top[1], top[2] || []]
      cur = stack.last
      (cur[0] == :if && cur[3] ? cur[2] : cur[1]) << item
    when ":"
      return nil unless top[0] == :top
      name = tokens[i + 1]
      return nil if name.nil? || name =~ /\A-?\d+\z/ || BUILTIN.include?(name)
      stack << [:def, [], name]
    when ";"
      return nil unless top[0] == :def
      stack.pop
      stack.last[1] << [:def, top[2], top[1]]
    else
      item = t =~ /\A-?\d+\z/ ? t.to_i : t
      # skip the name token right after ':'
      if top[0] == :def && top[3] != :named
        top[3] = :named
        next
      end
      (top[0] == :if && top[3] ? top[2] : top[1]) << item
    end
  end
  return nil unless stack.size == 1
  stack[0][1]
end

$defs = {}
$st = []
$depth = 0

def run(items)
  items.each do |it|
    case it
    when Integer
      $st << it
    when String
      word(it)
    else
      case it[0]
      when :def
        $defs[it[1]] = it[2]
      when :if
        raise RunError, "stack underflow in if" if $st.empty?
        v = $st.pop
        run(v != 0 ? it[1] : it[2])
      end
    end
  end
end

def word(w)
  if (n = ARITY[w])
    raise RunError, "stack underflow in #{w}" if $st.size < n
    case w
    when "+" then b = $st.pop; a = $st.pop; $st << a + b
    when "-" then b = $st.pop; a = $st.pop; $st << a - b
    when "*" then b = $st.pop; a = $st.pop; $st << a * b
    when "/", "mod"
      b = $st.pop
      a = $st.pop
      raise RunError, "division by zero" if b == 0
      q = a.abs / b.abs
      q = -q if (a < 0) != (b < 0)
      $st << (w == "/" ? q : a - b * q)
    when "=" then b = $st.pop; a = $st.pop; $st << (a == b ? 1 : 0)
    when "<" then b = $st.pop; a = $st.pop; $st << (a < b ? 1 : 0)
    when ">" then b = $st.pop; a = $st.pop; $st << (a > b ? 1 : 0)
    when "dup" then $st << $st[-1]
    when "drop" then $st.pop
    when "swap" then b = $st.pop; a = $st.pop; $st << b << a
    when "over" then $st << $st[-2]
    when "." then puts $st.pop
    end
  else
    body = $defs[w]
    raise RunError, "unknown word #{w}" unless body
    raise RunError, "too deep" if $depth >= 100
    $depth += 1
    begin
      run(body)
    ensure
      $depth -= 1
    end
  end
end

$stdin.each_line.with_index(1) do |line, no|
  tokens = line.chomp.split(/ +/).reject(&:empty?)
  tree = parse(tokens)
  if tree.nil?
    puts "line #{no}: syntax error"
    next
  end
  saved = $st.dup
  $depth = 0
  begin
    run(tree)
  rescue RunError => e
    $st = saved
    puts "line #{no}: error: #{e.message}"
  end
end
puts "stack: " + ($st.empty? ? "(empty)" : $st.join(" "))
