def word_list
  "listen silent enlist tinsel inlets google stone tones notes onset seton " +
  "angel glean angle evil vile live veil levi rat tar art star rats tars arts " +
  "night thing apple paple elbow below bowel state taste teats loop pool polo " +
  "dusty study cat act tac dog god heart earth hater"
end

def signature(word) = word.downcase.chars.sort.join

def group_anagrams(words)
  groups = {}
  words.each do |w|
    key = signature(w)
    groups[key] ||= []
    groups[key] << w unless groups[key].include?(w)
  end
  groups
end

def letter_counts(phrase)
  counts = Hash.new(0)
  phrase.downcase.each_char do |c|
    counts[c] += 1 if c.match?(/[a-z]/)
  end
  counts
end

def phrase_anagram?(a, b)
  ca = letter_counts(a)
  cb = letter_counts(b)
  return false if ca.size != cb.size
  ca.all? { |c, n| cb[c] == n }
end

def missing_letters(a, b)
  ca = letter_counts(a)
  cb = letter_counts(b)
  diff = []
  ca.keys.sort.each do |c|
    extra = ca[c] - cb[c]
    diff << "#{c}x#{extra}" if extra > 0
  end
  diff
end

words = word_list.split(" ")
groups = group_anagrams(words)
puts "words: #{words.size}, signatures: #{groups.size}"

multi = groups.select { |_, ws| ws.size > 1 }
ordered = multi.keys.sort_by { |k| k }
ordered.each do |k|
  ws = multi[k]
  puts format("%-6s %d: %s", k, ws.size, ws.sort.join(" "))
end

loners = groups.reject { |_, ws| ws.size > 1 }.values.flat_map { |ws| ws }.sort
puts "no anagram partner: #{loners.join(", ")}"

largest = groups.max_by { |_, ws| ws.size }
if largest
  k, ws = largest
  puts "largest group (#{k}): #{ws.join(", ")}"
end

by_len = Hash.new(0)
multi.each { |k, _| by_len[k.size] += 1 }
by_len.keys.sort.each { |len| puts "groups with #{len} letters: #{by_len[len]}" }

phrases = [
  ["Dormitory", "Dirty room"],
  ["The eyes", "They see"],
  ["Astronomer", "Moon starer"],
  ["Conversation", "Voices rant on"],
  ["Hello world", "Word hollow"]
]
phrases.each do |a, b|
  if phrase_anagram?(a, b)
    puts "#{a} <-> #{b}: anagram"
  else
    puts "#{a} <-> #{b}: no (#{missing_letters(a, b).join(" ")} | #{missing_letters(b, a).join(" ")})"
  end
end
