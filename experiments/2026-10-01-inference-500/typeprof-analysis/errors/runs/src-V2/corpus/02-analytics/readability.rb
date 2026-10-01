class Stats
  attr_reader :sentences, :words, :syllables, :complex

  def initialize(sentences, words, syllables, complex)
    @sentences = sentences
    @words = words
    @syllables = syllables
    @complex = complex
  end

  def reading_ease
    wps = @words * 1.0 / @sentences
    spw = @syllables * 1.0 / @words
    206.835 - 1.015 * wps - 84.6 * spw
  end

  def grade
    wps = @words * 1.0 / @sentences
    spw = @syllables * 1.0 / @words
    0.39 * wps + 11.8 * spw - 15.59
  end

  def merge(other)
    Stats.new(@sentences + other.sentences, @words + other.words,
              @syllables + other.syllables, @complex.dup.concat(other.complex))
  end
end

def paragraphs
  [
    "The cat sat on the mat. It was a sunny day. The cat was happy.",
    "Photosynthesis is the biochemical process whereby chlorophyll-containing organisms convert electromagnetic radiation into chemical energy. Consequently, atmospheric carbon dioxide is incorporated into carbohydrates.",
    "We walked to the park after lunch. Some children were playing football, and their parents watched from the benches. Later it started to rain, so everyone went home.",
    "Readability formulas estimate difficulty. They count sentences, words, and syllables! Are they reliable? Only approximately."
  ]
end

def syllables(word, cache)
  cached = cache[word]
  return cached if cached
  w = word.downcase
  w = w.sub(/e$/, "") if w.size > 2 && w.match?(/[^l]e$/)
  n = w.scan(/[aeiouy]+/).size
  n = 1 if n < 1
  cache[word] = n
  n
end

def analyze(text, cache)
  sents = text.split(/[.!?]+/).reject { |s| s.strip.empty? }
  words = text.scan(/[A-Za-z]+(?:-[A-Za-z]+)*/)
  syl = 0
  complex = []
  words.each do |w|
    n = w.split("-").map { |part| syllables(part, cache) }.sum
    syl += n
    complex << w if n >= 3
  end
  Stats.new(sents.size, words.size, syl, complex)
end

def band(score)
  if score >= 80.0
    "easy"
  elsif score >= 60.0
    "standard"
  elsif score >= 30.0
    "difficult"
  else
    "very difficult"
  end
end

cache = {}
total = Stats.new(0, 0, 0, [])
paragraphs.each_with_index do |para, i|
  s = analyze(para, cache)
  total = total.merge(s)
  ease = s.reading_ease
  puts format("P%d: %d sentences, %2d words, %3d syllables, ease %6.1f (%s), grade %5.1f",
              i + 1, s.sentences, s.words, s.syllables, ease, band(ease), s.grade)
  cx = s.complex
  puts "    complex: #{cx.take(5).join(", ")}" unless cx.empty?
end

puts format("overall: ease %.1f, grade %.1f", total.reading_ease, total.grade)
puts "syllable cache: #{cache.size} words"

by_syl = Hash.new(0)
cache.each { |_, n| by_syl[n] += 1 }
by_syl.keys.sort.each { |n| puts format("  %d syllable(s): %2d words", n, by_syl[n]) }

longest = cache.max_by { |w, n| n * 100 + w.size }
if longest
  w, n = longest
  puts "most syllables: #{w} (#{n})"
end
["table", "little", "create", "the", "rhythm", "queue"].each do |w|
  puts "  #{w}: #{syllables(w, cache)}"
end
