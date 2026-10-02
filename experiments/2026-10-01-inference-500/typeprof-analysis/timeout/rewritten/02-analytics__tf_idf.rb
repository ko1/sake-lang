def corpus
  {
    "apples" => "apples and oranges are fruit. apples grow on trees and apples are sweet.",
    "trees" => "oak trees and pine trees grow tall. trees need water and sun.",
    "juice" => "orange juice and apple juice are sweet drinks made from fruit.",
    "garden" => "a garden needs water, sun and care. fruit trees in the garden grow slowly.",
    "market" => "the market sells fruit, juice and fresh bread every morning."
  }
end

def stop?(w) = ["a", "and", "are", "the", "on", "in", "from", "every"].include?(w)

def terms(text)
  text.downcase.split(/[^a-z]+/).reject { |w| w.empty? || stop?(w) }
end

def term_freqs(words)
  tf = Hash.new(0)
  words.each { |w| tf[w] += 1 }
  total = words.size
  tf.transform_values { |c| c * 1.0 / total }
end

def doc_freqs(docs)
  df = Hash.new(0)
  docs.each { |_, words| words.uniq.each { |w| df[w] += 1 } }
  df
end

def tfidf_vectors(docs)
  n = docs.size
  df = doc_freqs(docs)
  idf = df.transform_values { |c| Math.log(n * 1.0 / c) }
  vectors = {}
  docs.each do |name, words|
    vec = {}
    term_freqs(words).each { |w, f| vec[w] = f * idf[w] }
    vectors[name] = vec
  end
  [vectors, idf]
end

def norm(vec) = Math.sqrt(vec.sum { |_, x| x * x })

def cosine(a, b)
  dot = 0.0
  a.each do |w, x|
    y = b[w]
    dot += x * y if y
  end
  na = norm(a)
  nb = norm(b)
  return 0.0 if na == 0.0 || nb == 0.0
  dot / (na * nb)
end

def top_terms(vec, k)
  sorted = vec.sort_by { |e__0| w, _ = e__0; w }
  sorted = sorted.sort_by { |_, x| -x }
  sorted.select { |_, x| x > 0.0 }.take(k)
end

docs = corpus.transform_values { |text| terms(text) }
vectors, idf = tfidf_vectors(docs)

puts "documents: #{docs.size}, vocabulary: #{idf.size}"
everywhere = idf.select { |_, v| v < 0.6 }.keys.sort
puts "common terms (idf < 0.6): #{everywhere.join(", ")}"

vectors.each do |name, vec|
  parts = top_terms(vec, 3).map { |w, x| format("%s(%.3f)", w, x) }
  puts format("%-7s %s", name, parts.join(" "))
end

names = vectors.keys.sort
puts "cosine similarity:"
puts "        " + names.map { |n| format("%7s", n) }.join
names.each do |a|
  row = names.map { |b| format("%7.3f", cosine(vectors[a], vectors[b])) }
  puts format("%-8s", a) + row.join
end

best = nil
best_score = -1.0
names.each_with_index do |a, i|
  names.drop(i + 1).each do |b|
    s = cosine(vectors[a], vectors[b])
    if s > best_score
      best_score = s
      best = [a, b]
    end
  end
end
if best
  a, b = best
  puts format("most similar pair: %s / %s (%.3f)", a, b, best_score)
end

query = terms("sweet fruit juice")
scores = vectors.map { |name, vec| [name, query.sum { |w| vec[w] || 0.0 }] }
ranked = scores.sort_by { |e__1| n, _ = e__1; n }.sort_by { |_, s| -s }
puts "query 'sweet fruit juice': " + ranked.map { |n, s| format("%s=%.3f", n, s) }.join(" ")
