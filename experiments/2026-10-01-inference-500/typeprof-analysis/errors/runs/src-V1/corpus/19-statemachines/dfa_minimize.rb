class Dfa
  attr_reader :states, :alphabet, :delta, :start, :accepting

  def initialize(states, alphabet, delta, start, accepting)
    @states = states
    @alphabet = alphabet
    @delta = delta
    @start = start
    @accepting = accepting
  end

  def step(s, c) = @delta[[s, c]]

  def accepts?(word)
    s = @start
    word.each_char { |c| s = step(s, c) }
    @accepting.include?(s)
  end

  def reachable
    seen = Set[@start]
    work = [@start]
    until work.empty?
      s = work.pop
      @alphabet.each do |c|
        t = step(s, c)
        unless seen.include?(t)
          seen << t
          work << t
        end
      end
    end
    @states.select { seen.include?(it) }
  end

  def minimize
    live = reachable
    block_of = {}
    live.each { |s| block_of[s] = @accepting.include?(s) ? 1 : 0 }
    rounds = 0
    loop_again = true
    while loop_again
      rounds += 1
      signatures = {}
      next_block = {}
      live.each do |s|
        sig = @alphabet.map { |c| block_of[step(s, c)].to_s }.join(",")
        key = "#{block_of[s]}|#{sig}"
        signatures[key] = signatures.size unless signatures.key?(key)
        next_block[s] = signatures[key]
      end
      loop_again = signatures.size != block_of.values.uniq.size
      block_of = next_block
    end
    groups = live.group_by { block_of[it] }
    new_delta = {}
    accepting = Set[]
    groups.each do |b, members|
      rep = members.first
      @alphabet.each { |c| new_delta[[b, c]] = block_of[step(rep, c)] }
      accepting << b if @accepting.include?(rep)
    end
    min = Dfa.new(groups.keys.sort, @alphabet, new_delta, block_of[@start], accepting)
    [min, groups, rounds]
  end
end

def words_upto(alphabet, n)
  result = [""]
  frontier = [""]
  n.times do
    frontier = frontier.flat_map { |w| alphabet.map { |c| w + c } }
    result.concat(frontier)
  end
  result
end

def describe(name, d)
  puts "#{name}: #{d.states.size} states, accepting #{d.accepting.to_a.sort}"
end

def check(label, d, words)
  min, groups, rounds = d.minimize
  describe(label, d)
  describe("  minimized", min)
  puts "  refinement rounds: #{rounds}"
  groups.each { |b, members| puts "  block #{b}: #{members.join(" ")}" }
  bad = words.reject { |w| d.accepts?(w) == min.accepts?(w) }
  puts "  checked #{words.size} words, mismatches: #{bad.size}"
  sample = words.select { |w| min.accepts?(w) && w.size > 0 }.take(6)
  puts "  accepted sample: #{sample.join(" ")}"
end

ab = ["a", "b"]
delta1 = {}
[[0, 1, 2], [1, 1, 3], [2, 1, 2], [3, 1, 4], [4, 1, 2], [5, 4, 0]].each do |s, on_a, on_b|
  delta1[[s, "a"]] = on_a
  delta1[[s, "b"]] = on_b
end
ends_abb = Dfa.new([0, 1, 2, 3, 4, 5], ab, delta1, 0, Set[4])
check("ends-with-abb", ends_abb, words_upto(ab, 6))

digits = ["0", "1"]
delta2 = {}
6.times do |s|
  digits.each { |c| delta2[[s, c]] = (s * 2 + c.to_i) % 6 }
end
mod3 = Dfa.new([0, 1, 2, 3, 4, 5], digits, delta2, 0, Set[0, 3])
check("binary-div-by-3 (mod 6 states)", mod3, words_upto(digits, 7))
