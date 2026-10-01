class Dfa
  attr_reader :name, :start, :delta, :accept

  def initialize(name, start, delta, accept)
    @name = name
    @start = start
    @delta = delta
    @accept = accept
  end

  def self.divisible_by(n, base)
    delta = {}
    digits = (0...base).map { |d| d.to_s(base) }
    n.times do |r|
      digits.each_with_index { |ch, d| delta[[r, ch]] = (r * base + d) % n }
    end
    Dfa.new("div#{n}/b#{base}", 0, delta, Set[0])
  end

  def run(word)
    s = @start
    word.each_char do |c|
      s = @delta[[s, c]]
      return false if s.nil?
    end
    @accept.include?(s)
  end

  def states = @delta.keys.map { |s, c| s }.uniq

  def self.product(a, b, mode, name)
    delta = {}
    accept = Set[]
    start = [a.start, b.start]
    work = [start]
    seen = Set[start]
    alphabet = a.delta.keys.map { |s, c| c }.uniq
    until work.empty?
      pair = work.pop
      sa, sb = pair
      in_a = a.accept.include?(sa)
      in_b = b.accept.include?(sb)
      ok = case mode
           in :and then in_a && in_b
           in :or then in_a || in_b
           in :and_not then in_a && !in_b
           end
      accept << pair if ok
      alphabet.each do |c|
        ta = a.delta[[sa, c]]
        tb = b.delta[[sb, c]]
        next if ta.nil? || tb.nil?
        target = [ta, tb]
        delta[[pair, c]] = target
        unless seen.include?(target)
          seen << target
          work << target
        end
      end
    end
    Dfa.new(name, start, delta, accept)
  end
end

def check(dfa, numbers, base)
  wrong = 0
  hits = []
  numbers.each do |n|
    got = dfa.run(n.to_s(base))
    want = yield(n)
    wrong += 1 if got != want
    hits << n if got
  end
  puts format("%-22s states=%2d accepted=%3d wrong=%d first: %s", dfa.name, dfa.states.size,
    hits.size, wrong, hits.take(8).join(","))
end

nums = (1..150).to_a
div3 = Dfa.divisible_by(3, 2)
div4 = Dfa.divisible_by(4, 2)
div7 = Dfa.divisible_by(7, 10)
div5 = Dfa.divisible_by(5, 10)
check(div3, nums, 2) { |n| n % 3 == 0 }
check(div4, nums, 2) { |n| n % 4 == 0 }
check(div7, nums, 10) { |n| n % 7 == 0 }
check(Dfa.product(div3, div4, :and, "div3 and div4"), nums, 2) { |n| n % 12 == 0 }
check(Dfa.product(div3, div4, :and_not, "div3 but not div4"), nums, 2) { |n| n % 3 == 0 && n % 4 != 0 }
check(Dfa.product(div7, div5, :or, "div7 or div5"), nums, 10) { |n| n % 7 == 0 || n % 5 == 0 }
check(Dfa.divisible_by(6, 16), nums, 16) { |n| n % 6 == 0 }
p div7.run("12a")
