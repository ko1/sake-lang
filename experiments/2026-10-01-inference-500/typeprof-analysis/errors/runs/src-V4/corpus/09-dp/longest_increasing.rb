class Envelope
  attr_reader :label, :w, :h

  def initialize(label, w, h)
    @label = label
    @w = w
    @h = h
  end
end

# O(n^2) version: lengths and predecessors
def lis_quadratic(xs)
  n = xs.size
  return [] if n == 0
  len = Array.new(n, 1)
  prev = Array.new(n)
  n.times do |i|
    i.times do |j|
      if xs[j] < xs[i] && len[j] + 1 > len[i]
        len[i] = len[j] + 1
        prev[i] = j
      end
    end
  end
  k = len.index(len.max)
  out = []
  while k
    out.unshift(xs[k])
    k = prev[k]
  end
  out
end

# patience sorting: tails[i] = index of smallest tail of an increasing run of length i+1
def lower_bound(xs, tails, x)
  lo = 0
  hi = tails.size
  while lo < hi
    mid = (lo + hi) / 2
    if xs[tails[mid]] < x
      lo = mid + 1
    else
      hi = mid
    end
  end
  lo
end

def lis_fast(xs)
  tails = []
  parent = []
  xs.each_with_index do |x, i|
    pos = lower_bound(xs, tails, x)
    parent << (pos > 0 ? tails[pos - 1] : nil)
    if pos == tails.size
      tails << i
    else
      tails[pos] = i
    end
  end
  out = []
  k = tails.last
  while k
    out.unshift(xs[k])
    k = parent[k]
  end
  out
end

def nested_envelopes(envs)
  # sort by width ascending and height descending, so equal widths cannot nest
  sorted = envs.sort_by { |e| [e.w, -e.h] }
  chain = lis_fast(sorted.map(&:h))
  picked = []
  idx = 0
  sorted.each do |e|
    if idx < chain.size && e.h == chain[idx]
      if picked.empty? || picked.last.w < e.w
        picked << e
        idx += 1
      end
    end
  end
  picked
end

sequences = [
  [10, 9, 2, 5, 3, 7, 101, 18],
  [0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15],
  [5, 4, 3, 2, 1],
  [1, 2, 3, 4],
  [3, 10, 2, 1, 20, 4, 6, 7, 30, 5],
  []
]
sequences.each do |xs|
  slow = lis_quadratic(xs)
  fast = lis_fast(xs)
  agree = slow.size == fast.size ? "agree" : "DISAGREE"
  puts "#{xs}"
  puts "  n^2:     #{slow} (#{slow.size})"
  puts "  n log n: #{fast} (#{fast.size}) #{agree}"
end

prices = [31, 29, 33, 35, 30, 28, 36, 40, 37, 41, 39, 44, 42, 38, 45]
run = lis_fast(prices)
puts "longest rising run of prices: #{run.join(" < ")}"
days = run.map { |v| prices.index(v) + 1 }
puts "on days #{days.join(", ")}"

envs = [
  Envelope.new("A", 5, 4), Envelope.new("B", 6, 4), Envelope.new("C", 6, 7),
  Envelope.new("D", 2, 3), Envelope.new("E", 8, 9), Envelope.new("F", 7, 8),
  Envelope.new("G", 3, 2), Envelope.new("H", 9, 10)
]
nest = nested_envelopes(envs)
labels = nest.map { |e| "#{e.label}(#{e.w}x#{e.h})" }
puts "envelopes nest #{nest.size} deep: #{labels.join(" in ")}"
