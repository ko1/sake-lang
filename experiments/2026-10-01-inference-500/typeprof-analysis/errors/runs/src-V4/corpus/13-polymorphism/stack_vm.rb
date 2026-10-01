class VMError < StandardError
  attr_reader :pc
  def initialize(message, pc)
    super(message)
    @pc = pc
  end
end

class AsmError < StandardError
  attr_reader :line_no
  def initialize(message, line_no)
    super(message)
    @line_no = line_no
  end
end

class VM
  attr_accessor :stack, :vars, :pc, :out, :steps, :halted

  def initialize(stack, vars, pc, out, steps, halted)
    @stack = stack
    @vars = vars
    @pc = pc
    @out = out
    @steps = steps
    @halted = halted
  end

  def self.fresh = VM.new([], {}, 0, [], 0, false)
  def push(x) = @stack.push(x)
  def pop
    raise VMError.new("stack underflow at pc #{@pc}", @pc) if @stack.empty?
    @stack.pop
  end
  def advance = @pc += 1
end

module Instr
  def exec(vm) = raise("exec not implemented")
  def show = "?"
  def to_s = show
end

class Push
  include Instr
  attr_reader :value
  def initialize(value)
    @value = value
  end
  def exec(vm)
    vm.push(@value)
    vm.advance
  end
  def show = "push #{@value}"
end

class BinOp
  include Instr
  attr_reader :op
  def initialize(op)
    @op = op
  end
  def exec(vm)
    b = vm.pop
    a = vm.pop
    r = case @op
        in :add then a + b
        in :sub then a - b
        in :mul then a * b
        in :mod
          raise VMError.new("modulo by zero at pc #{vm.pc}", vm.pc) if b == 0
          a % b
        in :lt then a < b ? 1 : 0
        in :eq then a == b ? 1 : 0
        end
    vm.push(r)
    vm.advance
  end
  def show = @op.to_s
end

class Load
  include Instr
  attr_reader :name
  def initialize(name)
    @name = name
  end
  def exec(vm)
    v = vm.vars[@name]
    raise VMError.new("undefined variable #{@name}", vm.pc) if !v    
    vm.push(v)
    vm.advance
  end
  def show = "load #{@name}"
end

class Store
  include Instr
  attr_reader :name
  def initialize(name)
    @name = name
  end
  def exec(vm)
    vm.vars[@name] = vm.pop
    vm.advance
  end
  def show = "store #{@name}"
end

class Jump
  include Instr
  attr_reader :target, :cond
  def initialize(target, cond)
    @target = target
    @cond = cond
  end
  def exec(vm)
    take = @cond == :always || (@cond == :zero && vm.pop == 0)
    take ? vm.pc = @target : vm.advance
  end
  def show = @cond == :always ? "jmp #{@target}" : "jz #{@target}"
end

class Print
  include Instr
  attr_reader :label
  def initialize(label)
    @label = label
  end
  def exec(vm)
    vm.out << "#{@label}#{vm.pop}"
    vm.advance
  end
  def show = "print"
end

class Halt
  include Instr
  attr_reader :code
  def initialize(code)
    @code = code
  end
  def exec(vm) = vm.halted = true
  def show = "halt"
end

def assemble(source)
  labels = {}
  lines = source.lines.map(&:strip).reject { |l| l.empty? || l.start_with?("#") }
  addr = 0
  lines.each do |l|
    if l.end_with?(":")
      labels[l.delete_suffix(":")] = addr
    else
      addr += 1
    end
  end
  program = []
  lines.reject { |l| l.end_with?(":") }.each_with_index do |l, i|
    op, arg = l.split(" ")
    ins = case op
          in "push" then Push.new(arg.to_i)
          in "add" | "sub" | "mul" | "mod" | "lt" | "eq" then BinOp.new(op.to_sym)
          in "load" then Load.new(arg)
          in "store" then Store.new(arg)
          in "jmp" | "jz"
            target = labels[arg]
            raise AsmError.new("unknown label #{arg}", i) if !target    
            Jump.new(target, op == "jmp" ? :always : :zero)
          in "print" then Print.new(arg ? "#{arg} " : "")
          in "halt" then Halt.new(0)
          else raise AsmError.new("unknown instruction #{op}", i)
          end
    program << ins
  end
  program
end

def run(name, source, limit)
  puts "== #{name} =="
  program = assemble(source)
  vm = VM.fresh
  while !vm.halted && vm.pc < program.size
    raise VMError.new("step limit #{limit} exceeded", vm.pc) if vm.steps >= limit
    program[vm.pc].exec(vm)
    vm.steps += 1
  end
  vm.out.each { |line| puts line }
  puts "(#{program.size} instructions, #{vm.steps} steps, stack #{vm.stack})"
rescue AsmError => e
  puts "assembly error at instruction #{e.line_no}: #{e.message}"
rescue VMError => e
  puts "runtime error at pc #{e.pc}: #{e.message}"
end

factorial = "push 1\nstore acc\npush 10\nstore n\nloop:\nload n\njz done\nload acc\nload n\nmul\nstore acc\nload n\npush 1\nsub\nstore n\njmp loop\ndone:\nload acc\nprint 10!=\nhalt\n"
gcd = "# Euclid\npush 1071\nstore a\npush 462\nstore b\ntop:\nload b\njz end\nload a\nload b\nmod\nload b\nstore a\nstore b\njmp top\nend:\nload a\nprint gcd=\n"
primes = "push 2\nstore n\nnext:\nload n\npush 30\nlt\njz stop\npush 2\nstore d\ntry:\nload d\nload d\nmul\nload n\npush 1\nadd\nlt\njz prime\nload n\nload d\nmod\njz skip\nload d\npush 1\nadd\nstore d\njmp try\nprime:\nload n\nprint\nskip:\nload n\npush 1\nadd\nstore n\njmp next\nstop:\nhalt\n"

run("factorial", factorial, 1000)
run("gcd", gcd, 1000)
run("primes", primes, 5000)
run("underflow", "push 1\nadd\n", 100)
run("bad label", "push 1\njz nowhere\n", 100)
run("bad op", "push 1\nfrobnicate\n", 100)
run("forever", "spin:\njmp spin\n", 50)
run("unset var", "load ghost\nprint\n", 10)

listing = assemble(gcd)
puts "== gcd listing =="
listing.each_with_index { |ins, i| puts format("%3d  %s", i, ins) }
kinds = listing.map(&:to_s).tally
puts "counts: #{kinds.keys.sort.map { |k| "#{k} x#{kinds[k]}" }.join(", ")}"
