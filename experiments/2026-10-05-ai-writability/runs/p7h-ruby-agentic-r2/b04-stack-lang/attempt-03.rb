#!/usr/bin/env ruby

def is_number?(token)
  token =~ /^-?\d+$/
end

def is_builtin?(word)
  %w[+ - * / mod = < > dup drop swap over . if then else : ;].include?(word)
end

def check_syntax(tokens)
  if_depth = 0
  in_def = false

  i = 0
  while i < tokens.length
    token = tokens[i]

    case token
    when ':'
      if in_def
        return true  # error
      end
      if if_depth > 0
        return true  # error
      end
      if i + 1 >= tokens.length
        return true  # error
      end
      next_token = tokens[i + 1]
      if is_number?(next_token) || is_builtin?(next_token)
        return true  # error
      end
      in_def = true
      i += 1
      # Skip to ;
      while i < tokens.length && tokens[i] != ';'
        i += 1
      end
      if i >= tokens.length
        return true  # error
      end
      in_def = false
    when ';'
      return true  # error (unmatched)
    when 'if'
      if_depth += 1
    when 'else'
      if if_depth == 0
        return true  # error
      end
    when 'then'
      if if_depth == 0
        return true  # error
      end
      if_depth -= 1
    end

    i += 1
  end

  return true if in_def
  return true if if_depth > 0
  false
end

def find_matching_then(tokens, if_pos)
  depth = 1
  else_pos = nil

  (if_pos + 1).upto(tokens.length - 1) do |i|
    if tokens[i] == 'if'
      depth += 1
    elsif tokens[i] == 'else' && depth == 1 && else_pos.nil?
      else_pos = i
    elsif tokens[i] == 'then'
      depth -= 1
      if depth == 0
        return { else: else_pos, then: i }
      end
    end
  end

  nil
end

class StackMachine
  def initialize
    @stack = []
    @dict = {}
    @output = []
    @depth = 0
  end

  def run_line(tokens, line_no)
    if check_syntax(tokens)
      @output << "line #{line_no}: syntax error"
      return
    end

    original_stack = @stack.dup

    begin
      execute_tokens(tokens, 0, tokens.length)
    rescue RuntimeError => e
      @stack = original_stack
      @output << "line #{line_no}: error: #{e.message}"
    end
  end

  def execute_tokens(tokens, start_idx, end_idx)
    i = start_idx
    while i < end_idx
      token = tokens[i]

      if is_number?(token)
        @stack.push(token.to_i)
      elsif token == '+'
        raise "stack underflow in +" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        @stack.push(a + b)
      elsif token == '-'
        raise "stack underflow in -" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        @stack.push(a - b)
      elsif token == '*'
        raise "stack underflow in *" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        @stack.push(a * b)
      elsif token == '/'
        raise "stack underflow in /" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        raise "division by zero" if b == 0
        @stack.push((a.to_f / b).truncate)
      elsif token == 'mod'
        raise "stack underflow in mod" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        raise "division by zero" if b == 0
        # Ruby's % has sign of divisor, but spec wants sign of dividend
        rem = a % b
        if rem != 0 && (a < 0) != (b < 0)
          rem -= b
        end
        @stack.push(rem)
      elsif token == '='
        raise "stack underflow in =" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        @stack.push(a == b ? 1 : 0)
      elsif token == '<'
        raise "stack underflow in <" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        @stack.push(a < b ? 1 : 0)
      elsif token == '>'
        raise "stack underflow in >" if @stack.length < 2
        b = @stack.pop
        a = @stack.pop
        @stack.push(a > b ? 1 : 0)
      elsif token == 'dup'
        raise "stack underflow in dup" if @stack.length < 1
        @stack.push(@stack[-1])
      elsif token == 'drop'
        raise "stack underflow in drop" if @stack.length < 1
        @stack.pop
      elsif token == 'swap'
        raise "stack underflow in swap" if @stack.length < 2
        @stack[-1], @stack[-2] = @stack[-2], @stack[-1]
      elsif token == 'over'
        raise "stack underflow in over" if @stack.length < 2
        @stack.push(@stack[-2])
      elsif token == '.'
        raise "stack underflow in ." if @stack.length < 1
        @output << @stack.pop.to_s
      elsif token == 'if'
        raise "stack underflow in if" if @stack.length < 1
        cond = @stack.pop
        match = find_matching_then(tokens, i)
        if match
          if cond != 0
            execute_tokens(tokens, i + 1, match[:else] || match[:then])
          elsif match[:else]
            execute_tokens(tokens, match[:else] + 1, match[:then])
          end
          i = match[:then]
        end
      elsif token == ':'
        # Find matching ;
        j = i + 2
        while j < tokens.length && tokens[j] != ';'
          j += 1
        end
        name = tokens[i + 1]
        body = tokens[i + 2...j]
        @dict[name] = body
        i = j
      elsif token == 'then' || token == 'else' || token == ';'
        # These are handled by if/: already
        nil
      elsif @dict[token]
        raise "too deep" if @depth >= 100
        @depth += 1
        execute_tokens(@dict[token], 0, @dict[token].length)
        @depth -= 1
      else
        raise "unknown word #{token}"
      end

      i += 1
    end
  end

  def print_output
    @output.each { |line| puts line }
  end

  def print_stack
    if @stack.empty?
      puts "stack: (empty)"
    else
      puts "stack: " + @stack.join(" ")
    end
  end
end

machine = StackMachine.new

ARGF.each_with_index do |line, idx|
  line_no = idx + 1
  line = line.chomp
  tokens = line.split(/\s+/)

  next if tokens.empty?

  machine.run_line(tokens, line_no)
end

machine.print_output
machine.print_stack
