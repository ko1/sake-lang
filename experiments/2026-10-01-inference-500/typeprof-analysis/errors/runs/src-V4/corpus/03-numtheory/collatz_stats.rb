# Collatz (3n+1) statistics with a memo table: chain lengths, record holders,
# peak values, and the distribution of lengths.

class Chain
  attr_reader :start, :length, :peak

  def initialize(start, length, peak)
    @start = start
    @length = length
    @peak = peak
  end

  def to_s = "#{@start}: length #{@length}, peak #{@peak}"
end

def next_term(n) = n.even? ? n / 2 : 3 * n + 1

def chain_length(n, memo)
  path = []
  while n != 1 && !memo[n]    
    path << n
    n = next_term(n)
  end
  len = n == 1 ? 1 : memo[n]
  path.reverse_each do |k|
    len += 1
    memo[k] = len
  end
  len
end

def peak(n)
  top = n
  while n != 1
    n = next_term(n)
    top = n if n > top
  end
  top
end

def trajectory(n)
  seq = [n]
  while n != 1
    n = next_term(n)
    seq << n
  end
  seq
end

limit = 1200
memo = { 1 => 1 }
chains = (1..limit).map { |n| Chain.new(n, chain_length(n, memo), peak(n)) }

longest = chains.max_by(&:length)
puts "longest chain below #{limit}: #{longest}"
highest = chains.max_by(&:peak)
puts "highest peak below #{limit}: #{highest}"

puts "length records:"
best = 0
chains.each do |c|
  if c.length > best
    best = c.length
    puts "  #{c}" if c.start > 20
  end
end

puts "trajectory of 27 (first 20): #{trajectory(27).take(20).join(" ")} ..."

buckets = chains.group_by { |c| c.length / 25 }
puts "length distribution:"
buckets.keys.sort.each do |b|
  n = buckets[b].size
  puts format("  %3d-%3d %5d %s", b * 25, b * 25 + 24, n, "#" * ((n + 19) / 20))
end

pairs = chains.each_cons(2).count { |a, b| a.length == b.length }
puts "consecutive starts with equal length: #{pairs}"

pow2 = chains.select { |c| c.peak == c.start && c.start > 1 }
puts "starts that never exceed themselves: #{pow2.size}"
puts "memo entries: #{memo.size}"
avg = (chains.sum(&:length) / limit.to_f).round(3)
puts "average length: #{avg}"
