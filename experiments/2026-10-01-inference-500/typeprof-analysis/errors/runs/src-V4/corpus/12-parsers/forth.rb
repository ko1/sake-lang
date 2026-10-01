class ForthError < StandardError
  attr_reader :word

  def initialize(message, word)
    super(message)
    @word = word
  end
end

class Forth
  attr_reader :stack, :dict
  attr_accessor :out, :loops

  def initialize
    @stack = []
    @dict = {}
    @out = +""
    @loops = []
  end

  def push(v) = @stack.push(v)

  def pop(word)
    raise ForthError.new("stack underflow", word) if @stack.empty?
    @stack.pop
  end

  def emit(s) = @out << s

  def flag(b) = b ? -1 : 0

  def find_matching(tokens, i, stop_at_else)
    depth = 0
    ((i + 1)...tokens.size).each do |j|
      case tokens[j]
      when "IF" then depth += 1
      when "THEN"
        return j if depth == 0
        depth -= 1
      when "ELSE"
        return j if depth == 0 && stop_at_else
      end
    end
    raise ForthError.new("unbalanced IF", tokens[i])
  end

  def run(tokens)
    i = 0
    while i < tokens.size
      w = tokens[i]
      case w
      when ":"
        semi = tokens.index(";")
        raise ForthError.new("missing ;", w) if !semi    
        @dict[tokens[i + 1].upcase] = tokens[(i + 2)...semi]
        i = semi
      when ".\""
        j = i + 1
        words = []
        while j < tokens.size && !tokens[j].end_with?("\"")
          words << tokens[j]
          j += 1
        end
        raise ForthError.new("unterminated string", w) if j == tokens.size
        words << tokens[j].delete_suffix("\"")
        emit(words.join(" "))
        i = j
      when "IF"
        i = find_matching(tokens, i, true) if pop(w) == 0
      when "ELSE"
        i = find_matching(tokens, i, false)
      when "THEN"
        nil
      when "DO"
        start = pop(w)
        limit = pop(w)
        @loops.push([start, limit, i])
      when "LOOP"
        frame = @loops.last
        raise ForthError.new("LOOP without DO", w) if !frame    
        frame[0] += 1
        if frame[0] < frame[1]
          i = frame[2]
        else
          @loops.pop
        end
      when "I"
        frame = @loops.last
        raise ForthError.new("I outside a loop", w) if !frame    
        push(frame[0])
      when /\A-?\d+\z/
        push(w.to_i)
      else
        word(w.upcase)
      end
      i += 1
    end
  end

  BINARY = %w[+ - * / MOD = < > AND].freeze

  def word(w)
    if (body = @dict[w])
      return run(body)
    end
    case w
    when *BINARY
      b = pop(w)
      a = pop(w)
      push(
        case w
        when "+" then a + b
        when "-" then a - b
        when "*" then a * b
        when "/" then a / b
        when "MOD" then a % b
        when "=" then flag(a == b)
        when "<" then flag(a < b)
        when ">" then flag(a > b)
        when "AND" then a & b
        end
      )
    when "DUP"
      a = pop(w)
      push(a)
      push(a)
    when "DROP" then pop(w)
    when "SWAP"
      b = pop(w)
      a = pop(w)
      push(b)
      push(a)
    when "OVER"
      b = pop(w)
      a = pop(w)
      @stack.push(a, b, a)
    when "." then emit("#{pop(w)} ")
    when "EMIT" then emit(pop(w).chr)
    when "CR" then emit("\n")
    else raise ForthError.new("unknown word", w)
    end
  end
end

SESSION = [
  ": square dup * ;",
  "5 square . 12 square .",
  ": fact dup 1 > IF dup 1 - fact * ELSE drop 1 THEN ;",
  "10 fact . 1 fact .",
  "5 0 DO I . LOOP",
  ": stars 0 DO 42 emit LOOP ;",
  "3 stars cr 6 stars",
  "3 4 < . 4 3 < . 7 7 = .",
  ": fizz 1 + 1 DO I 15 mod 0 = IF .\" FizzBuzz \" ELSE I 3 mod 0 = IF .\" Fizz \" ELSE I 5 mod 0 = IF .\" Buzz \" ELSE I . THEN THEN THEN LOOP ;",
  "15 fizz",
  "2 3 over . . .",
  "1 +",
  "frobnicate",
  "10 0 /",
  ".\" never closed",
  "100 square square ."
]

f = Forth.new
SESSION.each do |line|
  f.out = +""
  f.loops = []
  status = "ok"
  begin
    f.run(line.split(" "))
  rescue ForthError => e
    status = "error: #{e.message} (#{e.word})"
  rescue ZeroDivisionError
    status = "error: division by zero"
  end
  out = f.out.rstrip
  puts "> #{line}"
  out.each_line { |l| puts "  #{l.chomp}" } unless out.empty?
  puts "  #{status}  stack: #{f.stack.join(" ")}"
end
puts "words: #{f.dict.keys.sort.join(" ")}"
