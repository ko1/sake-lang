require "set"

def corpus
  "It was the best of times, it was the worst of times, it was the age of wisdom, " +
  "it was the age of foolishness, it was the epoch of belief, it was the epoch of " +
  "incredulity, it was the season of Light, it was the season of Darkness, it was " +
  "the spring of hope, it was the winter of despair, we had everything before us, " +
  "we had nothing before us, we were all going direct to Heaven, we were all going " +
  "direct the other way. In short, the period was so far like the present period, " +
  "that some of its noisiest authorities insisted on its being received, for good " +
  "or for evil, in the superlative degree of comparison only."
end

def stopwords
  Set["the", "of", "it", "was", "we", "a", "an", "and", "in", "to", "on", "for", "or", "so", "that", "its", "us", "all", "had", "were"]
end

def tokenize(text)
  text.downcase.split(/[^a-z']+/).reject(&:empty?)
end

class Rank
  include Comparable
  attr_reader :word, :count

  def initialize(word, count)
    @word = word
    @count = count
  end

  def <=>(other)
    c = other.count <=> @count
    c == 0 ? @word <=> other.word : c
  end

  def to_s = format("%-14s %3d", @word, @count)
end

def count_words(words, stop)
  counts = Hash.new(0)
  words.each do |w|
    next if stop.include?(w)
    counts[w] += 1
  end
  counts
end

def top_n(counts, n)
  counts.map { |w, c| Rank.new(w, c) }.sort.take(n)
end

def length_histogram(words)
  hist = Hash.new(0)
  words.each { |w| hist[w.size] += 1 }
  hist
end

def bar(n) = "#" * n

words = tokenize(corpus)
puts "tokens: #{words.size}"
puts "distinct: #{words.uniq.size}"

counts = count_words(words, stopwords)
puts "content words: #{counts.size}"
puts "-- top 10 --"
top_n(counts, 10).each_with_index do |r, i|
  puts "#{(i + 1).to_s.rjust(2)}. #{r}"
end

puts "-- word lengths --"
hist = length_histogram(words)
hist.keys.sort.each do |len|
  puts format("%2d %-20s %d", len, bar(hist[len]), hist[len])
end

longest = counts.keys.max_by(&:size)
puts "longest content word: #{longest}"
singles = counts.select { |w, c| c == 1 }.keys.sort
puts "hapax (#{singles.size}): #{singles.take(8).join(", ")} ..."
share = (100.0 * singles.size / counts.size).round(1)
puts "hapax share: #{share}%"
