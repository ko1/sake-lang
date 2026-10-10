require_relative "ref/text"

# Levenshtein
pairs = [["kitten", "sitting"], ["flaw", "lawn"], ["", "abc"], ["abc", ""], ["", ""], ["same", "same"],
         ["gumbo", "gambol"], ["日本語", "日本"], ["Saturday", "Sunday"]]
pairs.each { |a, b| puts "levenshtein(#{a.inspect}, #{b.inspect}) = #{Text::Levenshtein.distance(a, b)}" }
p Text::Levenshtein.distance("kitten", "sitting", 2)
p Text::Levenshtein.distance("kitten", "sitting", 5)
begin
  Text::Levenshtein.distance("a", ["a", 1].fetch(1))
rescue NoMatchingPatternError => e
  puts "error: not a String"
end

# Soundex
names = ["Robert", "Rupert", "Rubin", "Ashcraft", "Ashcroft", "Tymczak", "Pfister", "Honeyman",
         "Lee", "Washington", "O'Hara", "a", "", "123"]
names.each { |n| puts "soundex(#{n.inspect}) = #{Text::Soundex.soundex(n).inspect}" }
p Text::Soundex.soundex("Robert") == Text::Soundex.soundex("Rupert")

# Jaro-Winkler
jw = [["MARTHA", "MARHTA"], ["DWAYNE", "DUANE"], ["DIXON", "DICKSONX"], ["abc", "abc"], ["abc", "xyz"],
      ["", ""], ["a", ""], ["CRATE", "TRACE"], ["dixon", "DIXON"]]
jw.each do |a, b|
  puts "#{a} ~ #{b}: jaro=#{JaroWinkler.jaro_distance(a, b).round(6)} jw=#{JaroWinkler.distance(a, b).round(6)}"
end
p JaroWinkler.distance("dixon", "DIXON", ignore_case: true)
p JaroWinkler.distance("MARTHA", "MARHTA", weight: 0.2)
p JaroWinkler.distance("CRATE", "CRACK", threshold: 0.9)
begin
  JaroWinkler.distance("a", "b", weight: 0.5)
rescue ArgumentError => e
  puts e.message
end

# word wrap
text = "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs."
puts WordWrap.word_wrap(text, line_width: 20)
puts "--"
puts WordWrap.word_wrap(text, line_width: 30, break_sequence: " /\n")
puts "--"
puts WordWrap.word_wrap("short\nlines stay\n\nas they are", line_width: 20)
puts "--"
puts WordWrap.word_wrap("a supercalifragilisticexpialidocious word", line_width: 10)
p WordWrap.word_wrap(text)
begin
  WordWrap.word_wrap(text, line_width: 0)
rescue ArgumentError => e
  puts e.message
end
