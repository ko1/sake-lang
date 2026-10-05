require "set"

class Review
  attr_reader :product, :stars, :text

  def initialize(product, stars, text)
    @product = product
    @stars = stars
    @text = text
  end
end

class Score
  attr_accessor :total, :hits, :words

  def initialize(total, hits, words)
    @total = total
    @hits = hits
    @words = words
  end
end

def lexicon
  {
    "good" => 2, "great" => 3, "excellent" => 4, "love" => 3, "nice" => 2, "fast" => 1,
    "bad" => -2, "terrible" => -4, "slow" => -1, "broken" => -3, "hate" => -3, "poor" => -2,
    "cheap" => -1, "sturdy" => 2, "flimsy" => -2, "happy" => 2, "disappointed" => -3
  }
end

def intensifiers = { "very" => 1.5, "really" => 1.5, "extremely" => 2.0, "slightly" => 0.5 }
def negators = Set["not", "never", "no", "hardly"]

def reviews
  [
    Review.new("kettle", 5, "Great kettle, really fast and very sturdy. Love it!"),
    Review.new("kettle", 2, "Not good. The lid feels flimsy and the switch is slow."),
    Review.new("kettle", 4, "Nice design, slightly slow but not bad at all."),
    Review.new("toaster", 1, "Terrible. Arrived broken and support was no help. Extremely disappointed."),
    Review.new("toaster", 3, "It is fine. Not great, not terrible."),
    Review.new("toaster", 5, "Excellent toast every time, I am very happy."),
    Review.new("blender", 4, "Good blender, never slow, a bit loud."),
    Review.new("blender", 2, "Cheap plastic, hardly sturdy, I hate the noise.")
  ]
end

def tokenize(text) = text.downcase.split(/[^a-z]+/).reject(&:empty?)

def score_text(text)
  score = Score.new(0.0, 0, [])
  negate = false
  boost = 1.0
  tokenize(text).each do |w|
    if negators.include?(w)
      negate = true
      next
    end
    factor = intensifiers[w]
    if factor
      boost = factor
      next
    end
    base = lexicon[w]
    if base
      value = base * boost
      value = -value if negate
      score.total += value
      score.hits += 1
      score.words << (negate ? "not-#{w}" : w)
    end
    negate = false
    boost = 1.0
  end
  score
end

def label(total)
  if total >= 2.0
    "positive"
  elsif total <= -2.0
    "negative"
  else
    "neutral"
  end
end

def expected(stars)
  return "positive" if stars >= 4
  return "negative" if stars <= 2
  "neutral"
end

agree = 0
per_product = {}
confusion = Hash.new(0)
reviews.each do |r|
  s = score_text(r.text)
  total = s.total
  got = label(total)
  want = expected(r.stars)
  agree += 1 if got == want
  confusion[[want, got]] += 1
  (per_product[r.product] ||= []) << total
  puts format("%-8s %d* %6.2f %-8s %s", r.product, r.stars, total, got, s.words.join(" "))
end
puts "agreement with stars: #{agree}/#{reviews.size}"

puts "confusion (expected -> predicted):"
["positive", "neutral", "negative"].each do |want|
  cells = ["positive", "neutral", "negative"].map { |got| format("%3d", confusion[[want, got]]) }
  puts format("  %-9s", want) + cells.join
end

puts "per product mean sentiment:"
ranking = per_product.to_a.sort_by { |_, scores| -scores.sum / scores.size }
ranking.each do |name, scores|
  mean = scores.sum / scores.size
  puts format("  %-8s %6.2f  (min %.2f, max %.2f)", name, mean, scores.min, scores.max)
end

used = Hash.new(0)
reviews.each { |r| tokenize(r.text).each { |w| used[w] += 1 if lexicon.key?(w) } }
unused = lexicon.keys.reject { |w| used.key?(w) }.sort
puts "lexicon words never used: #{unused.join(", ")}"
