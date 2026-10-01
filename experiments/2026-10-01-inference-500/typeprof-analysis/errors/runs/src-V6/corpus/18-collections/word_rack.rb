# Word games over a small dictionary: anagram classes, letter racks (multisets via tally), scoring.

def dictionary
  ("stone notes onset tones steno alert alter later ratel least slate stale steal tales teals " \
   "rat tar art star rats arts tsar lose sole oles reals earls rales lares seal sale ales " \
   "quiz jazz zest").split(" ")
end

def letter_scores
  scores = Hash.new(1)
  [["dg", 2], ["bcmp", 3], ["fhvwy", 4], ["k", 5], ["jx", 8], ["qz", 10]].each do |letters, pts|
    letters.each_char { |c| scores[c] = pts }
  end
  scores
end

def signature(w) = w.chars.sort.join

def score(w, table) = w.chars.sum { |c| table[c] }

def can_make?(word, rack_counts)
  word.chars.tally.all? { |c, n| rack_counts.fetch(c, 0) >= n }
end

def leftover(rack, word)
  counts = rack.chars.tally
  word.each_char { |c| counts[c] -= 1 }
  counts.flat_map { |c, n| [c] * n }.sort.join
end

words = dictionary
table = letter_scores
puts "dictionary: #{words.size} words, #{words.uniq.size} distinct"

classes = words.group_by { |w| signature(w) }
big = classes.select { |sig, ws| ws.size > 1 }
puts "== Anagram classes =="
big.sort_by { |sig, ws| [-ws.size, sig] }.each do |sig, ws|
  puts format("%-6s %d: %s", sig, ws.size, ws.sort.join(" "))
end
singles = classes.select { |sig, ws| ws.size == 1 }.map { |sig, ws| ws[0] }
puts "no anagram: #{singles.sort.join(" ")}"

puts "== Racks =="
["aelrst", "otsen", "zzaj", "qixx"].each do |rack|
  counts = rack.chars.tally
  playable = words.select { |w| can_make?(w, counts) }.uniq
  if playable.empty?
    puts "#{rack}: nothing playable"
    next
  end
  best = playable.max_by { |w| [score(w, table), w.size] }
  full = playable.select { |w| w.size == rack.size }
  puts "#{rack}: #{playable.size} words, best #{best} (#{score(best, table)}), leaves '#{leftover(rack, best)}'"
  puts "  uses every tile: #{full.sort.join(" ")}" unless full.empty?
end

puts "== Letters =="
used = words.reduce(Set[]) { |acc, w| acc.merge(w.chars) }
alphabet = ("a".."z").to_set
puts "unused letters: #{(alphabet - used).sort.join}"
common = words.select { |w| w.size == 5 }.map { |w| w.chars.to_set }.reduce(alphabet) { |acc, s| acc & s }
puts "in every 5-letter word: #{common.sort.join}"
by_len = words.map(&:size).tally
puts "lengths: #{by_len.keys.sort.map { |l| "#{l}x#{by_len[l]}" }.join(" ")}"
top = words.uniq.sort_by { |w| [-score(w, table), w] }.take(3)
puts "highest scoring: #{top.map { |w| "#{w}=#{score(w, table)}" }.join(" ")}"
doubles = words.select { |w| w.chars.uniq.size < w.size }
puts "repeated letters: #{doubles.join(" ")}"
