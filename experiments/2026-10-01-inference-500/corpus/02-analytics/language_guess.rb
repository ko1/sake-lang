require "set"

def samples
  {
    "english" => "the quick brown fox jumps over the lazy dog and then the dog runs away from the house " +
                 "while the children are watching through the window with their mother and father",
    "german" => "der schnelle braune fuchs springt ueber den faulen hund und dann laeuft der hund " +
                "weg von dem haus waehrend die kinder durch das fenster mit ihrer mutter schauen",
    "spanish" => "el rapido zorro marron salta sobre el perro perezoso y luego el perro corre lejos " +
                 "de la casa mientras los ninos miran por la ventana con su madre y su padre",
    "dutch" => "de snelle bruine vos springt over de luie hond en dan rent de hond weg van het huis " +
               "terwijl de kinderen door het raam kijken met hun moeder en vader"
  }
end

def trigrams(text)
  counts = Hash.new(0)
  text.downcase.split(/[^a-z]+/).each do |w|
    next if w.empty?
    padded = "_#{w}_"
    (padded.size - 2).times { |i| counts[padded[i..(i + 2)]] += 1 }
  end
  counts
end

def profile(text, size)
  ranked = trigrams(text).to_a.sort_by { |g, n| [-n, g] }
  ranks = {}
  ranked.take(size).each_with_index { |(g, _), i| ranks[g] = i }
  ranks
end

def out_of_place(doc, lang, penalty)
  total = 0
  doc.each do |g, rank|
    other = lang[g]
    total += other ? (rank - other).abs : penalty
  end
  total
end

def tests
  [
    ["english", "the dog and the cat are in the house"],
    ["german", "die katze und der hund sind in dem haus"],
    ["spanish", "el gato y el perro estan en la casa"],
    ["dutch", "de kat en de hond zijn in het huis"],
    ["english", "watching their window"],
    ["dutch", "snelle vader"]
  ]
end

profiles = samples.transform_values { |t| profile(t, 60) }
profiles.each do |lang, prof|
  top = prof.keys.sort_by { |g| prof[g] }
  puts format("%-8s %2d trigrams, top: %s", lang, prof.size, top.take(8).join(" "))
end

langs = profiles.keys.sort
puts "shared trigrams:"
langs.each do |a|
  cells = langs.map do |b|
    shared = profiles[a].keys.to_set & profiles[b].keys.to_set
    format("%4d", shared.size)
  end
  puts format("  %-8s", a) + cells.join
end

right = 0
tests.each do |want, text|
  doc = profile(text, 60)
  dists = profiles.map { |lang, prof| [lang, out_of_place(doc, prof, 60)] }
  ordered = dists.sort_by { |lang, d| [d, langs.index(lang)] }
  best_lang, best = ordered[0]
  _, second = ordered[1]
  right += 1 if best_lang == want
  mark = best_lang == want ? "ok  " : "MISS"
  puts format("%s %-8s margin %4d  %s", mark, best_lang, second - best, text)
end
puts "#{right}/#{tests.size} correct"
