# Word statistics over a few short documents: stopwords, frequencies, bigrams, and document overlap.

def stopwords = Set["the", "a", "an", "of", "and", "to", "in", "is", "it", "that", "on", "for", "with", "as", "was", "be"]

def documents
  {
    "intro" => "The cat sat on the mat. The cat was happy, and the mat was warm.",
    "sequel" => "A dog chased the cat around the garden; the dog was fast and the cat was faster.",
    "garden" => "In the garden the roses grow. Roses need water, sun, and a patient gardener.",
    "notes" => "Water the roses. Feed the cat. Walk the dog. Repeat."
  }
end

def tokenize(text)
  text.downcase.scan(/[a-z]+/).reject { |w| stopwords.include?(w) }
end

def bigrams(words)
  words.each_cons(2).map { |pair| pair.join(" ") }
end

def top_n(counts, n)
  counts.sort_by { |w, c| [-c, w] }.take(n)
end

docs = documents
tokens = docs.transform_values { |text| tokenize(text) }

puts "== Per document =="
tokens.each do |name, words|
  longest = words.max_by(&:size)
  puts format("%-7s words=%2d unique=%2d longest=%s", name, words.size, words.uniq.size, longest)
end

all_words = tokens.values.flatten
freq = all_words.tally
puts "== Top words =="
top_n(freq, 5).each { |w, c| puts format("%-10s %d", w, c) }

puts "== Top bigrams =="
bi = Hash.new(0)
tokens.each_value { |words| bigrams(words).each { |b| bi[b] += 1 } }
repeated = bi.select { |b, c| c > 1 }
puts "distinct: #{bi.size}, repeated: #{repeated.size}"
top_n(bi, 4).each { |b, c| puts "#{b}: #{c}" }

puts "== Document frequency =="
vocab = tokens.transform_values(&:to_set)
df = Hash.new(0)
vocab.each_value { |set| set.each { |w| df[w] += 1 } }
everywhere = df.select { |w, n| n == vocab.size }.keys
p everywhere.sort
in_three = df.select { |w, n| n >= 3 }.keys.sort
p in_three

puts "== Shared vocabulary =="
vocab.keys.sort.combination(2).each do |a, b|
  shared = vocab[a] & vocab[b]
  next if shared.empty?
  puts "#{a} & #{b}: #{shared.sort.join(",")}"
end

puts "== Unique to one document =="
vocab.each do |name, set|
  others = vocab.reduce(Set[]) { |acc, (n, s)| n == name ? acc : acc | s }
  only = (set - others).sort
  puts "#{name}: #{only.take(4).join(" ")}#{only.size > 4 ? " ..." : ""}"
end

puts "== Letters =="
letters = all_words.flat_map(&:chars).tally
vowels = Set["a", "e", "i", "o", "u"]
v, c = letters.partition { |l, n| vowels.include?(l) }
puts "vowels: #{v.sum { |l, n| n }}, consonants: #{c.sum { |l, n| n }}"
rare = letters.select { |l, n| n == 1 }.map { |l, n| l }.sort
puts "seen once: #{rare.join}"
missing = ("a".."z").reject { |l| letters.key?(l) }
puts "never: #{missing.join}"
