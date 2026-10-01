class Instr
  attr_reader :op, :line
  attr_accessor :arg

  def initialize(op, arg, line)
    @op = op
    @arg = arg
    @line = line
  end
end

class AsmError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

class VMError < StandardError
  attr_reader :pc

  def initialize(message, pc)
    super(message)
    @pc = pc
  end
end

def arg_kind(op)
  if ["push"].include?(op)
    :int
  elsif ["jmp", "jz", "jnz", "call"].include?(op)
    :label
  elsif ["load", "store"].include?(op)
    :name
  elsif ["pop", "dup", "swap", "over", "add", "sub", "mul", "div", "mod",
         "lt", "eq", "print", "ret", "halt"].include?(op)
    :none
  else
    nil
  end
end

def assemble(source)
  code = []
  labels = {}
  lineno = 0
  source.each_line do |raw|
    lineno += 1
    line = raw.sub(/;.*/, "").strip
    next if line.empty?
    m = line.match(/\A(\w+):\z/)
    if m
      name = m[1]
      raise AsmError.new("duplicate label '#{name}'", lineno) if labels.key?(name)
      labels[name] = code.size
      next
    end
    parts = line.split(/\s+/)
    op = parts[0].downcase
    kind = arg_kind(op)
    raise AsmError.new("unknown instruction '#{op}'", lineno) if kind.nil?
    want = kind == :none ? 1 : 2
    raise AsmError.new("'#{op}' takes #{want - 1} operand(s)", lineno) if parts.size != want
    arg = nil
    if kind == :int
      arg = Integer(parts[1]) rescue raise(AsmError.new("bad number '#{parts[1]}'", lineno))
    elsif kind != :none
      arg = parts[1]
    end
    code << Instr.new(op, arg, lineno)
  end
  code.each do |ins|
    next unless arg_kind(ins.op) == :label
    target = labels[ins.arg]
    raise AsmError.new("undefined label '#{ins.arg}'", ins.line) if target.nil?
    ins.arg = target
  end
  code
end

def pop1(stack, pc)
  v = stack.pop
  raise VMError.new("stack underflow", pc) if v.nil?
  v
end

def run(code, max_steps)
  stack = []
  frames = []
  vars = {}
  output = []
  pc = 0
  steps = 0
  while pc < code.size
    steps += 1
    raise VMError.new("step limit #{max_steps} exceeded", pc) if steps > max_steps
    ins = code[pc]
    op = ins.op
    arg = ins.arg
    pc += 1
    if op == "push"
      stack.push(arg)
    elsif op == "pop"
      pop1(stack, pc - 1)
    elsif op == "dup"
      v = pop1(stack, pc - 1)
      stack.push(v, v)
    elsif op == "swap"
      b = pop1(stack, pc - 1)
      a = pop1(stack, pc - 1)
      stack.push(b, a)
    elsif op == "over"
      b = pop1(stack, pc - 1)
      a = pop1(stack, pc - 1)
      stack.push(a, b, a)
    elsif ["add", "sub", "mul", "div", "mod", "lt", "eq"].include?(op)
      b = pop1(stack, pc - 1)
      a = pop1(stack, pc - 1)
      raise VMError.new("division by zero", pc - 1) if b == 0 && (op == "div" || op == "mod")
      r = case op
          when "add" then a + b
          when "sub" then a - b
          when "mul" then a * b
          when "div" then a / b
          when "mod" then a % b
          when "lt" then a < b ? 1 : 0
          else a == b ? 1 : 0
          end
      stack.push(r)
    elsif op == "jmp"
      pc = arg
    elsif op == "jz"
      pc = arg if pop1(stack, pc - 1) == 0
    elsif op == "jnz"
      pc = arg if pop1(stack, pc - 1) != 0
    elsif op == "call"
      frames.push(pc)
      pc = arg
    elsif op == "ret"
      back = frames.pop
      raise VMError.new("return without call", pc - 1) if back.nil?
      pc = back
    elsif op == "load"
      v = vars[arg]
      raise VMError.new("unset variable '#{arg}'", pc - 1) if v.nil?
      stack.push(v)
    elsif op == "store"
      vars[arg] = pop1(stack, pc - 1)
    elsif op == "print"
      output.push(pop1(stack, pc - 1))
    else
      break
    end
  end
  { output: output, steps: steps, depth: stack.size }
end

programs = [
  ["factorial", "push 1\nstore acc\npush 10\nstore n\nloop:\n  load n\n  jz done\n  load acc\n  load n\n  mul\n  store acc\n  load n\n  push 1\n  sub\n  store n\n  jmp loop\ndone:\n  load acc\n  print\n  halt\n"],
  ["fibonacci", "push 0\npush 1\npush 12\nstore k\nnext:   ; a b on stack\n  over\n  print\n  swap\n  over\n  add\n  load k\n  push 1\n  sub\n  dup\n  store k\n  jnz next\n  pop\n  pop\n"],
  ["gcd calls", "push 1071\npush 462\ncall gcd\nprint\npush 270\npush 192\ncall gcd\nprint\nhalt\ngcd:\n  dup\n  jz gcd_end\n  swap\n  over\n  mod\n  jmp gcd\ngcd_end:\n  pop\n  ret\n"],
  ["underflow", "push 1\nadd\nprint\n"],
  ["divzero", "push 4\npush 0\ndiv\n"],
  ["forever", "top:\n  push 1\n  pop\n  jmp top\n"],
  ["bad label", "push 1\njnz nowhere\n"],
  ["bad op", "push 2\n; comment only\nsquare\n"],
  ["bad number", "push 12x\n"]
]

programs.each do |name, source|
  begin
    code = assemble(source)
    result = run(code, 500)
    result => { output:, steps:, depth: }
    puts format("%-10s ok: %s (%d instrs, %d steps, stack %d)", name, output.join(" "), code.size, steps, depth)
  rescue AsmError => e
    puts format("%-10s asm error, line %d: %s", name, e.line, e.message)
  rescue VMError => e
    puts format("%-10s vm error at pc %d: %s", name, e.pc, e.message)
  end
end
