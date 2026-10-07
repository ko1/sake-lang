BUILTIN_WORDS = Set.new(%w[+ - * / mod = < > dup drop swap over . if else then :])

def check_syntax(tokens)
  depth = 0
  i = 0
  while i < tokens.length
    token = tokens[i]

    if token == ':'
      # Check for definition syntax
      if depth > 0
        return "syntax error"  # : inside if
      end

      if i + 1 >= tokens.length
        return "syntax error"  # : without name
      end

      name_token = tokens[i + 1]
      if name_token.match?(/^-?\d+$/) || BUILTIN_WORDS.include?(name_token)
        return "syntax error"  # : followed by number or builtin
      end

      # Find matching ;
      j = i + 2
      found_semicolon = false
      while j < tokens.length
        if tokens[j] == ';'
          found_semicolon = true
          break
        elsif tokens[j] == ':'
          return "syntax error"  # : inside definition
        end
        j += 1
      end

      return "syntax error" unless found_semicolon

      i = j + 1
    elsif token == 'if'
      depth += 1
      i += 1
    elsif token == 'else'
      if depth == 0
        return "syntax error"  # else without if
      end
      i += 1
    elsif token == 'then'
      if depth == 0
        return "syntax error"  # then without if
      end
      depth -= 1
      i += 1
    elsif token == ';'
      if depth > 0
        return "syntax error"  # ; while inside if
      end
      return "syntax error"  # ; without :
    else
      i += 1
    end
  end

  return "syntax error" if depth > 0  # Unclosed if
  nil
end

def run_tokens(tokens, stack, defs, depth)
  i = 0

  while i < tokens.length
    token = tokens[i]

    # Check for number
    if token.match?(/^-?\d+$/)
      stack.push(token.to_i)
      i += 1

    elsif token == '+'
      raise "stack underflow in +" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a + b)
      i += 1

    elsif token == '-'
      raise "stack underflow in -" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a - b)
      i += 1

    elsif token == '*'
      raise "stack underflow in *" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a * b)
      i += 1

    elsif token == '/'
      raise "stack underflow in /" if stack.length < 2
      b = stack.pop
      a = stack.pop
      raise "division by zero" if b == 0
      stack.push((a.to_f / b).to_i)
      i += 1

    elsif token == 'mod'
      raise "stack underflow in mod" if stack.length < 2
      b = stack.pop
      a = stack.pop
      raise "division by zero" if b == 0
      # Remainder has the sign of a (the dividend)
      quotient = (a.to_f / b).to_i
      remainder = a - quotient * b
      stack.push(remainder)
      i += 1

    elsif token == '='
      raise "stack underflow in =" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a == b ? 1 : 0)
      i += 1

    elsif token == '<'
      raise "stack underflow in <" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a < b ? 1 : 0)
      i += 1

    elsif token == '>'
      raise "stack underflow in >" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a > b ? 1 : 0)
      i += 1

    elsif token == 'dup'
      raise "stack underflow in dup" if stack.length < 1
      stack.push(stack[-1])
      i += 1

    elsif token == 'drop'
      raise "stack underflow in drop" if stack.length < 1
      stack.pop
      i += 1

    elsif token == 'swap'
      raise "stack underflow in swap" if stack.length < 2
      a = stack.pop
      b = stack.pop
      stack.push(a)
      stack.push(b)
      i += 1

    elsif token == 'over'
      raise "stack underflow in over" if stack.length < 2
      stack.push(stack[-2])
      i += 1

    elsif token == '.'
      raise "stack underflow in ." if stack.length < 1
      puts stack.pop
      i += 1

    elsif token == 'if'
      raise "stack underflow in if" if stack.length < 1
      cond = stack.pop

      # Find matching else and then
      j = i + 1
      else_idx = nil
      then_idx = nil
      depth_local = 0

      while j < tokens.length
        if tokens[j] == 'if'
          depth_local += 1
        elsif tokens[j] == 'else' && depth_local == 0
          else_idx = j
        elsif tokens[j] == 'then'
          if depth_local == 0
            then_idx = j
            break
          else
            depth_local -= 1
          end
        end
        j += 1
      end

      if cond != 0
        # Run if part
        if else_idx.nil?
          run_tokens(tokens[i+1...then_idx], stack, defs, depth)
        else
          run_tokens(tokens[i+1...else_idx], stack, defs, depth)
        end
      else
        # Run else part if present
        if !else_idx.nil?
          run_tokens(tokens[else_idx+1...then_idx], stack, defs, depth)
        end
      end

      i = then_idx + 1

    elsif token == ':'
      # Define word
      name = tokens[i + 1]
      j = i + 2
      while j < tokens.length && tokens[j] != ';'
        j += 1
      end
      defs[name] = tokens[i+2...j]
      i = j + 1

    elsif defs[token]
      # User word
      raise "too deep" if depth >= 100
      run_tokens(defs[token], stack, defs, depth + 1)
      i += 1

    else
      raise "unknown word #{token}"
    end
  end
end

stack = []
defs = {}

STDIN.readlines.each_with_index do |line, idx|
  line_num = idx + 1
  line = line.chomp

  next if line.strip.empty?

  tokens = line.split
  next if tokens.empty?

  # Check syntax
  error = check_syntax(tokens)
  if error
    puts "line #{line_num}: #{error}"
    next
  end

  # Save stack state for rollback
  saved_stack = stack.dup

  begin
    run_tokens(tokens, stack, defs, 0)
  rescue => e
    puts "line #{line_num}: error: #{e.message}"
    stack = saved_stack
  end
end

if stack.empty?
  puts "stack: (empty)"
else
  puts "stack: #{stack.join(' ')}"
end
