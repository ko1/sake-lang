class Model
  attr_reader :states, :start, :trans, :emit

  def initialize(states, start, trans, emit)
    @states = states
    @start = start
    @trans = trans
    @emit = emit
  end

  def emission(state, obs) = @emit[state].fetch(obs, 0.0)
end

def viterbi(model, observations)
  states = model.states
  columns = []
  back = []
  columns << states.to_h { |s| [s, model.start[s] * model.emission(s, observations[0])] }
  observations.drop(1).each do |obs|
    prev = columns.last
    col = {}
    ptr = {}
    states.each do |s|
      best_state = states.max_by { |r| prev[r] * model.trans[r][s] }
      col[s] = prev[best_state] * model.trans[best_state][s] * model.emission(s, obs)
      ptr[s] = best_state
    end
    columns << col
    back << ptr
  end
  last = columns.last
  state = states.max_by { |s| last[s] }
  prob = last[state]
  path = [state]
  back.reverse_each do |ptr|
    state = ptr[state]
    path.unshift(state)
  end
  [path, prob]
end

def forward(model, observations)
  states = model.states
  alpha = states.to_h { |s| [s, model.start[s] * model.emission(s, observations[0])] }
  observations.drop(1).each do |obs|
    alpha = states.to_h do |s|
      total = states.sum { |r| alpha[r] * model.trans[r][s] }
      [s, total * model.emission(s, obs)]
    end
  end
  alpha.values.sum
end

weather = Model.new(
  ["Rainy", "Sunny"],
  { "Rainy" => 0.6, "Sunny" => 0.4 },
  { "Rainy" => { "Rainy" => 0.7, "Sunny" => 0.3 }, "Sunny" => { "Rainy" => 0.4, "Sunny" => 0.6 } },
  { "Rainy" => { "walk" => 0.1, "shop" => 0.4, "clean" => 0.5 },
    "Sunny" => { "walk" => 0.6, "shop" => 0.3, "clean" => 0.1 } }
)

diaries = [
  "walk shop clean",
  "walk walk walk",
  "clean clean shop walk walk",
  "shop clean walk clean clean shop walk",
  "walk swim"
]
diaries.each do |line|
  obs = line.split(" ")
  path, prob = viterbi(weather, obs)
  total = forward(weather, obs)
  share = total > 0 ? prob / total * 100 : 0.0
  puts line
  puts format("  best: %s  p=%.6f", path.map { |s| s[0] }.join, prob)
  puts format("  all paths p=%.6f, best explains %.1f%%", total, share)
end

tagger = Model.new(
  ["DET", "NOUN", "VERB"],
  { "DET" => 0.6, "NOUN" => 0.3, "VERB" => 0.1 },
  { "DET" => { "DET" => 0.05, "NOUN" => 0.9, "VERB" => 0.05 },
    "NOUN" => { "DET" => 0.1, "NOUN" => 0.3, "VERB" => 0.6 },
    "VERB" => { "DET" => 0.6, "NOUN" => 0.3, "VERB" => 0.1 } },
  { "DET" => { "the" => 0.7, "a" => 0.3 },
    "NOUN" => { "dog" => 0.3, "duck" => 0.3, "park" => 0.2, "walk" => 0.2 },
    "VERB" => { "duck" => 0.3, "walk" => 0.4, "saw" => 0.3 } }
)
["the dog saw a duck", "a duck walk the park", "the walk saw the duck"].each do |sentence|
  words = sentence.split(" ")
  tags, prob = viterbi(tagger, words)
  pairs = words.zip(tags).map { |w, t| "#{w}/#{t}" }
  puts format("%-40s %.2e", pairs.join(" "), prob)
end
