# Design-by-contract helpers shared through a mixin: preconditions, postconditions and invariants on two types.
class ContractViolation < StandardError
  attr_reader :kind, :subject

  def initialize(message, kind, subject)
    super(message)
    @kind = kind
    @subject = subject
  end
end

module Contract
  def require!(cond, what)
    raise ContractViolation.new("precondition failed: #{what}", :pre, describe) unless cond
  end

  def ensure!(cond, what)
    raise ContractViolation.new("postcondition failed: #{what}", :post, describe) unless cond
  end

  def check_invariant!
    problem = invariant_problem
    raise ContractViolation.new("invariant broken: #{problem}", :invariant, describe) if problem
    self
  end
end

class Stack
  include Contract
  attr_reader :capacity, :items

  def initialize(capacity, items)
    @capacity = capacity
    @items = items
  end

  def describe = "Stack(#{@items.size}/#{@capacity})"
  def invariant_problem = @items.size > @capacity ? "size exceeds capacity" : nil

  def push(v)
    require!(@items.size < @capacity, "stack not full")
    before = @items.size
    @items.push(v)
    ensure!(@items.size == before + 1, "size grew by one")
    check_invariant!
  end

  def pop
    require!(!@items.empty?, "stack not empty")
    v = @items.pop
    check_invariant!
    v
  end
end

class Range2
  include Contract
  attr_accessor :lo, :hi

  def initialize(lo, hi)
    @lo = lo
    @hi = hi
  end

  def describe = "Range2(#{@lo}, #{@hi})"
  def invariant_problem = @lo > @hi ? "lo > hi" : nil

  def shift(d)
    require!(d != 0, "non-zero shift")
    @lo += d
    @hi += d
    check_invariant!
  end

  def set_bounds(lo, hi)
    @lo = lo
    @hi = hi
    check_invariant!
  end

  def width
    w = @hi - @lo
    ensure!(w >= 0, "width is non-negative")
    w
  end
end

def attempt(log, label)
  yield
  log << [label, "ok", ""]
rescue ContractViolation => e
  log << [label, e.kind.to_s, "#{e.message} on #{e.subject}"]
end

s = Stack.new(2, [])
r = Range2.new(1, 5)
log = []
attempt(log, "push 10") { s.push(10) }
attempt(log, "push 20") { s.push(20) }
attempt(log, "push 30") { s.push(30) }
attempt(log, "pop") { s.pop }
attempt(log, "pop") { s.pop }
attempt(log, "pop") { s.pop }
s.items.push(1, 2, 3)
attempt(log, "check stack") { s.check_invariant! }
attempt(log, "shift 3") { r.shift(3) }
attempt(log, "shift 0") { r.shift(0) }
attempt(log, "bounds 9..2") { r.set_bounds(9, 2) }
attempt(log, "width") { r.width }
attempt(log, "bounds 0..4") { r.set_bounds(0, 4) }
attempt(log, "check range") { r.check_invariant! }

log.each { |label, status, detail| puts format("%-12s %-9s %s", label, status, detail) }
counts = log.map { |_, status, _| status }.tally
puts counts.keys.sort.map { |k| "#{k}=#{counts[k]}" }.join(" ")
