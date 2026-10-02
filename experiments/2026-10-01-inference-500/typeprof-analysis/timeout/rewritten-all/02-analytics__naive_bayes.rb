require "set"

class Model
  attr_reader :class_docs, :word_counts, :totals, :vocab

  def initialize(class_docs, word_counts, totals, vocab)
    @class_docs = class_docs
    @word_counts = word_counts
    @totals = totals
    @vocab = vocab
  end

  def self.train(examples)
    m = Model.new(Hash.new(0), {}, Hash.new(0), Set[])
    examples.each do |label, text|
      m.class_docs[label] += 1
      counts = m.word_counts[label] ||= Hash.new(0)
      words(text).each do |w|
        counts[w] += 1
        m.totals[label] += 1
        m.vocab << w
      end
    end
    m
  end

  def log_prob(label, w)
    v = @vocab.size
    Math.log((@word_counts[label][w] + 1.0) / (@totals[label] + v))
  end

  def scores(text)
    n_docs = @class_docs.values.sum
    result = {}
    @class_docs.each do |label, docs|
      s = Math.log(docs * 1.0 / n_docs)
      words(text).each do |w|
        s += log_prob(label, w) if @vocab.include?(w)
      end
      result[label] = s
    end
    result
  end

  def classify(text)
    best = scores(text).max_by { |e__0| _, s = e__0; s }
    return nil unless best
    label, _ = best
    label
  end

  def indicative(label, k)
    others = @class_docs.keys.reject { |l| l == label }
    ratios = @vocab.map do |w|
      mine = log_prob(label, w)
      rest = others.map { |o| log_prob(o, w) }.max
      [w, mine - rest]
    end
    ranked = ratios.sort_by { |e__1| w, r = e__1; [-r, w] }
    ranked.take(k).map { |e__2| w, _ = e__2; w }
  end
end

def training
  [
    [:sports, "the team won the match with a late goal"],
    [:sports, "the striker scored twice and the fans cheered"],
    [:sports, "a tense final set decided the tennis match"],
    [:sports, "the coach praised the defence after the win"],
    [:tech, "the new phone has a faster chip and better battery"],
    [:tech, "developers released a patch for the security bug"],
    [:tech, "the laptop battery lasts all day with the new chip"],
    [:tech, "the app update fixes a crash on startup"],
    [:food, "slow roast the lamb with garlic and rosemary"],
    [:food, "the chef added fresh basil to the tomato sauce"],
    [:food, "bake the bread until the crust is golden"],
    [:food, "a pinch of salt makes the sauce better"]
  ]
end

def tests
  [
    [:sports, "the fans cheered the late winner in the final"],
    [:tech, "a security patch for the phone app"],
    [:food, "garlic bread with fresh tomato"],
    [:tech, "the battery update"],
    [:sports, "the goal of the new chip is a faster laptop"],
    [:food, "the team ate pasta with basil sauce"]
  ]
end

def stop = Set["the", "a", "and", "with", "for", "of", "to", "is", "in", "on", "all", "after", "until"]

def words(text) = text.split(" ").reject { |w| stop.include?(w) }

model = Model.train(training)
puts "classes: #{model.class_docs.keys.map(&:to_s).join(", ")}"
puts "vocabulary: #{model.vocab.size}"
model.totals.each { |label, n| puts "  #{label}: #{n} words" }

correct = 0
confusion = Hash.new(0)
tests.each do |want, text|
  got = model.classify(text)
  sc = model.scores(text)
  correct += 1 if got == want
  confusion[[want, got]] += 1
  detail = sc.keys.map { |l| format("%s=%.2f", l, sc[l]) }.join(" ")
  mark = got == want ? "ok" : "MISS"
  puts format("%-4s %-7s %-45s %s", mark, got, text, detail)
end
puts format("accuracy: %d/%d = %.1f%%", correct, tests.size, 100.0 * correct / tests.size)
misses = confusion.select { |(want, got), _| want != got }
misses.each do |(want, got), n|
  puts "  confused #{want} as #{got}: #{n}"
end

[:sports, :tech, :food].each do |label|
  puts "#{label} words: #{model.indicative(label, 4).join(", ")}"
end
