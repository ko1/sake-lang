class Frame
  attr_reader :open, :line, :col

  def initialize(open, line, col)
    @open = open
    @line = line
    @col = col
  end
end

class Problem
  attr_reader :line, :col, :message

  def initialize(line, col, message)
    @line = line
    @col = col
    @message = message
  end

  def to_s = "#{@line}:#{@col}: #{@message}"
end

def closer_for(open)
  case open
  in "(" then ")"
  in "[" then "]"
  in "{" then "}"
  end
end

def check(src)
  stack = []
  problems = []
  state = :code
  quote = ""
  line = 1
  col = 0
  max_depth = 0
  src.each_char do |c|
    col += 1
    case state
    in :code
      if c == "\"" || c == "'"
        state = :string
        quote = c
        stack << Frame.new(c, line, col)
      elsif c == "#"
        state = :comment
      elsif c == "(" || c == "[" || c == "{"
        stack << Frame.new(c, line, col)
        max_depth = stack.size if stack.size > max_depth
      elsif c == ")" || c == "]" || c == "}"
        top = stack.last
        if top.nil?
          problems << Problem.new(line, col, "unexpected #{c}")
        elsif closer_for(top.open) != c
          problems << Problem.new(line, col, "#{c} closes #{top.open} from #{top.line}:#{top.col}")
          stack.pop
        else
          stack.pop
        end
      end
    in :string
      if c == "\\"
        state = :escape
      elsif c == quote
        stack.pop
        state = :code
      elsif c == "\n"
        problems << Problem.new(line, col, "newline in string")
        stack.pop
        state = :code
      end
    in :escape then state = :string
    in :comment then state = :code if c == "\n"
    end
    if c == "\n"
      line += 1
      col = 0
    end
  end
  stack.each { |f| problems << Problem.new(f.line, f.col, "unclosed #{f.open}") }
  [problems, max_depth]
end

samples = [
  ["balanced", "def f(a, b)\n  x = [a, {k: (b + 1)}]\n  puts(\"(not a paren\")\nend\n"],
  ["mismatch", "foo(bar[1)]\nbaz{ qux }\n"],
  ["unclosed", "list = [1, 2, (3\n# comment with ) and ]\nmore = {a: 1\n"],
  ["strings", "s = 'it\\'s' + \"x\\\"(y\"\nt = \"broken\nu = (1)\n"],
  ["extra", "a = (1))\n] }\n"]
]
samples.each do |name, src|
  problems, depth = check(src)
  status = problems.empty? ? "ok" : "#{problems.size} problem(s)"
  puts format("%-9s lines=%d depth=%d %s", name, src.lines.size, depth, status)
  problems.each { |pr| puts "    #{pr}" }
end
