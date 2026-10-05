require "set"

class LogicError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class Reader
  attr_reader :pos

  def initialize(src)
    @src = src
    @pos = 0
  end

  def skip
    @pos += 1 while @src[@pos] == " "
  end

  def peek_is?(s)
    skip
    (@src[@pos..] || "").start_with?(s)
  end

  def take(s)
    return false unless peek_is?(s)
    @pos += s.size
    true
  end

  def equiv
    left = implies
    left = { op: :iff, l: left, r: implies } while take("<->")
    left
  end

  def implies
    left = disj
    return { op: :imp, l: left, r: implies } if take("->")
    left
  end

  def disj
    left = conj
    left = { op: :or, l: left, r: conj } while take("|")
    left
  end

  def conj
    left = unary
    left = { op: :and, l: left, r: unary } while take("&")
    left
  end

  def unary
    return { neg: unary } if take("!")
    if take("(")
      e = equiv
      raise LogicError.new("expected ')'", @pos) unless take(")")
      return e
    end
    skip
    c = @src[@pos]
    raise LogicError.new("expected a variable", @pos) unless c&.match?(/\A[a-z]\z/)
    @pos += 1
    { var: c }
  end
end

def parse(src)
  r = Reader.new(src)
  e = r.equiv
  r.skip
  raise LogicError.new("unexpected input", r.pos) if r.pos < src.size
  e
end

def variables(e, acc = Set.new)
  case e
  in { var: } then acc << var
  in { neg: } then variables(neg, acc)
  in { op:, l:, r: }
    variables(l, acc)
    variables(r, acc)
  end
  acc
end

def holds?(e, env)
  case e
  in { var: } then env[var]
  in { neg: } then !holds?(neg, env)
  in { op:, l:, r: }
    a = holds?(l, env)
    case op
    when :and then a && holds?(r, env)
    when :or then a || holds?(r, env)
    when :imp then !a || holds?(r, env)
    when :iff then a == holds?(r, env)
    end
  end
end

SYMBOLS = { and: "&", or: "|", imp: "->", iff: "<->" }.freeze

def show(e)
  case e
  in { var: } then var
  in { neg: } then "!" + show(neg)
  in { op:, l:, r: } then "(#{show(l)} #{SYMBOLS[op]} #{show(r)})"
  end
end

def rows(vars)
  n = vars.size
  (0...(1 << n)).map do |bits|
    vars.each_with_index.to_h { |v, i| [v, ((bits >> (n - 1 - i)) & 1) == 1] }
  end
end

def bit(b) = b ? "T" : "F"

def analyze(src, print_table)
  e = parse(src)
  vars = variables(e).to_a.sort
  table = rows(vars).map { |env| [env, holds?(e, env)] }
  puts "#{src}  ==>  #{show(e)}"
  if print_table
    puts "  #{vars.join(" ")} | value"
    table.each do |env, value|
      puts "  #{vars.map { |v| bit(env[v]) }.join(" ")} | #{bit(value)}"
    end
  end
  trues = table.count { |_, value| value }
  kind = if trues == table.size
           "tautology"
         elsif trues.zero?
           "contradiction"
         else
           "satisfiable (#{trues}/#{table.size})"
         end
  minterms = table.filter_map do |env, value|
    vars.map { |v| env[v] ? v : "!#{v}" }.join("&") if value
  end
  puts "  #{kind}"
  puts "  dnf: #{minterms.empty? ? "false" : minterms.join(" | ")}" unless trues == table.size
  table
end

def signature(src)
  e = parse(src)
  vars = variables(e).to_a.sort
  rows(vars).map { |env| bit(holds?(e, env)) }.join + "/" + vars.join
end

inputs = [
  ["p -> q", true],
  ["!(p & q) <-> (!p | !q)", true],
  ["p & !p", false],
  ["(p -> q) & (q -> r) -> (p -> r)", false],
  ["a | b & c", false],
  ["p -> q -> p", false],
  ["p -> ", false],
  ["p & (q", false],
  ["p ^ q", false]
]
inputs.each do |src, show_table|
  analyze(src, show_table)
rescue LogicError => e
  puts "#{src}  ==>  error at #{e.pos}: #{e.message}"
end

pairs = [["p -> q", "!q -> !p"], ["p -> q", "q -> p"], ["!(a | b)", "!a & !b"], ["a & (b | c)", "a & b | a & c"]]
pairs.each do |x, y|
  puts "#{x}  #{signature(x) == signature(y) ? "==" : "!="}  #{y}"
end
