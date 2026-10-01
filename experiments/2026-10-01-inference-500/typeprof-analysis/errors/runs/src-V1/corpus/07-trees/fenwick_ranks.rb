class Fenwick
  attr_reader :size, :tree

  def initialize(n)
    @size = n
    @tree = Array.new(n + 1, 0)
  end

  def add(i, delta)
    i += 1
    while i <= size
      tree[i] += delta
      i += lowbit(i)
    end
  end

  # sum of positions 0..i
  def prefix(i)
    i += 1
    s = 0
    while i > 0
      s += tree[i]
      i -= lowbit(i)
    end
    s
  end

  def range(lo, hi) = lo > hi ? 0 : prefix(hi) - (lo == 0 ? 0 : prefix(lo - 1))

  # smallest index whose prefix sum reaches k (k >= 1)
  def find_kth(k)
    pos = 0
    step = 1
    step *= 2 while step * 2 <= size
    while step > 0
      if pos + step <= size && tree[pos + step] < k
        pos += step
        k -= tree[pos]
      end
      step /= 2
    end
    pos < size ? pos : nil
  end

  private

  def lowbit(i) = i & -i
end

def count_inversions(values)
  sorted = values.sort.uniq
  rank = sorted.each_with_index.to_h
  bit = Fenwick.new(sorted.size)
  inversions = 0
  values.each_with_index do |v, seen|
    r = rank[v]
    inversions += seen - bit.prefix(r)
    bit.add(r, 1)
  end
  inversions
end

def brute_inversions(values)
  values.each_with_index.sum { |a, i| values[(i + 1)..].count { |b| a > b } }
end

puts "-- inversions --"
samples = [[3, 1, 2], [1, 2, 3, 4], [5, 4, 3, 2, 1], [8, 4, 2, 1, 4, 8, 3, 3], []]
samples.each do |s|
  fast = count_inversions(s)
  slow = brute_inversions(s)
  puts "#{s.inspect}: #{fast} #{fast == slow ? "(checked)" : "(MISMATCH #{slow})"}"
end

puts "-- live leaderboard --"
max_score = 100
board = Fenwick.new(max_score + 1)
players = {}
events = [["ann", 40], ["bob", 72], ["cy", 55], ["dee", 72], ["ann", 90], ["eve", 12], ["bob", 30], ["fay", 100]]
events.each do |name, score|
  old = players[name]
  board.add(old, -1) unless old.nil?
  board.add(score, 1)
  players[name] = score
  better = board.range(score + 1, max_score)
  total = players.size
  pct = 100.0 * board.prefix(score) / total
  verb = old.nil? ? "joins" : "moves #{old}->"
  puts format("%-4s %-9s %3d  rank %d of %d  (percentile %.1f)", name, verb, score, better + 1, total, pct)
end

total = players.size
median_pos = board.find_kth((total + 1) / 2)
puts "median score: #{median_pos}"
[1, total, total + 1].each do |k|
  s = board.find_kth(k)
  puts "#{k}-th lowest: #{s.nil? ? "none" : s}"
end
buckets = [[0, 49], [50, 79], [80, 100]].map { |lo, hi| "#{lo}-#{hi}: #{board.range(lo, hi)}" }
puts "buckets: #{buckets.join(", ")}"
