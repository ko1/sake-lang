class Instr
  attr_accessor :op, :a, :b

  def initialize(op, a = nil, b = nil)
    @op = op
    @a = a
    @b = b
  end

  def to_s = [@op, @a, @b].compact.join(" ")
end

class Frame
  attr_accessor :ret, :locals

  def initialize(ret, locals)
    @ret = ret
    @locals = locals
  end
end

class VMError < StandardError
  attr_reader :pc

  def initialize(message, pc)
    super(message)
    @pc = pc
  end
end

def parse_arg(s) = s.match?(/\A-?\d+\z/) ? s.to_i : s

def assemble(text)
  labels = {}
  code = []
  text.each_line do |raw|
    line = raw.sub(/;.*/, "").strip
    next if line.empty?
    if (m = line.match(/\A(\w+):\z/)) && m
      labels[m[1]] = code.size
      next
    end
    words = line.split(" ")
    op = words[0].to_sym
    a = words[1] ? parse_arg(words[1]) : nil
    b = words[2] ? parse_arg(words[2]) : nil
    code << Instr.new(op, a, b)
  end
  code.each do |ins|
    if ins.a.is_a?(String)
      addr = labels[ins.a]
      raise VMError.new("undefined label #{ins.a}", -1) if !addr    
      ins.a = addr
    end
  end
  code
end

def pop!(stack, pc)
  raise VMError.new("stack underflow", pc) if stack.empty?
  stack.pop
end

def run(code, out)
  stack = []
  frames = [Frame.new(-1, [])]
  pc = 0
  steps = 0
  max_stack = 0
  max_depth = 1
  counts = Hash.new(0)
  loop do
    ins = code[pc]
    raise VMError.new("pc out of range", pc) if !ins    
    op = ins.op
    a = ins.a
    counts[op] += 1
    steps += 1
    raise VMError.new("step limit exceeded", pc) if steps > 100_000
    frame = frames.last
    next_pc = pc + 1
    case op
    when :push then stack.push(a)
    when :load then stack.push(frame.locals[a] || 0)
    when :store then frame.locals[a] = pop!(stack, pc)
    when :add, :sub, :mul, :div, :mod, :lt, :eq
      y = pop!(stack, pc)
      x = pop!(stack, pc)
      stack.push(
        case op
        when :add then x + y
        when :sub then x - y
        when :mul then x * y
        when :div then x / y
        when :mod then x % y
        when :lt then x < y ? 1 : 0
        when :eq then x == y ? 1 : 0
        end
      )
    when :dup
      v = pop!(stack, pc)
      stack.push(v, v)
    when :jmp then next_pc = a
    when :jz then next_pc = a if pop!(stack, pc) == 0
    when :call
      locals = []
      ins.b.times { locals.unshift(pop!(stack, pc)) }
      frames.push(Frame.new(pc + 1, locals))
      max_depth = frames.size if frames.size > max_depth
      next_pc = a
    when :ret
      frames.pop
      next_pc = frame.ret
    when :print then out << pop!(stack, pc).to_s
    when :halt then break
    else raise VMError.new("bad opcode #{op}", pc)
    end
    max_stack = stack.size if stack.size > max_stack
    pc = next_pc
  end
  { steps: steps, max_stack: max_stack, max_depth: max_depth, counts: counts }
end

PROGRAM_OK = <<~ASM
    call main 0
    halt
  fact:            ; fact(n)
    load 0
    push 2
    lt
    jz fact_rec
    push 1
    ret
  fact_rec:
    load 0
    load 0
    push 1
    sub
    call fact 1
    mul
    ret
  fib:             ; fib(n), naive recursion
    load 0
    push 2
    lt
    jz fib_rec
    load 0
    ret
  fib_rec:
    load 0
    push 1
    sub
    call fib 1
    load 0
    push 2
    sub
    call fib 1
    add
    ret
  main:
    push 10
    call fact 1
    print
    push 15
    call fib 1
    print
    push 0         ; sum of 1..100 with locals 0 (sum) and 1 (i)
    store 0
    push 1
    store 1
  loop:
    push 100
    load 1
    lt
    jz body
    jmp done
  body:
    load 0
    load 1
    add
    store 0
    load 1
    push 1
    add
    store 1
    jmp loop
  done:
    load 0
    print
    push 0
    ret
ASM

PROGRAM_BAD = <<~ASM
    push 1
    push 2
    add
    mul           ; needs two operands
    halt
ASM

PROGRAM_UNDEFINED = "  push 1\n  jz nowhere\n  halt\n"

[["ok", PROGRAM_OK], ["bad", PROGRAM_BAD], ["undefined", PROGRAM_UNDEFINED]].each do |name, text|
  puts "== #{name}"
  out = []
  begin
    code = assemble(text)
    puts "#{code.size} instructions; first: #{code.first}; last: #{code.last}"
    stats = run(code, out)
    puts "output: #{out.join(", ")}"
    puts "steps=#{stats[:steps]} max_stack=#{stats[:max_stack]} max_depth=#{stats[:max_depth]}"
    top = stats[:counts].sort_by { |op, n| [-n, op.to_s] }.take(4)
    puts "hot: #{top.map { |op, n| "#{op}=#{n}" }.join(" ")}"
  rescue VMError => e
    puts "output so far: #{out.join(", ")}"
    puts "vm error at #{e.pc}: #{e.message}"
  end
end
