class BasicError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

class ForFrame
  attr_reader :var, :limit, :step, :index

  def initialize(var, limit, step, index)
    @var = var
    @limit = limit
    @step = step
    @index = index
  end
end

class Toks
  def initialize(list)
    @list = list
    @pos = 0
  end

  def peek = @list[@pos]

  def take
    tok = @list[@pos]
    @pos += 1
    tok
  end

  def accept(s)
    return false unless peek == s
    @pos += 1
    true
  end

  def done? = @pos >= @list.size
end

class Basic
  attr_reader :out, :partial

  RELOPS = %w[= <> < > <= >=].freeze

  def initialize(text)
    @code = {}
    text.each_line do |raw|
      m = raw.strip.match(/\A(\d+)\s+(.*)\z/)
      next unless m
      @code[m[1].to_i] = m[2]
    end
    @numbers = @code.keys.sort
    @vars = {}
    @pc = 0
    @gosubs = []
    @fors = []
    @out = []
    @partial = +""
    @line = 0
  end

  def error!(msg) = raise(BasicError.new(msg, @line))

  def expect(t, s)
    error!("expected #{s} but got #{t.peek || "end of line"}") unless t.accept(s)
  end

  def relation(t)
    a = sum(t)
    op = t.peek
    return a unless RELOPS.include?(op)
    t.take
    c = sum(t)
    r = case op
        when "=" then a == c
        when "<>" then a != c
        when "<" then a < c
        when ">" then a > c
        when "<=" then a <= c
        when ">=" then a >= c
        end
    r ? 1 : 0
  end

  def sum(t)
    v = product(t)
    loop do
      if t.accept("+")
        v += product(t)
      elsif t.accept("-")
        v -= product(t)
      else
        return v
      end
    end
  end

  def product(t)
    v = atom(t)
    loop do
      if t.accept("*")
        v *= atom(t)
      elsif t.accept("/")
        d = atom(t)
        error!("division by zero") if d == 0
        v /= d
      elsif t.accept("MOD")
        v %= atom(t)
      else
        return v
      end
    end
  end

  def atom(t)
    tok = t.take
    error!("unexpected end of expression") if !tok    
    return -atom(t) if tok == "-"
    if tok == "("
      v = relation(t)
      expect(t, ")")
      return v
    end
    return tok.to_i if tok.match?(/\A\d+\z/)
    error!("bad token #{tok}") unless tok.match?(/\A[A-Z]\z/)
    @vars.fetch(tok, 0)
  end

  def jump(target)
    idx = @numbers.index(target)
    error!("no line #{target}") if !idx    
    @pc = idx
  end

  def variable(t)
    name = t.take
    error!("expected a variable") unless name&.match?(/\A[A-Z]\z/)
    name
  end

  def statement(t)
    case t.peek
    when "REM"
      return
    when "PRINT"
      t.take
      text = +""
      newline = true
      until t.done?
        tok = t.peek
        if tok.start_with?("\"")
          t.take
          text << tok[1...-1]
        else
          text << relation(t).to_s
        end
        newline = true
        if t.accept(";")
          newline = false
        elsif t.accept(",")
          text << " "
          newline = false
        end
      end
      if newline
        @out << @partial + text
        @partial = +""
      else
        @partial << text
      end
    when "IF"
      t.take
      cond = relation(t)
      expect(t, "THEN")
      target = relation(t)
      jump(target) if cond != 0
    when "GOTO"
      t.take
      jump(relation(t))
    when "GOSUB"
      t.take
      @gosubs.push(@pc)
      jump(relation(t))
    when "RETURN"
      t.take
      error!("RETURN without GOSUB") if @gosubs.empty?
      @pc = @gosubs.pop
    when "END"
      t.take
      @pc = @numbers.size
    when "FOR"
      t.take
      name = variable(t)
      expect(t, "=")
      @vars[name] = relation(t)
      expect(t, "TO")
      limit = relation(t)
      step = t.accept("STEP") ? relation(t) : 1
      @fors.push(ForFrame.new(name, limit, step, @pc))
    when "NEXT"
      t.take
      name = variable(t)
      frame = @fors.last
      error!("NEXT without FOR") if !frame     || frame.var != name
      v = @vars[name] += frame.step
      if (frame.step > 0 && v <= frame.limit) || (frame.step < 0 && v >= frame.limit)
        @pc = frame.index
      else
        @fors.pop
      end
    else
      t.accept("LET")
      name = variable(t)
      expect(t, "=")
      @vars[name] = relation(t)
    end
    error!("unexpected #{t.peek}") unless t.done?
  end

  def run(limit)
    steps = 0
    while @pc < @numbers.size
      steps += 1
      error!("step limit reached") if steps > limit
      @line = @numbers[@pc]
      src = @code[@line]
      @pc += 1
      statement(Toks.new(src.scan(/"[^"]*"|\d+|[A-Za-z]+|<>|<=|>=|\S/)))
    end
    steps
  end
end

def run_program(name, text)
  puts "=== #{name}"
  b = Basic.new(text)
  begin
    status = "ok, #{b.run(3000)} statements"
  rescue BasicError => e
    status = "error in line #{e.line}: #{e.message}"
  end
  b.out << b.partial unless b.partial.empty?
  b.out.each { |l| puts l }
  puts "[#{status}]"
end

run_program("primes", <<~BAS)
  10 REM primes below 50
  20 FOR N = 2 TO 50
  30 LET P = 1
  35 LET D = 2
  40 IF D * D > N THEN 90
  50 IF N MOD D = 0 THEN 80
  60 LET D = D + 1
  70 GOTO 40
  80 LET P = 0
  90 IF P = 0 THEN 110
  100 PRINT N; " ";
  110 NEXT N
  120 PRINT
  130 END
BAS

run_program("subroutines", <<~BAS)
  10 LET A = 0
  20 LET B = 1
  30 FOR I = 1 TO 10
  40 GOSUB 100
  50 NEXT I
  60 PRINT "fib(10) = "; A
  70 FOR K = 10 TO 1 STEP -3
  80 PRINT K,
  85 NEXT K
  90 PRINT "done"
  95 END
  100 LET C = A + B
  110 LET A = B
  120 LET B = C
  130 RETURN
BAS

run_program("countdown", "10 X = 3\n20 PRINT \"T-\"; X\n30 X = X - 1\n40 IF X > 0 THEN 20\n50 PRINT \"liftoff \"; (2 + 3) * 4 - 6 / 2\n")
run_program("bad goto", "10 PRINT \"before\"\n20 GOTO 99\n30 PRINT \"after\"\n")
run_program("bad return", "10 RETURN\n")
run_program("div zero", "10 A = 5\n20 PRINT A / (A - 5)\n")
run_program("forever", "10 GOTO 10\n")
