class SoldOut < StandardError
  attr_reader :day, :available

  def initialize(message, day, available)
    super(message)
    @day = day
    @available = available
  end
end

class LazyTree
  attr_reader :n, :mins, :sums, :pending

  def initialize(values)
    @n = values.size
    @mins = Array.new(4 * n, 0)
    @sums = Array.new(4 * n, 0)
    @pending = Array.new(4 * n, 0)
    init(values, 1, 0, n - 1)
  end

  def add(from, to, delta) = add_rec(1, 0, n - 1, from, to, delta)
  def min(from, to) = min_rec(1, 0, n - 1, from, to)
  def sum(from, to) = sum_rec(1, 0, n - 1, from, to)

  # first day in from..to whose availability is below need
  def first_short(from, to, need)
    (from..to).find { |d| min(d, d) < need }
  end

  private

  def init(values, node, lo, hi)
    if lo == hi
      mins[node] = sums[node] = values[lo]
      return
    end
    mid = (lo + hi) / 2
    init(values, node * 2, lo, mid)
    init(values, node * 2 + 1, mid + 1, hi)
    pull(node)
  end

  def pull(node)
    a = node * 2
    b = a + 1
    mins[node] = [mins[a], mins[b]].min
    sums[node] = sums[a] + sums[b]
  end

  def apply(node, lo, hi, delta)
    mins[node] += delta
    sums[node] += delta * (hi - lo + 1)
    pending[node] += delta
  end

  def push_down(node, lo, hi)
    d = pending[node]
    return if d == 0
    mid = (lo + hi) / 2
    apply(node * 2, lo, mid, d)
    apply(node * 2 + 1, mid + 1, hi, d)
    pending[node] = 0
  end

  def add_rec(node, lo, hi, from, to, delta)
    return if to < lo || hi < from
    if from <= lo && hi <= to
      apply(node, lo, hi, delta)
      return
    end
    push_down(node, lo, hi)
    mid = (lo + hi) / 2
    add_rec(node * 2, lo, mid, from, to, delta)
    add_rec(node * 2 + 1, mid + 1, hi, from, to, delta)
    pull(node)
  end

  def min_rec(node, lo, hi, from, to)
    return nil if to < lo || hi < from
    return mins[node] if from <= lo && hi <= to
    push_down(node, lo, hi)
    mid = (lo + hi) / 2
    [min_rec(node * 2, lo, mid, from, to), min_rec(node * 2 + 1, mid + 1, hi, from, to)].compact.min
  end

  def sum_rec(node, lo, hi, from, to)
    return 0 if to < lo || hi < from
    return sums[node] if from <= lo && hi <= to
    push_down(node, lo, hi)
    mid = (lo + hi) / 2
    sum_rec(node * 2, lo, mid, from, to) + sum_rec(node * 2 + 1, mid + 1, hi, from, to)
  end
end

class Train
  attr_reader :name, :seats, :tree

  def initialize(name, days, seats)
    @name = name
    @seats = seats
    @tree = LazyTree.new(Array.new(days, seats))
  end

  def reserve(from, to, count)
    avail = tree.min(from, to)
    if avail < count
      day = tree.first_short(from, to, count)
      raise SoldOut.new("#{name}: only #{avail} seats on day #{day}", day, avail)
    end
    tree.add(from, to, -count)
  end

  def cancel(from, to, count) = tree.add(from, to, count)

  def occupancy(from, to)
    days = to - from + 1
    sold = seats * days - tree.sum(from, to)
    100.0 * sold / (seats * days)
  end
end

train = Train.new("Night Express", 14, 40)
requests = [
  [:reserve, 0, 6, 12], [:reserve, 3, 9, 20], [:reserve, 5, 5, 8], [:reserve, 4, 8, 5],
  [:reserve, 2, 4, 10], [:cancel, 3, 9, 20], [:reserve, 2, 4, 10], [:reserve, 10, 13, 40],
  [:reserve, 12, 13, 1], [:reserve, 0, 13, 3]
]
requests.each do |kind, from, to, count|
  if kind == :reserve
    train.reserve(from, to, count)
  else
    train.cancel(from, to, count)
  end
  puts format("%-7s days %2d-%2d x%2d  ok", kind.to_s, from, to, count)
rescue SoldOut => e
  puts format("%-7s days %2d-%2d x%2d  REFUSED: %s", kind.to_s, from, to, count, e.message)
end

tree = train.tree
row = (0...14).map { |d| tree.min(d, d).to_s.rjust(3) }
puts "free seats:#{row.join}"
puts format("week 1 occupancy: %.1f%%, week 2: %.1f%%", train.occupancy(0, 6), train.occupancy(7, 13))
puts "tightest day in week 1 has #{tree.min(0, 6)} seats"
puts "seats sold over the fortnight: #{40 * 14 - tree.sum(0, 13)}"
