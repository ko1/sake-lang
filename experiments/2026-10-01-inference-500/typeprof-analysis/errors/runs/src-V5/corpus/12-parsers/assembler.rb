class AsmError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

class Stmt
  attr_reader :line, :mnemonic, :operands, :addr

  def initialize(line, mnemonic, operands, addr)
    @line = line
    @mnemonic = mnemonic
    @operands = operands
    @addr = addr
  end
end

OPCODES = {
  "halt" => 0, "mov" => 1, "add" => 2, "sub" => 3, "mul" => 4, "mod" => 5, "cmp" => 6,
  "jmp" => 7, "jeq" => 8, "jne" => 9, "jlt" => 10, "call" => 11, "ret" => 12,
  "push" => 13, "pop" => 14, "out" => 15
}.freeze
NAMES = OPCODES.invert.freeze

def kind_of(mn)
  case mn
  when "mov", "add", "sub", "mul", "mod", "cmp" then :binary
  when "jmp", "jeq", "jne", "jlt", "call" then :jump
  when "push", "pop", "out" then :unary
  else :none
  end
end

def register(s, line)
  m = s.match(/\Ar([0-7])\z/)
  raise AsmError.new("bad register '#{s}'", line) unless m
  m[1].to_i
end

def first_pass(text)
  stmts = []
  labels = {}
  text.lines.each_with_index do |raw, i|
    line = i + 1
    src = raw.sub(/;.*/, "").strip
    if (m = src.match(/\A(\w+):\s*(.*)\z/)) && m
      raise AsmError.new("duplicate label '#{m[1]}'", line) if labels.key?(m[1])
      labels[m[1]] = stmts.size
      src = m[2]
    end
    next if src.empty?
    mn, rest = src.split(/\s+/, 2)
    raise AsmError.new("unknown mnemonic '#{mn}'", line) unless OPCODES.key?(mn)
    operands = rest ? rest.split(",").map(&:strip) : []
    stmts << Stmt.new(line, mn, operands, stmts.size)
  end
  [stmts, labels]
end

def encode(stmt, labels)
  mn = stmt.mnemonic
  ops = stmt.operands
  line = stmt.line
  word = OPCODES[mn] << 20
  want = { binary: 2, jump: 1, unary: 1, none: 0 }[kind_of(mn)]
  raise AsmError.new("#{mn} takes #{want} operand(s)", line) unless ops.size == want
  case kind_of(mn)
  when :binary
    word |= register(ops[0], line) << 16
    src = ops[1]
    if src.start_with?("#")
      v = src[1..].to_i
      raise AsmError.new("immediate out of range: #{v}", line) unless v.between?(-32768, 32767)
      word |= (1 << 19) | (v & 0xFFFF)
    else
      word |= register(src, line)
    end
  when :jump
    target = labels[ops[0]]
    raise AsmError.new("undefined label '#{ops[0]}'", line) if !target    
    word |= target
  when :unary then word |= register(ops[0], line) << 16
  end
  word
end

def assemble(text)
  stmts, labels = first_pass(text)
  stmts.map { |s| encode(s, labels) }
end

def decode(word)
  imm = word & 0xFFFF
  imm -= 0x10000 if imm >= 0x8000
  { op: (word >> 20) & 0x3F, immediate: ((word >> 19) & 1) == 1, dst: (word >> 16) & 7,
    src: word & 7, imm: imm, addr: word & 0xFFFF }
end

def disassemble(word)
  d = decode(word)
  mn = NAMES[d[:op]]
  case kind_of(mn)
  when :binary then "#{mn} r#{d[:dst]}, #{d[:immediate] ? "##{d[:imm]}" : "r#{d[:src]}"}"
  when :jump then "#{mn} #{d[:addr]}"
  when :unary then "#{mn} r#{d[:dst]}"
  else mn
  end
end

def simulate(code, limit)
  regs = [0] * 8
  stack = []
  out = []
  flag = 0
  pc = 0
  steps = 0
  while steps < limit
    d = decode(code[pc])
    dst = d[:dst]
    addr = d[:addr]
    steps += 1
    pc += 1
    value = d[:immediate] ? d[:imm] : regs[d[:src]]
    case d[:op]
    when 0 then return [out, steps]
    when 1 then regs[dst] = value
    when 2 then regs[dst] += value
    when 3 then regs[dst] -= value
    when 4 then regs[dst] *= value
    when 5 then regs[dst] %= value
    when 6 then flag = regs[dst] <=> value
    when 7 then pc = addr
    when 8 then pc = addr if flag == 0
    when 9 then pc = addr if flag != 0
    when 10 then pc = addr if flag < 0
    when 11
      stack.push(pc)
      pc = addr
    when 12 then pc = stack.pop
    when 13 then stack.push(regs[dst])
    when 14 then regs[dst] = stack.pop
    when 15 then out << regs[dst]
    end
  end
  [out, steps]
end

PRIMES_PROGRAM = <<~ASM
  ; print primes below 40 by trial division
          mov r1, #2          ; candidate
  next:   cmp r1, #40
          jeq done
          call isprime
          cmp r0, #1
          jne skip
          out r1
  skip:   add r1, #1
          jmp next
  done:   halt
  isprime:
          push r2
          mov r2, #2          ; divisor
  loop:   mov r3, r2
          mul r3, r2
          cmp r1, r3
          jlt yes             ; divisor^2 > candidate
          mov r3, r1
          mod r3, r2
          cmp r3, #0
          jeq no
          add r2, #1
          jmp loop
  yes:    mov r0, #1
          pop r2
          ret
  no:     mov r0, #0
          pop r2
          ret
ASM

BROKEN_PROGRAMS = [
  "mov r1, #5\nadd r9, r1\n",
  "loop: add r1, #1\njmp lop\n",
  "mov r1, #40000\n",
  "a: halt\na: halt\n",
  "push r1, r2\n",
  "fly r1\n"
]

code = assemble(PRIMES_PROGRAM)
puts "#{code.size} words"
code.each_with_index { |w, i| puts format("%04x  %08x  %s", i, w, disassemble(w)) }
out, steps = simulate(code, 100_000)
puts "output: #{out.join(" ")}"
puts "steps: #{steps}"
BROKEN_PROGRAMS.each do |text|
  assemble(text)
  puts "assembled?"
rescue AsmError => e
  puts "line #{e.line}: #{e.message}"
end
