require "set"

class Node
  attr_accessor :id, :label, :next

  def initialize(id, label, nxt)
    @id = id
    @label = label
    @next = nxt
  end
end

def build(labels, tail_to)
  nodes = labels.each_with_index.map { |l, i| Node.new(i, l, nil) }
  nodes.each_cons(2) { |a, b| a.next = b }
  last = nodes.last
  last.next = nodes[tail_to] if last && tail_to
  nodes.first
end

def floyd(head)
  slow = head
  fast = head
  steps = 0
  while fast && fast.next
    slow = slow.next
    fast = fast.next.next
    steps += 1
    next unless slow.equal?(fast)
    start = head
    meet = slow
    mu = 0
    until start.equal?(meet)
      start = start.next
      meet = meet.next
      mu += 1
    end
    lam = 1
    probe = start.next
    until probe.equal?(start)
      probe = probe.next
      lam += 1
    end
    return { cyclic: true, start: mu, length: lam, steps: steps }
  end
  { cyclic: false, start: -1, length: 0, steps: steps }
end

def brent(head)
  return [0, 0] if head.nil?
  power = 1
  lam = 1
  tortoise = head
  hare = head.next
  while hare && !hare.equal?(tortoise)
    if power == lam
      tortoise = hare
      power *= 2
      lam = 0
    end
    hare = hare.next
    lam += 1
  end
  return [0, 0] if hare.nil?
  tortoise = head
  hare = head
  lam.times { hare = hare.next }
  mu = 0
  until tortoise.equal?(hare)
    tortoise = tortoise.next
    hare = hare.next
    mu += 1
  end
  [mu, lam]
end

def first_repeat_by_set(head)
  seen = Set.new
  node = head
  while node
    return node.label unless seen.add?(node)
    node = node.next
  end
  nil
end

def walk(head, limit)
  out = []
  node = head
  while node && out.size < limit
    out << node.label
    node = node.next
  end
  out.join
end

def break_cycle(head)
  info = floyd(head)
  return false unless info[:cyclic]
  node = head
  (info[:start] + info[:length] - 1).times { node = node.next }
  node.next = nil
  true
end

cases = [
  ["straight", "abcdef", nil],
  ["rho", "abcdefgh", 3],
  ["full loop", "pqrs", 0],
  ["self loop", "xyz", 2],
  ["single", "k", nil],
  ["tiny rho", "mn", 1]
]
cases.each do |name, labels, tail_to|
  head = build(labels.chars, tail_to)
  floyd(head) => { cyclic:, start:, length:, steps: }
  mu, lam = brent(head)
  puts format("%-10s walk=%-14s floyd: cyclic=%-5s start=%2d len=%d steps=%d  brent: %d/%d  repeat=%s",
    name, walk(head, 12), cyclic, start, length, steps, mu, lam, first_repeat_by_set(head).inspect)
  if break_cycle(head)
    puts format("%-10s repaired: %s cyclic=%s", "", walk(head, 20), floyd(head)[:cyclic])
  end
end
