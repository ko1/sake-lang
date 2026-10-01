class StackError < StandardError
  attr_reader :needed, :had

  def initialize(message, needed, had)
    super(message)
    @needed = needed
    @had = had
  end
end

class UnknownWord < StandardError
  attr_reader :word

  def initialize(message, word)
    super(message)
    @word = word
  end
end

class Calc
  attr_reader :stack, :regs

  def initialize
    @stack = []
    @regs = {}
  end

  def need(n)
    raise StackError.new("stack underflow", n, @stack.size) if @stack.size < n
  end

  def push(v) = @stack.push(v)

  def pop
    need(1)
    @stack.pop
  end

  def divide(a, b)
    if a.is_a?(Integer) && b.is_a?(Integer)
      return a / b if b != 0 && a % b == 0
      return a.to_f / b
    end
    a / b
  end

  def word(w)
    if (m = w.match(/\A(sto|rcl):([a-z])\z/))
      if m[1] == "sto"
        need(1)
        @regs[m[2]] = @stack.last
      else
        v = @regs[m[2]]
        raise UnknownWord.new("empty register", w) if !v    
        push(v)
      end
    elsif w.match?(/\A-?\d+\z/)
      push(Integer(w))
    elsif w.match?(/\A-?\d+\.\d+\z/)
      push(Float(w))
    elsif %w[+ - * /].include?(w)
      need(2)
      b = pop
      a = pop
      push(w == "/" ? divide(a, b) : a.send(w, b))
    else
      case w
      when "neg" then push(-pop)
      when "sqrt" then push(Math.sqrt(pop))
      when "dup"
        need(1)
        push(@stack.last)
      when "drop" then pop
      when "swap"
        need(2)
        b = pop
        a = pop
        push(b)
        push(a)
      when "over"
        need(2)
        push(@stack[-2])
      when "sum"
        total = @stack.sum
        @stack.clear
        push(total)
      when "clear" then @stack.clear
      else raise UnknownWord.new("unknown word", w)
      end
    end
  end

  def show = "[" + @stack.map(&:to_s).join(" ") + "]"
end

calc = Calc.new
lines = [
  "3 4 + 2 *",
  "dup * sto:a",
  "clear 10 4 /",
  "9 3 / 2.5 *",
  "drop 2 sqrt",
  "1 2 3 4 5 sum",
  "rcl:a swap -",
  "neg 7 over",
  "+ +",
  "drop drop drop",
  "rcl:b",
  "1 0 /",
  "1 2 frob 3",
  "clear 1.5 2 * rcl:a +"
]
lines.each do |line|
  line.split(" ").each { |w| calc.word(w) }
  puts format("%-24s %s", line, calc.show)
rescue StackError => e
  puts format("%-24s %s  error: %s (need %d, have %d)", line, calc.show, e.message, e.needed, e.had)
rescue UnknownWord => e
  puts format("%-24s %s  error: %s '%s'", line, calc.show, e.message, e.word)
rescue ZeroDivisionError
  puts format("%-24s %s  error: divided by 0", line, calc.show)
end
regs = calc.regs
puts "registers: #{regs.keys.sort.map { |k| "#{k}=#{regs[k]}" }.join(", ")}"
