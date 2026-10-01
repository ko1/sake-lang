require "set"

class NState
  attr_accessor :kind, :ch, :out1, :out2

  def initialize(kind, ch)
    @kind = kind
    @ch = ch
    @out1 = nil
    @out2 = nil
  end
end

class Frag
  attr_reader :start, :holes

  def initialize(start, holes)
    @start = start
    @holes = holes
  end
end

class RegexSyntaxError < StandardError
  attr_reader :pattern

  def initialize(message, pattern)
    super(message)
    @pattern = pattern
  end
end

def insert_concat(re)
  out = +""
  chars = re.chars
  chars.each_with_index do |c, i|
    out << c
    nxt = chars[i + 1]
    next if !nxt    
    out << "." if !"(|".include?(c) && !")|*+?".include?(nxt)
  end
  out
end

def prec(op)
  case op
  in "|" then 1
  in "." then 2
  else 0
  end
end

def to_postfix(re)
  output = +""
  ops = []
  insert_concat(re).each_char do |c|
    if c == "("
      ops << c
    elsif c == ")"
      while ops.last != "("
        raise RegexSyntaxError.new("unbalanced )", re) if ops.empty?
        output << ops.pop
      end
      ops.pop
    elsif c == "*" || c == "+" || c == "?"
      output << c
    elsif c == "." || c == "|"
      output << ops.pop while !ops.empty? && prec(ops.last) >= prec(c)
      ops << c
    else
      output << c
    end
  end
  until ops.empty?
    op = ops.pop
    raise RegexSyntaxError.new("unbalanced (", re) if op == "("
    output << op
  end
  output
end

class Nfa
  attr_reader :states, :start

  def initialize(states, start)
    @states = states
    @start = start
  end

  def self.add(states, kind, ch)
    states << NState.new(kind, ch)
    states.size - 1
  end

  def self.patch(states, holes, target)
    holes.each do |id, slot|
      if slot == 1
        states[id].out1 = target
      else
        states[id].out2 = target
      end
    end
  end

  def self.compile(re)
    states = []
    stack = []
    to_postfix(re).each_char do |c|
      case c
      in "."
        e2 = stack.pop
        e1 = stack.pop
        patch(states, e1.holes, e2.start)
        stack << Frag.new(e1.start, e2.holes)
      in "|"
        e2 = stack.pop
        e1 = stack.pop
        s = add(states, :split, nil)
        states[s].out1 = e1.start
        states[s].out2 = e2.start
        stack << Frag.new(s, e1.holes + e2.holes)
      in "*" | "+" | "?"
        e = stack.pop
        raise RegexSyntaxError.new("nothing to repeat", re) if !e    
        s = add(states, :split, nil)
        states[s].out1 = e.start
        if c == "?"
          stack << Frag.new(s, e.holes + [[s, 2]])
        else
          patch(states, e.holes, s)
          start = c == "*" ? s : e.start
          stack << Frag.new(start, [[s, 2]])
        end
      else
        s = add(states, :char, c)
        stack << Frag.new(s, [[s, 1]])
      end
    end
    raise RegexSyntaxError.new("empty or dangling operator", re) if stack.size != 1
    e = stack.pop
    m = add(states, :match, nil)
    patch(states, e.holes, m)
    Nfa.new(states, e.start)
  end

  def closure(set, id)
    return if !id     || set.include?(id)
    set << id
    st = @states[id]
    if st.kind == :split
      closure(set, st.out1)
      closure(set, st.out2)
    end
  end

  def matches?(text)
    current = Set[]
    closure(current, @start)
    text.each_char do |c|
      following = Set[]
      current.each do |id|
        st = @states[id]
        closure(following, st.out1) if st.kind == :char && st.ch == c
      end
      current = following
    end
    current.any? { |id| @states[id].kind == :match }
  end
end

tests = [
  ["ab*c", ["ac", "abbbc", "abd", "a"]],
  ["(a|b)*abb", ["abb", "babb", "aabab", "bbbabb"]],
  ["colou?r", ["color", "colour", "colouur"]],
  ["(ab)+(c|d)?", ["ab", "ababd", "abc", "abcd", ""]],
  ["x(y|z)*", ["x", "xyzzy", "xa"]],
  ["a(b|c", ["ab"]],
  ["*a", ["a"]]
]
tests.each do |re, inputs|
  begin
    nfa = Nfa.compile(re)
    puts "#{re}  postfix=#{to_postfix(re)} states=#{nfa.states.size}"
    inputs.each { |s| puts format("  %-8s %s", s.inspect, nfa.matches?(s) ? "match" : "no") }
  rescue RegexSyntaxError => e
    puts "#{e.pattern}  error: #{e.message}"
  end
end
