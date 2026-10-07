#!/usr/bin/env ruby

def is_number?(token)
  token =~ /^-?\d+$/
end

def is_builtin?(word)
  %w[+ - * / mod = < > dup drop swap over . if then else : ;].include?(word)
end

def check_syntax(tokens)
  depth = 0
  if_depth = 0
  in_def = false

  tokens.each_with_index do |token, i|
    case token
    when ':'
      if in_def
        return "line N: syntax error"
      end
      if if_depth > 0
        return "line N: syntax error"
      end
      if i + 1 >= tokens.length
        return "line N: syntax error"
      end
      next_token = tokens[i + 1]
      if is_number?(next_token) || is_builtin?(next_token)
        return "line N: syntax error"
      end
      in_def = true
    when ';'
      unless in_def
        return "line N: syntax error"
      end
      in_def = false
    when 'if'
      if in_def && depth == 0
        depth += 1
      end
      if_depth += 1
    when 'else'
      if if_depth == 0
        return "line N: syntax error"
      end
    when 'then'
      if if_depth == 0
        return "line N: syntax error"
      end
      if_depth -= 1
    end
  end

  return "line N: syntax error" if in_def
  return "line N: syntax error" if if_depth > 0
  nil
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

class Interpreter
  def initialize
    @stack = []
    @dict = {}
    @output = []
    @depth = 0
    @max_depth = 100
  end

  def run(tokens, line_no)
    begin
      original_stack = @stack.dup
      execute(tokens)
    rescue RuntimeError => e
      @stack = original_stack
      @output << "line #{line_no}: error: #{e.message}"
    end
  end

  def execute(tokens, pos = 0, end_pos = nil)
    end_pos ||= tokens.length

    pos.upto(end_pos - 1) do |i|
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
        @stack.push(a % b)
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
            # Run then branch
            if match[:else]
              execute(tokens, i + 1, match[:else])
            else
              execute(tokens, i + 1, match[:then])
            end
          elsif match[:else]
            # Run else branch
            execute(tokens, match[:else] + 1, match[:then])
          end
        end
        return
      elsif token == ':'
        # Skip to ;
        j = i + 2
        while j < tokens.length && tokens[j] != ';'
          j += 1
        end
        return
      elsif @dict[token]
        # Call user-defined word
        raise "too deep" if @depth >= @max_depth
        @depth += 1
        execute(@dict[token])
        @depth -= 1
      else
        raise "unknown word #{token}"
      end
    end
  end

  def define(name, body)
    @dict[name] = body
  end

  def output
    @output
  end

  def stack_str
    if @stack.empty?
      "stack: (empty)"
    else
      "stack: " + @stack.join(" ")
    end
  end
end

interpreter = Interpreter.new

ARGF.each_with_index do |line, idx|
  line_no = idx + 1
  line = line.chomp
  tokens = line.split(/\s+/)

  # Check syntax
  error = check_syntax(tokens)
  if error
    puts "line #{line_no}: syntax error"
    next
  end

  # Process definitions and if/then
  processed = []
  i = 0
  while i < tokens.length
    if tokens[i] == ':'
      # Find matching ;
      j = i + 2
      while j < tokens.length && tokens[j] != ';'
        j += 1
      end
      name = tokens[i + 1]
      body = tokens[i + 2...j]
      interpreter.define(name, body)
      i = j + 1
    else
      processed << tokens[i]
      i += 1
    end
  end

  interpreter.run(processed, line_no)
end

interpreter.output.each { |line| puts line }
puts interpreter.stack_str
