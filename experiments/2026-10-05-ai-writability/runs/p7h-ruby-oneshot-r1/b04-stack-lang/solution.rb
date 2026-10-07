#!/usr/bin/env ruby

BUILT_INS = Set.new(["+", "-", "*", "/", "mod", "=", "<", ">", "dup", "drop", "swap", "over", "."])

stack = []
definitions = {}
output = []
call_depth = 0

def is_number?(token)
  token =~ /^-?\d+$/
end

def validate_syntax(tokens)
  if_depth = 0
  def_depth = 0
  tokens.each_with_index do |token, idx|
    if token == "if"
      if_depth += 1
    elsif token == "then"
      return false if if_depth == 0
      if_depth -= 1
    elsif token == "else"
      return false if if_depth == 0
    elsif token == ":"
      return false if def_depth > 0 || if_depth > 0
      return false unless idx + 1 < tokens.length
      next_token = tokens[idx + 1]
      return false if is_number?(next_token) || BUILT_INS.include?(next_token)
      def_depth += 1
    elsif token == ";"
      return false if def_depth == 0
      def_depth -= 1
    end
  end

  return false if if_depth != 0 || def_depth != 0
  true
end

def parse_if_then(tokens, start_idx)
  if_idx = start_idx
  then_idx = nil
  else_idx = nil
  nesting = 0

  (if_idx + 1...tokens.length).each do |i|
    if tokens[i] == "if"
      nesting += 1
    elsif tokens[i] == "then"
      if nesting == 0
        then_idx = i
        break
      else
        nesting -= 1
      end
    elsif tokens[i] == "else" && nesting == 0
      else_idx = i
    end
  end

  return nil if then_idx.nil?

  if else_idx
    [tokens[if_idx + 1...else_idx], tokens[else_idx + 1...then_idx], then_idx]
  else
    [tokens[if_idx + 1...then_idx], [], then_idx]
  end
end

def run_tokens(tokens, stack, definitions, output, call_depth)
  i = 0
  while i < tokens.length
    token = tokens[i]

    if is_number?(token)
      stack.push(token.to_i)
    elsif token == "+"
      return "stack underflow in +" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a + b)
    elsif token == "-"
      return "stack underflow in -" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a - b)
    elsif token == "*"
      return "stack underflow in *" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a * b)
    elsif token == "/"
      return "stack underflow in /" if stack.length < 2
      b = stack.pop
      a = stack.pop
      return "division by zero" if b == 0
      stack.push((a.to_f / b).truncate)
    elsif token == "mod"
      return "stack underflow in mod" if stack.length < 2
      b = stack.pop
      a = stack.pop
      return "division by zero" if b == 0
      stack.push(a % b)
    elsif token == "="
      return "stack underflow in =" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a == b ? 1 : 0)
    elsif token == "<"
      return "stack underflow in <" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a < b ? 1 : 0)
    elsif token == ">"
      return "stack underflow in >" if stack.length < 2
      b = stack.pop
      a = stack.pop
      stack.push(a > b ? 1 : 0)
    elsif token == "dup"
      return "stack underflow in dup" if stack.empty?
      stack.push(stack[-1])
    elsif token == "drop"
      return "stack underflow in drop" if stack.empty?
      stack.pop
    elsif token == "swap"
      return "stack underflow in swap" if stack.length < 2
      stack[-1], stack[-2] = stack[-2], stack[-1]
    elsif token == "over"
      return "stack underflow in over" if stack.length < 2
      stack.push(stack[-2])
    elsif token == "."
      return "stack underflow in ." if stack.empty?
      output.push(stack.pop.to_s)
    elsif token == "if"
      if_data = parse_if_then(tokens, i)
      return "stack underflow in if" if stack.empty?
      cond = stack.pop

      if cond != 0
        err = run_tokens(if_data[0], stack, definitions, output, call_depth)
        return err if err
      elsif !if_data[1].empty?
        err = run_tokens(if_data[1], stack, definitions, output, call_depth)
        return err if err
      end

      i = if_data[2]
    elsif token == ":"
      def_name = tokens[i + 1]
      semi_idx = nil
      (i + 2...tokens.length).each do |j|
        if tokens[j] == ";"
          semi_idx = j
          break
        end
      end

      definitions[def_name] = tokens[(i + 2)...semi_idx]
      i = semi_idx
    elsif token == "then" || token == "else" || token == ";" || token == "then"
      # These are handled by if/: so skip
    elsif definitions[token]
      return "too deep" if call_depth >= 100
      err = run_tokens(definitions[token], stack, definitions, output, call_depth + 1)
      return err if err
    else
      return "unknown word #{token}"
    end

    i += 1
  end

  nil
end

STDIN.each_with_index do |line, idx|
  line_num = idx + 1
  line = line.strip

  next if line.empty?

  tokens = line.split(/\s+/)

  unless validate_syntax(tokens)
    puts "line #{line_num}: syntax error"
    next
  end

  original_stack = stack.dup
  err = run_tokens(tokens, stack, definitions, output, call_depth)

  if err
    puts "line #{line_num}: error: #{err}"
    stack = original_stack
  end
end

output.each { |o| puts o }

if stack.empty?
  puts "stack: (empty)"
else
  puts "stack: #{stack.join(" ")}"
end
