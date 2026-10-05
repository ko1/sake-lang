require "set"

def poems
  {
    "sonnet18" => "Shall I compare thee to a summer's day?
Thou art more lovely and more temperate:
Rough winds do shake the darling buds of May,
And summer's lease hath all too short a date:",
    "roses" => "Roses are red,
Violets are blue,
Sugar is sweet,
And so are you.",
    "limerick" => "There once was a man from Peru
Who dreamed he was eating his shoe
He woke with a fright
In the middle of the night
To find that his dream had come true",
    "couplets" => "The cat sat on a mat
It was round and fat
The dog chased a log
Into the fog"
  }
end

def overrides = { "you" => "u", "blue" => "u", "true" => "u", "peru" => "u", "shoe" => "u", "day" => "ay", "may" => "ay" }

def last_word(line)
  w = line.downcase.scan(/[a-z']+/).last
  w ? w.delete("'") : ""
end

def rhyme_key(word)
  special = overrides[word]
  return special if special
  m = word.match(/[aeiouy]+[^aeiouy]*\z/)
  m ? m.to_s : word
end

def scheme(lines)
  letters = {}
  next_letter = "A"
  result = ""
  lines.each do |line|
    key = rhyme_key(last_word(line))
    unless letters.key?(key)
      letters[key] = next_letter
      next_letter = next_letter.succ
    end
    result += letters[key]
  end
  result
end

def classify(s)
  case s
  in "AABBA" then "limerick"
  in "AABB" then "couplets"
  in "ABAB" then "alternate"
  in "ABCB" then "ballad"
  else "free (#{s})"
  end
end

all_endings = {}
poems.each do |name, text|
  lines = text.lines
  s = scheme(lines)
  puts format("%-9s %-6s %s", name, s, classify(s))
  lines.each do |line|
    w = last_word(line)
    (all_endings[rhyme_key(w)] ||= Set[]) << w
  end
end

puts "rhyme families across poems:"
families = all_endings.select { |_, ws| ws.size > 1 }
families.keys.sort.each do |k|
  puts format("  -%-5s %s", k, families[k].sort.join(", "))
end
orphans = all_endings.reject { |_, ws| ws.size > 1 }.values.flat_map(&:to_a).sort
puts "no partner: #{orphans.join(", ")}"

pairs = [["cat", "hat"], ["day", "may"], ["blue", "shoe"], ["fright", "night"], ["red", "sweet"], ["fog", "log"]]
pairs.each do |a, b|
  ok = rhyme_key(a) == rhyme_key(b)
  puts "#{a}/#{b}: #{ok ? "rhyme" : "no"} (#{rhyme_key(a)} vs #{rhyme_key(b)})"
end
