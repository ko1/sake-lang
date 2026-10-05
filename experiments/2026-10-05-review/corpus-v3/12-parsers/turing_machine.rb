require "set"

class Rule
  attr_reader :write, :move, :next_state

  def initialize(write, move, next_state)
    @write = write
    @move = move
    @next_state = next_state
  end
end

class Machine
  attr_reader :name, :start, :accept, :rules

  def initialize(name, start, accept, rules)
    @name = name
    @start = start
    @accept = accept
    @rules = rules
  end
end

class SpecError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

def parse_machine(name, text)
  rules = {}
  start = nil
  accept = Set.new
  text.lines.each_with_index do |raw, i|
    line = raw.sub(/#.*/, "").strip
    next if line.empty?
    case line
    when /\Astart\s+(\w+)\z/ then start = $1
    when /\Aaccept\s+(.+)\z/ then accept.merge($1.split(" "))
    when /\A(\w+)\s+(\S)\s*->\s*(\w+)\s+(\S)\s+([LRN])\z/
      key = [$1, $2]
      raise SpecError.new("duplicate rule for #{$1}/#{$2}", i + 1) if rules.key?(key)
      rules[key] = Rule.new($4, $5, $3)
    else
      raise SpecError.new("cannot parse '#{line}'", i + 1)
    end
  end
  raise SpecError.new("no start state", 0) if start.nil?
  Machine.new(name, start, accept, rules)
end

def run(machine, input, limit)
  tape = {}
  input.each_char.with_index { |c, i| tape[i] = c }
  head = 0
  state = machine.start
  steps = 0
  while steps < limit
    break if machine.accept.include?(state)
    rule = machine.rules[[state, tape.fetch(head, "_")]]
    break if rule.nil?
    tape[head] = rule.write
    case rule.move
    when "R" then head += 1
    when "L" then head -= 1
    end
    state = rule.next_state
    steps += 1
  end
  cells = tape.keys.select { |k| tape[k] != "_" }
  shown = cells.empty? ? "" : (cells.min..cells.max).map { |k| tape.fetch(k, "_") }.join
  status = if machine.accept.include?(state)
             "accept"
           elsif steps >= limit
             "timeout"
           else
             "halt in #{state}"
           end
  { tape: shown, steps: steps, status: status }
end

INCREMENT_SPEC = <<~TM
  # binary increment: move to the right end, then add one with carry
  start right
  accept done
  right 0 -> right 0 R
  right 1 -> right 1 R
  right _ -> carry _ L
  carry 1 -> carry 0 L
  carry 0 -> done 1 N
  carry _ -> done 1 N
TM

PALINDROME_SPEC = <<~TM
  start s
  accept yes
  s a -> ha _ R
  s b -> hb _ R
  s _ -> yes _ N
  ha a -> ha a R
  ha b -> ha b R
  ha _ -> ca _ L
  hb a -> hb a R
  hb b -> hb b R
  hb _ -> cb _ L
  ca a -> back _ L
  ca _ -> yes _ N
  cb b -> back _ L
  cb _ -> yes _ N
  back a -> back a L
  back b -> back b L
  back _ -> s _ R
TM

BEAVER_SPEC = <<~TM
  start A
  accept H
  A _ -> B 1 R
  A 1 -> C 1 L
  B _ -> A 1 L
  B 1 -> B 1 R
  C _ -> B 1 L
  C 1 -> H 1 N
TM

BROKEN_SPECS = ["start q\nq 1 -> q 1 R\nq 1 -> q 0 L\n", "start q\nq 1 => q 1 R\n", "q 1 -> q 1 R\n"]

jobs = [
  ["increment", INCREMENT_SPEC, ["1011", "111", "0", ""]],
  ["palindrome", PALINDROME_SPEC, ["abba", "aba", "abab", "", "bbbab"]],
  ["beaver3", BEAVER_SPEC, [""]]
]
jobs.each do |name, spec, inputs|
  machine = parse_machine(name, spec)
  puts "#{name}: #{machine.rules.size} rules"
  inputs.each do |input|
    r = run(machine, input, 1000)
    puts format("  %-8s -> %-8s %4d steps  %s", input.inspect, r[:tape], r[:steps], r[:status])
  end
end
BROKEN_SPECS.each do |spec|
  parse_machine("broken", spec)
rescue SpecError => e
  puts "spec error (line #{e.line}): #{e.message}"
end
