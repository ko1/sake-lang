require "set"

def corpus
  "The quick brown fox jumps over the lazy dog. The dog sleeps! " \
  "Does the fox care? Not at all; the fox simply runs away into the forest, " \
  "where other foxes are waiting. Reading level formulas count syllables, words, and sentences. " \
  "They are crude, but they are surprisingly useful for comparing two drafts of the same text."
end

def stopwords = Set["the", "a", "an", "and", "of", "at", "are", "for", "but", "they", "into", "over", "not", "all"]

def sentences(text)
  text.split(/(?<=[.!?])\s+/).map(&:strip).reject(&:empty?)
end

def words(text) = text.downcase.scan(/[a-z']+/)

def syllables(word)
  w = word.sub(/e\z/, "")
  n = w.scan(/[aeiouy]+/).size
  n < 1 ? 1 : n
end

def flesch(word_count, sentence_count, syllable_count)
  206.835 - 1.015 * (word_count.to_f / sentence_count) - 84.6 * (syllable_count.to_f / word_count)
end

def top_words(ws, n)
  counts = Hash.new(0)
  ws.each { |w| counts[w] += 1 unless stopwords.include?(w) }
  counts.sort_by { |w, c| [-c, w] }.take(n)
end

def histogram(ws)
  by_len = ws.group_by(&:size)
  by_len.keys.sort.each do |len|
    count = by_len[len].size
    puts format("  %2d | %-12s %d", len, "#" * count, count)
  end
end

text = corpus
ss = sentences(text)
ws = words(text)
syl = ws.sum { |w| syllables(w) }
puts "sentences: #{ss.size}"
puts "words:     #{ws.size}"
puts "unique:    #{ws.uniq.size}"
puts "syllables: #{syl}"
puts format("avg word length: %.2f", ws.sum(&:size).to_f / ws.size)
score = flesch(ws.size, ss.size, syl)
level =
  if score >= 80 then "easy"
  elsif score >= 60 then "standard"
  elsif score >= 30 then "difficult"
  else "very difficult"
  end
puts format("flesch reading ease: %.1f (%s)", score, level)

longest = ss.max_by { |s| words(s).size }
puts "longest sentence (#{words(longest).size} words): #{longest}"
kinds = ss.map { |s| s[-1] }.tally
puts "endings: " + kinds.map { |k, v| "#{k} x#{v}" }.join(", ")

puts "top words:"
top_words(ws, 6).each { |w, c| puts "  #{w.ljust(10)} #{c}" }
puts "word lengths:"
histogram(ws)
