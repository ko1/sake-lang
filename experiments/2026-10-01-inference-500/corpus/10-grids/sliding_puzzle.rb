class Node
  include Comparable
  attr_reader :f, :g, :state, :seq

  def initialize(f, g, state, seq)
    @f = f
    @g = g
    @state = state
    @seq = seq
  end

  def <=>(other)
    if @f != other.f
      @f <=> other.f
    else
      other.seq <=> @seq
    end
  end
end

class Heap
  attr_reader :items

  def initialize(items = [])
    @items = items
  end

  def size = @items.size

  def push(x)
    @items << x
    i = @items.size - 1
    while i > 0
      parent = (i - 1) / 2
      break if @items[parent] <= @items[i]
      @items[parent], @items[i] = @items[i], @items[parent]
      i = parent
    end
    self
  end

  def pop
    top = @items.first
    last = @items.pop
    return top if @items.empty?
    @items[0] = last
    i = 0
    n = @items.size
    loop do
      l = 2 * i + 1
      r = l + 1
      m = i
      m = l if l < n && @items[l] < @items[m]
      m = r if r < n && @items[r] < @items[m]
      break if m == i
      @items[m], @items[i] = @items[i], @items[m]
      i = m
    end
    top
  end
end

GOAL = "123456780"

def manhattan(state)
  total = 0
  state.chars.each_with_index do |ch, i|
    next if ch == "0"
    t = ch.to_i - 1
    total += (i / 3 - t / 3).abs + (i % 3 - t % 3).abs
  end
  total
end

def solvable?(state)
  tiles = state.chars.map(&:to_i).reject(&:zero?)
  inversions = 0
  tiles.each_with_index do |a, i|
    tiles.drop(i + 1).each { |b| inversions += 1 if a > b }
  end
  inversions.even?
end

def neighbours(state)
  z = state.index("0")
  return [] unless z
  out = []
  [[-3, "up"], [3, "down"], [-1, "left"], [1, "right"]].each do |delta, name|
    t = z + delta
    next if t < 0 || t > 8
    next if (delta == -1 || delta == 1) && t / 3 != z / 3
    chars = state.chars
    chars[z], chars[t] = chars[t], chars[z]
    out << [chars.join, name]
  end
  out
end

def solve(start)
  return nil unless solvable?(start)
  heap = Heap.new
  seq = 0
  heap.push(Node.new(manhattan(start), 0, start, seq))
  best_g = { start => 0 }
  came = {}
  expanded = 0
  while heap.size > 0
    node = heap.pop
    state = node.state
    g = node.g
    next if g > best_g.fetch(state, g)
    expanded += 1
    if state == GOAL
      moves = []
      cur = state
      while came[cur]
        prev, name = came[cur]
        moves.unshift(name)
        cur = prev
      end
      return { moves: moves, expanded: expanded }
    end
    neighbours(state).each do |nxt, name|
      ng = g + 1
      known = best_g[nxt]
      next if known && known <= ng
      best_g[nxt] = ng
      came[nxt] = [state, name]
      seq += 1
      heap.push(Node.new(ng + manhattan(nxt), ng, nxt, seq))
    end
  end
  nil
end

def show(state) = (0..2).map { |r| state[r * 3, 3].tr("0", ".") }.join(" / ")

["123456780", "123456708", "123405786", "413726580", "023156478", "436718520", "150732684", "724506831", "812043765", "123456870"].each do |start|
  result = solve(start)
  if result
    result => { moves:, expanded: }
    puts "#{show(start)}: #{moves.size} moves, #{expanded} expanded"
    puts "  #{moves.join(" ")}" unless moves.empty?
  else
    puts "#{show(start)}: unsolvable (odd permutation)"
  end
end
