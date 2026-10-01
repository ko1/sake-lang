module Costs
  module_function

  def insert = 1
  def delete = 1
  def substitute(a, b) = a == b ? 0 : 1
end

def distance_table(s, t)
  n = s.size
  m = t.size
  d = Array.new(n + 1) { |i| Array.new(m + 1) { |j| i == 0 ? j : (j == 0 ? i : 0) } }
  1.upto(n) do |i|
    1.upto(m) do |j|
      del = d[i - 1][j] + Costs.delete
      ins = d[i][j - 1] + Costs.insert
      sub = d[i - 1][j - 1] + Costs.substitute(s[i - 1], t[j - 1])
      d[i][j] = [del, ins, sub].min
    end
  end
  d
end

def distance(s, t)
  distance_table(s, t)[s.size][t.size]
end

def script(s, t)
  d = distance_table(s, t)
  i = s.size
  j = t.size
  steps = []
  while i > 0 || j > 0
    if i > 0 && j > 0 && d[i][j] == d[i - 1][j - 1] + Costs.substitute(s[i - 1], t[j - 1])
      steps << (s[i - 1] == t[j - 1] ? "=#{s[i - 1]}" : "#{s[i - 1]}>#{t[j - 1]}")
      i -= 1
      j -= 1
    elsif i > 0 && d[i][j] == d[i - 1][j] + Costs.delete
      steps << "-#{s[i - 1]}"
      i -= 1
    else
      steps << "+#{t[j - 1]}"
      j -= 1
    end
  end
  steps.reverse
end

def suggest(word, dictionary, limit)
  scored = dictionary.map { |w| [distance(word, w), w] }
  close = scored.select { |dist, _| dist <= limit }
  sorted = close.sort_by { |dist, w| dist * 100 + w.size }
  sorted.take(3).map { |dist, w| "#{w}(#{dist})" }
end

pairs = [
  ["kitten", "sitting"],
  ["sunday", "saturday"],
  ["flaw", "lawn"],
  ["intention", "execution"],
  ["", "abc"],
  ["same", "same"]
]
pairs.each do |s, t|
  steps = script(s, t)
  edits = steps.count { |st| !st.start_with?("=") }
  puts format("%-10s -> %-10s distance %d", s, t, distance(s, t))
  puts "  #{steps.join(" ")}"
  puts "  (#{edits} edit operations)"
end

dictionary = %w[receive believe achieve weird seize their there friend separate definitely necessary occasion]
typos = %w[recieve beleive wierd freind seperate definately neccessary ocasion xyzzy]
puts "spelling suggestions:"
typos.each do |typo|
  found = suggest(typo, dictionary, 2)
  if found.empty?
    puts "  #{typo}: no suggestion"
  else
    puts "  #{typo}: #{found.join(", ")}"
  end
end

words = %w[rust ruby rubs tuba cube cubs]
puts "distance matrix:"
puts "      " + words.map { |w| w.ljust(5) }.join
words.each do |a|
  row = words.map { |b| distance(a, b).to_s.ljust(5) }
  puts a.ljust(6) + row.join
end
