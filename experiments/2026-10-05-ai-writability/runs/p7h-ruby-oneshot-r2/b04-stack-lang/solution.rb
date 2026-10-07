def is_number?(token)
  token =~ /^-?\d+$/
end

def is_builtin?(word)
  %w[+ - * / mod = < > dup drop swap over . if then else : ;].include?(word)
end

def syntax_check(tokens)
  stack = []
  colon_count = 0
  semicolon_count = 0
  in_def = false

  tokens.each_with_index do |token, idx|
    case token
    when ':'
      if in_def
        return false
      end
      in_def = true
      colon_count += 1

      if idx + 1 >= tokens.length
        return false
      end
      name = tokens[idx + 1]
      if is_number?(name) || is_builtin?(name)
        return false
      end
    when ';'
      if !in_def
        return false
      end
      in_def = false
      semicolon_count += 1
    when 'if'
      if in_def
        # Can have if inside def, just check structure
      end
      stack.push('if')
    when 'else'
      if stack.empty? || stack[-1] != 'if'
        return false
      end
    when 'then'
      if stack.empty? || stack[-1] != 'if'
        return false
      end
      stack.pop
    end
  end

  return false if colon_count != semicolon_count
  return false if !stack.empty?
  return false if in_def
  true
end

def find_matching_then(tokens, if_idx)
  depth = 1
  idx = if_idx + 1
  else_idx = nil

  while idx < tokens.length && depth > 0
    if tokens[idx] == 'if'
      depth += 1
    elsif tokens[idx] == 'then'
      depth -= 1
      if depth == 0
        return [idx, else_idx]
      end
    elsif tokens[idx] == 'else' && depth == 1 && !else_idx
      else_idx = idx
    end
    idx += 1
  end

  [idx - 1, else_idx]
end

def find_matching_semicolon(tokens, colon_idx)
  depth = 1
  idx = colon_idx + 1

  while idx < tokens.length && depth > 0
    if tokens[idx] == ':'
      depth += 1
    elsif tokens[idx] == ';'
      depth -= 1
      if depth == 0
        return idx
      end
    end
    idx += 1
  end

  -1
end

def execute_tokens(tokens, stack, definitions, depth, start = 0, end_idx = nil)
  end_idx ||= tokens.length
  idx = start

  while idx < end_idx
    token = tokens[idx]

    if token == 'then' || token == 'else' || token == ';'
      return idx
    end

    case token
    when ':'
      semi_idx = find_matching_semicolon(tokens, idx)
      name = tokens[idx + 1]
      body = tokens[(idx + 2)...semi_idx]
      definitions[name] = body
      idx = semi_idx + 1

    when 'if'
      if stack.empty?
        raise RuntimeError.new("stack underflow in if")
      end
      condition = stack.pop

      then_idx, else_idx = find_matching_then(tokens, idx)
      if else_idx
        then_body = tokens[(idx + 1)...else_idx]
        else_body = tokens[(else_idx + 1)...then_idx]
      else
        then_body = tokens[(idx + 1)...then_idx]
        else_body = []
      end

      if condition != 0
        execute_tokens(then_body, stack, definitions, depth, 0, then_body.length)
      elsif else_body.length > 0
        execute_tokens(else_body, stack, definitions, depth, 0, else_body.length)
      end

      idx = then_idx + 1

    when '.'
      if stack.empty?
        raise RuntimeError.new("stack underflow in .")
      end
      puts stack.pop
      idx += 1

    when '+'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in +")
      end
      b = stack.pop
      a = stack.pop
      stack.push(a + b)
      idx += 1

    when '-'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in -")
      end
      b = stack.pop
      a = stack.pop
      stack.push(a - b)
      idx += 1

    when '*'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in *")
      end
      b = stack.pop
      a = stack.pop
      stack.push(a * b)
      idx += 1

    when '/'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in /")
      end
      b = stack.pop
      a = stack.pop
      if b == 0
        raise RuntimeError.new("division by zero")
      end
      stack.push((a.to_f / b).truncate)
      idx += 1

    when 'mod'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in mod")
      end
      b = stack.pop
      a = stack.pop
      if b == 0
        raise RuntimeError.new("division by zero")
      end
      stack.push(a % b)
      idx += 1

    when '='
      if stack.length < 2
        raise RuntimeError.new("stack underflow in =")
      end
      b = stack.pop
      a = stack.pop
      stack.push(a == b ? 1 : 0)
      idx += 1

    when '<'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in <")
      end
      b = stack.pop
      a = stack.pop
      stack.push(a < b ? 1 : 0)
      idx += 1

    when '>'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in >")
      end
      b = stack.pop
      a = stack.pop
      stack.push(a > b ? 1 : 0)
      idx += 1

    when 'dup'
      if stack.empty?
        raise RuntimeError.new("stack underflow in dup")
      end
      stack.push(stack[-1])
      idx += 1

    when 'drop'
      if stack.empty?
        raise RuntimeError.new("stack underflow in drop")
      end
      stack.pop
      idx += 1

    when 'swap'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in swap")
      end
      stack[-1], stack[-2] = stack[-2], stack[-1]
      idx += 1

    when 'over'
      if stack.length < 2
        raise RuntimeError.new("stack underflow in over")
      end
      stack.push(stack[-2])
      idx += 1

    else
      if is_number?(token)
        stack.push(token.to_i)
        idx += 1
      elsif definitions[token]
        if depth >= 100
          raise RuntimeError.new("too deep")
        end
        execute_tokens(definitions[token], stack, definitions, depth + 1, 0, definitions[token].length)
        idx += 1
      else
        raise RuntimeError.new("unknown word #{token}")
      end
    end
  end

  idx
end

stack = []
definitions = {}
line_num = 0

$stdin.each_line do |line|
  line_num += 1
  line = line.chomp

  tokens = line.split(/\s+/)
  next if tokens.empty?

  unless syntax_check(tokens)
    puts "line #{line_num}: syntax error"
    next
  end

  stack_backup = stack.dup

  begin
    execute_tokens(tokens, stack, definitions, 0, 0, tokens.length)
  rescue RuntimeError => e
    stack.clear
    stack.concat(stack_backup)
    puts "line #{line_num}: error: #{e.message}"
  end
end

puts "stack: " + (stack.empty? ? "(empty)" : stack.join(" "))
