class SegTree
  attr_reader :n, :sums, :mins, :maxs

  def initialize(values)
    @n = values.size
    @sums = Array.new(4 * n, 0)
    @mins = Array.new(4 * n, 0)
    @maxs = Array.new(4 * n, 0)
    build(values, 1, 0, n - 1)
  end

  def update(idx, value) = update_rec(1, 0, n - 1, idx, value)

  def query(from, to)
    raise ArgumentError, "bad range #{from}..#{to}" if from > to || from < 0 || to >= n
    query_rec(1, 0, n - 1, from, to)
  end

  private

  def build(values, node, lo, hi)
    if lo == hi
      sums[node] = mins[node] = maxs[node] = values[lo]
      return
    end
    mid = (lo + hi) / 2
    build(values, 2 * node, lo, mid)
    build(values, 2 * node + 1, mid + 1, hi)
    pull(node)
  end

  def pull(node)
    l = 2 * node
    r = l + 1
    sums[node] = sums[l] + sums[r]
    mins[node] = [mins[l], mins[r]].min
    maxs[node] = [maxs[l], maxs[r]].max
  end

  def update_rec(node, lo, hi, idx, value)
    if lo == hi
      sums[node] = mins[node] = maxs[node] = value
      return
    end
    mid = (lo + hi) / 2
    if idx <= mid
      update_rec(2 * node, lo, mid, idx, value)
    else
      update_rec(2 * node + 1, mid + 1, hi, idx, value)
    end
    pull(node)
  end

  def query_rec(node, lo, hi, from, to)
    return { sum: sums[node], min: mins[node], max: maxs[node] } if from <= lo && hi <= to
    mid = (lo + hi) / 2
    return query_rec(2 * node, lo, mid, from, to) if to <= mid
    return query_rec(2 * node + 1, mid + 1, hi, from, to) if from > mid
    a = query_rec(2 * node, lo, mid, from, to)
    b = query_rec(2 * node + 1, mid + 1, hi, from, to)
    { sum: a[:sum] + b[:sum], min: [a[:min], b[:min]].min, max: [a[:max], b[:max]].max }
  end
end

DAYS = %w[Mon Tue Wed Thu Fri Sat Sun].freeze

def day_name(i) = DAYS[i % 7]

def report(tree, label, from, to)
  r = tree.query(from, to)
  days = to - from + 1
  puts format("%-14s days %2d-%2d (%s..%s): total %5d  avg %7.2f  min %4d  max %4d",
              label, from, to, day_name(from), day_name(to), r[:sum], r[:sum] / days.to_f, r[:min], r[:max])
end

sales = [120, 95, 143, 80, 210, 305, 288, 101, 99, 150, 77, 230, 310, 295,
         130, 90, 160, 85, 220, 330, 301, 118, 104, 149, 92, 240, 299, 280]
tree = SegTree.new(sales)
report(tree, "all", 0, sales.size - 1)
4.times { |w| report(tree, "week #{w + 1}", w * 7, w * 7 + 6) }
report(tree, "weekend 1", 5, 6)
report(tree, "single day", 10, 10)

puts "-- corrections --"
corrections = [[3, 180], [10, 0], [27, 500]]
corrections.each do |day, amount|
  old = sales[day]
  sales[day] = amount
  tree.update(day, amount)
  puts "day #{day}: #{old} -> #{amount}"
end
report(tree, "all", 0, sales.size - 1)
report(tree, "week 2", 7, 13)
report(tree, "week 4", 21, 27)

best_start, best_total = (0..(sales.size - 7)).map { |s| [s, tree.query(s, s + 6)[:sum]] }
                                              .reduce([0, 0]) { |best, cur| cur[1] > best[1] ? cur : best }
puts "best 7-day window starts day #{best_start} (#{day_name(best_start)}): #{best_total}"

[[5, 2], [0, 40]].each do |from, to|
  tree.query(from, to)
rescue ArgumentError => e
  puts "error: #{e.message}"
end
