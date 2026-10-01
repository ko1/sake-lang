class InvalidAmount < StandardError
  attr_reader :amount

  def initialize(message, amount)
    super(message)
    @amount = amount
  end
end

def check_inputs(coins, amount)
  raise InvalidAmount.new("negative amount", amount) if amount < 0
  raise ArgumentError, "no coins given" if coins.empty?
  coins.each do |c|
    raise ArgumentError, "bad coin #{c}" if c <= 0
  end
end

# fewest coins; nil when the amount cannot be made
def min_coins(coins, amount)
  check_inputs(coins, amount)
  best = [0]
  last = [nil]
  1.upto(amount) do |a|
    best << nil
    last << nil
    coins.each do |c|
      next if c > a
      prev = best[a - c]
      next if !prev    
      cur = best[a]
      if !cur     || prev + 1 < cur
        best[a] = prev + 1
        last[a] = c
      end
    end
  end
  count = best[amount]
  return nil if !count    
  used = []
  a = amount
  while a > 0
    c = last[a]
    used << c
    a -= c
  end
  [count, used.sort]
end

def count_ways(coins, amount)
  check_inputs(coins, amount)
  ways = Array.new(amount + 1, 0)
  ways[0] = 1
  coins.each do |c|
    c.upto(amount) { |a| ways[a] += ways[a - c] }
  end
  ways[amount]
end

def describe(coins, amount)
  result = min_coins(coins, amount)
  ways = count_ways(coins, amount)
  if result
    count, used = result
    parts = used.tally.map { |c, k| "#{k}x#{c}" }
    puts format("%-14s %4d: %2d coins [%s], %d ways", coins.join("/"), amount, count, parts.join(" "), ways)
  else
    puts format("%-14s %4d: impossible, %d ways", coins.join("/"), amount, ways)
  end
end

systems = [
  [1, 5, 10, 25],
  [1, 3, 4],
  [2, 5],
  [7, 11, 13],
  [1, 2, 5, 10, 20, 50]
]
amounts = [6, 23, 63, 3, 100]

systems.each do |coins|
  amounts.each { |amount| describe(coins, amount) }
end

# greedy is not always optimal; find where it fails
def greedy(coins, amount)
  n = 0
  coins.sort.reverse.each do |c|
    n += amount / c
    amount %= c
  end
  amount == 0 ? n : nil
end

[[1, 3, 4], [1, 5, 10, 25], [1, 6, 10]].each do |coins|
  bad = (1..60).find do |a|
    g = greedy(coins, a)
    r = min_coins(coins, a)
    g && r && g > r[0]
  end
  if bad
    puts "#{coins.join(",")}: greedy fails first at #{bad}"
  else
    puts "#{coins.join(",")}: greedy optimal up to 60"
  end
end

[[[1, 2], -5], [[], 4], [[3, 0], 4]].each do |coins, amount|
  begin
    describe(coins, amount)
  rescue InvalidAmount => e
    puts "invalid amount #{e.amount}: #{e.message}"
  rescue ArgumentError => e
    puts "argument error: #{e.message}"
  end
end
