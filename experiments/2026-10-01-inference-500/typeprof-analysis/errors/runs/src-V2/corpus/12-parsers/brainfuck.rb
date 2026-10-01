class BracketError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

def strip_comments(src) = src.chars.select { |c| "+-<>[].,".include?(c) }.join

def jump_table(code)
  jumps = {}
  open = []
  code.each_char.with_index do |c, i|
    if c == "["
      open.push(i)
    elsif c == "]"
      j = open.pop
      raise BracketError.new("unmatched ']'", i) if j.nil?
      jumps[i] = j
      jumps[j] = i
    end
  end
  raise BracketError.new("unmatched '['", open.last) unless open.empty?
  jumps
end

def run(src, input, tape_size)
  code = strip_comments(src)
  jumps = jump_table(code)
  tape = Array.new(tape_size, 0)
  ptr = 0
  pc = 0
  inp = 0
  out = +""
  steps = 0
  while pc < code.size
    case code[pc]
    when "+" then tape[ptr] = (tape[ptr] + 1) % 256
    when "-" then tape[ptr] = (tape[ptr] - 1) % 256
    when ">" then ptr = (ptr + 1) % tape_size
    when "<" then ptr = (ptr - 1) % tape_size
    when "." then out << tape[ptr].chr
    when ","
      ch = input[inp]
      tape[ptr] = ch ? ch.ord : 0
      inp += 1
    when "[" then pc = jumps[pc] if tape[ptr] == 0
    when "]" then pc = jumps[pc] if tape[ptr] != 0
    end
    pc += 1
    steps += 1
  end
  { out: out, steps: steps, cells: tape.count { |v| v != 0 } }
end

PROGRAMS = [
  ["hello", "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.", ""],
  ["add 3+4", ",>,[<+>-]<------------------------------------------------.", "34"],
  ["reverse", ">,[>,]<[.<]", "stressed"],
  ["upcase", ",[--------------------------------.,] read and shift each byte", "sake"],
  ["broken", "+[>+<-]]", ""],
  ["open", "[[]", ""]
]

PROGRAMS.each do |name, src, input|
  r = run(src, input, 64)
  puts format("%-8s %-20s steps=%-5d cells=%d", name, r[:out].chomp.inspect, r[:steps], r[:cells])
rescue BracketError => e
  puts format("%-8s error: %s at %d", name, e.message, e.pos)
end
