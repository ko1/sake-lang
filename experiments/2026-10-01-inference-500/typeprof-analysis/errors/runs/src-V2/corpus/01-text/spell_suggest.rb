class Suggestion
  include Comparable
  attr_reader :word, :distance, :frequency

  def initialize(word, distance, frequency)
    @word = word
    @distance = distance
    @frequency = frequency
  end

  def <=>(other)
    [distance, -frequency, word] <=> [other.distance, -other.frequency, other.word]
  end

  def to_s = "#{word}(#{distance})"
end

def dictionary_text
  "the of and to in is it that was for on are with as they be at one have this from " \
  "word but what we all there when your how said each she which their time if will " \
  "write like long make see two has more day go come number no people who first " \
  "receive believe separate definitely occurred language program writing here fine everything"
end

def frequencies
  words = dictionary_text.split(" ")
  words.each_with_index.to_h { |w, i| [w, words.size - i] }
end

def distance(a, b)
  m = a.size
  n = b.size
  prev2 = nil
  prev = (0..n).to_a
  1.upto(m) do |i|
    cur = [i]
    1.upto(n) do |j|
      cost = a[i - 1] == b[j - 1] ? 0 : 1
      best = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].min
      if prev2 && i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]
        best = [best, prev2[j - 2] + 1].min
      end
      cur << best
    end
    prev2 = prev
    prev = cur
  end
  prev[n]
end

def suggest(word, freq, max_dist)
  list = freq.filter_map do |cand, f|
    next if (cand.size - word.size).abs > max_dist
    d = distance(word, cand)
    Suggestion.new(cand, d, f) if d <= max_dist
  end
  list.sort.take(3)
end

def match_case(original, replacement)
  first = original[0]
  first && first == first.upcase && first != first.downcase ? replacement.capitalize : replacement
end

def check(sentence, freq)
  report = []
  corrected = sentence.split(" ").map do |token|
    m = token.match(/\A([A-Za-z]+)(.*)\z/)
    next token unless m
    word = m[1]
    tail = m[2]
    next token if freq.key?(word.downcase)
    options = suggest(word.downcase, freq, 2)
    if options.empty?
      report << "#{word}: no suggestion"
      "[#{word}?]" + tail
    else
      report << "#{word}: " + options.join(", ")
      match_case(word, options.first.word) + tail
    end
  end
  [corrected.join(" "), report]
end

freq = frequencies
puts "dictionary: #{freq.size} words"
pairs = [["kitten", "sitting"], ["recieve", "receive"], ["teh", "the"], ["flaw", "lawn"], ["", "abc"]]
pairs.each { |a, b| puts "distance(#{a.inspect}, #{b.inspect}) = #{distance(a, b)}" }
sentences = [
  "Teh peopel who wrtie definately recieve wierd errors.",
  "Thier frist nubmer was seperate!",
  "Everything here is fine."
]
sentences.each do |s|
  fixed, report = check(s, freq)
  puts
  puts "in:  #{s}"
  puts "out: #{fixed}"
  report.each { |r| puts "     #{r}" }
end
