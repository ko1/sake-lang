require "set"

class Keyword
  include Comparable
  attr_accessor :phrase, :score, :count, :docs

  def initialize(phrase, score, count, docs)
    @phrase = phrase
    @score = score
    @count = count
    @docs = docs
  end

  def <=>(other)
    c = other.score <=> @score
    c == 0 ? @phrase <=> other.phrase : c
  end

  def to_s = format("%-42s %6.2f  x%d", @phrase, @score, @count)
end

class EmptyDocument < StandardError
  attr_reader :name

  def initialize(message, name)
    super(message)
    @name = name
  end
end

def stopwords
  Set["a", "an", "and", "are", "as", "at", "be", "by", "can", "for", "from", "has", "have", "in", "is",
      "it", "its", "of", "on", "or", "over", "such", "that", "the", "their", "these", "this", "to", "using",
      "was", "we", "which", "with", "be", "both", "into", "also", "than", "they", "all", "each", "only"]
end

def documents
  {
    "inference" => "Compatibility of systems of linear constraints over the set of natural numbers. " +
                   "Criteria of compatibility of a system of linear Diophantine equations, strict inequations, " +
                   "and nonstrict inequations are considered. Upper bounds for components of a minimal set of " +
                   "solutions and algorithms of construction of minimal generating sets of solutions for all " +
                   "types of systems are given.",
    "types" => "Type inference reconstructs the types of program expressions without annotations. " +
               "A type inference engine collects constraints over type variables and solves the constraints " +
               "by unification. Minimal annotations can still help the type inference engine report errors.",
    "search" => "Keyword extraction finds the important phrases of a document. Rapid automatic keyword extraction " +
                "scores candidate phrases by word degree and word frequency. Candidate phrases are split at " +
                "stop words and punctuation.",
    "blank" => "   "
  }
end

module Scoring
  module_function

  def degree(freq, deg, w) = deg[w] * 1.0
  def frequency(freq, deg, w) = freq[w] * 1.0
  def ratio(freq, deg, w) = deg[w] * 1.0 / freq[w]

  def score(metric, freq, deg, w)
    case metric
    in :degree then degree(freq, deg, w)
    in :frequency then frequency(freq, deg, w)
    in :ratio then ratio(freq, deg, w)
    end
  end
end

def candidates(text)
  phrases = []
  text.downcase.split(/[.,;:!?()]+/).each do |sentence|
    current = []
    sentence.split(/\s+/).each do |w|
      next if w.empty?
      if stopwords.include?(w)
        phrases << current unless current.empty?
        current = []
      else
        current << w
      end
    end
    phrases << current unless current.empty?
  end
  phrases
end

def word_stats(phrases)
  freq = Hash.new(0)
  deg = Hash.new(0)
  phrases.each do |ph|
    ph.each do |w|
      freq[w] += 1
      deg[w] += ph.size
    end
  end
  [freq, deg]
end

def adjoining(text)
  words = text.downcase.split(/[^a-z]+/).reject(&:empty?)
  found = Hash.new(0)
  words.each_cons(3) do |a, mid, b|
    if stopwords.include?(mid) && !stopwords.include?(a) && !stopwords.include?(b)
      found["#{a} #{mid} #{b}"] += 1
    end
  end
  found.select { |_, n| n >= 2 }
end

def extract(name, text, metric)
  raise EmptyDocument.new("document has no words", name) if text.strip.empty?
  phrases = candidates(text)
  freq, deg = word_stats(phrases)
  keywords = {}
  phrases.each do |ph|
    key = ph.join(" ")
    s = ph.sum { |w| Scoring.score(metric, freq, deg, w) }
    kw = keywords[key]
    if kw
      kw.count += 1
    else
      keywords[key] = Keyword.new(key, s, 1, Set[name])
    end
  end
  adjoining(text).each do |phrase, n|
    parts = phrase.split(" ")
    s = parts.reject { |w| stopwords.include?(w) }.sum { |w| Scoring.score(metric, freq, deg, w) }
    keywords[phrase] = Keyword.new(phrase, s, n, Set[name])
  end
  keywords
end

all = {}
skipped = []
documents.keys.sort.each do |name|
  begin
    kws = extract(name, documents[name], :ratio)
  rescue EmptyDocument => e
    skipped << "#{e.name} (#{e.message})"
    next
  end
  ranked = kws.values.sort
  puts "== #{name}: #{kws.size} candidates =="
  ranked.take(5).each { |k| puts "  #{k}" }
  kws.each do |phrase, k|
    merged = all[phrase]
    if merged
      merged.score += k.score
      merged.count += k.count
      merged.docs << name
    else
      all[phrase] = Keyword.new(phrase, k.score, k.count, Set[name])
    end
  end
end
puts "skipped: #{skipped.join(", ")}" unless skipped.empty?

shared = all.values.select { |k| k.docs.size > 1 }
puts "phrases in several documents: " +
     shared.sort.map { |k| "#{k.phrase} [#{k.docs.sort.join(",")}]" }.join("; ")

repeated = all.values.select { |k| k.count > 1 }.sort
puts "repeated phrases:"
repeated.each { |k| puts "  #{k}" }

puts "metric comparison for 'types':"
[:degree, :frequency, :ratio].each do |metric|
  top = extract("types", documents["types"], metric).values.sort.take(3)
  puts format("  %-9s %s", metric, top.map(&:phrase).join(" | "))
end

phrases = candidates(documents["search"])
freq, deg = word_stats(phrases)
words = freq.keys.sort_by { |w| [-Scoring.ratio(freq, deg, w), w] }
puts "word scores (search): " + words.take(6).map { |w| format("%s=%d/%d", w, deg[w], freq[w]) }.join(" ")
lengths = phrases.map(&:size).tally
puts "candidate lengths: " + lengths.keys.sort.map { |n| "#{n}:#{lengths[n]}" }.join(" ")
