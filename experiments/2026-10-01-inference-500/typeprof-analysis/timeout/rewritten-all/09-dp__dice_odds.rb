class Die
  attr_reader :name, :faces

  def initialize(name, faces)
    @name = name
    @faces = faces
  end

  def self.standard(n) = new("d#{n}", (1..n).to_a)
  def to_s = @name
end

# distribution of the total of several dice, as exact fractions
def distribution(dice)
  dist = { 0 => 1r }
  dice.each do |die|
    share = Rational(1, die.faces.size)
    nxt = Hash.new(0r)
    dist.each do |total, prob|
      die.faces.each { |f| nxt[total + f] += prob * share }
    end
    dist = nxt
  end
  dist
end

def expectation(dist) = dist.sum { |e__0| v, prob = e__0; prob * v }

def at_least(dist, target) = dist.select { |v, _| v >= target }.sum { |e__1| _, prob = e__1; prob }

def show_histogram(dist)
  peak = dist.values.max
  dist.keys.sort.each do |v|
    prob = dist[v]
    bar = "*" * (prob / peak * 30).round
    puts format("  %3d %-8s %6.2f%% %s", v, prob.to_s, prob.to_f * 100, bar)
  end
end

# probability that a pool of d6 dice gets at least `need` successes (5 or 6 each)
def success_odds(pool, need)
  ways = [1r]
  hit = Rational(1, 3)
  pool.times do
    nxt = Array.new(ways.size + 1, 0r)
    ways.each_with_index do |prob, k|
      nxt[k] += prob * (1 - hit)
      nxt[k + 1] += prob * hit
    end
    ways = nxt
  end
  ways.drop(need).sum
end

two_d6 = distribution([Die.standard(6), Die.standard(6)])
puts "2d6:"
show_histogram(two_d6)
puts "  mean #{expectation(two_d6)}"

fudge = [-1, -1, 0, 0, 1, 1]
sets = [
  [Die.standard(6), Die.standard(6), Die.standard(6)],
  [Die.standard(20)],
  [Die.standard(4), Die.standard(8), Die.standard(12)],
  [Die.new("fudge", fudge), Die.new("fudge", fudge), Die.new("fudge", fudge)]
]
sets.each do |dice|
  dist = distribution(dice)
  label = dice.map(&:to_s).join("+")
  mode = dist.max_by { |e__2| _, prob = e__2; prob }
  low, high = dist.keys.minmax
  puts format("%-14s range %d..%d, mean %s, most likely %d (%s)", label, low, high, expectation(dist).to_s, mode[0], mode[1].to_s)
  target = (low + high + 1) / 2 + 2
  odds = at_least(dist, target)
  puts format("  P(total >= %d) = %s ~ %.4f", target, odds.to_s, odds.to_f)
end

puts "dice pool, success on 5 or 6:"
[[3, 1], [3, 2], [6, 2], [6, 4], [10, 5]].each do |pool, need|
  puts format("  %2d dice, need %d: %6.2f%%", pool, need, success_odds(pool, need).to_f * 100)
end
