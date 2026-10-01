require "set"

def text
  "In the beginning the universe was created. This has made a lot of people very angry " +
  "and been widely regarded as a bad move. Many races believe that it was created by " +
  "some sort of god, though the Jatravartid people of Viltvodle Six believe that the " +
  "entire universe was in fact sneezed out of the nose of a being called the Great Green " +
  "Arkleseizure. The Jatravartids, who live in perpetual fear of the time they call The " +
  "Coming of the Great White Handkerchief, are small blue creatures with more than fifty " +
  "arms each, who are therefore unique in being the only race in history to have invented " +
  "the aerosol deodorant before the wheel. However, the Great Green Arkleseizure Theory is " +
  "not widely accepted outside Viltvodle Six and so, the universe being the puzzling place " +
  "it is, other explanations are constantly being sought."
end

def tokens(t) = t.downcase.split(/[^a-z]+/).reject(&:empty?)

def growth_curve(words, step)
  seen = Set[]
  points = []
  words.each_with_index do |w, i|
    seen << w
    n = i + 1
    points << [n, seen.size] if n % step == 0 || n == words.size
  end
  points
end

def fit_loglog(points)
  xs = points.map { |n, _| Math.log(n) }
  ys = points.map { |_, v| Math.log(v) }
  m = points.size
  mx = xs.sum / m
  my = ys.sum / m
  num = 0.0
  den = 0.0
  xs.each_with_index do |x, i|
    num += (x - mx) * (ys[i] - my)
    den += (x - mx) * (x - mx)
  end
  beta = num / den
  k = Math.exp(my - beta * mx)
  [k, beta]
end

def frequency_spectrum(counts)
  spectrum = Hash.new(0)
  counts.each_value { |c| spectrum[c] += 1 }
  spectrum
end

words = tokens(text)
counts = words.tally
puts "tokens: #{words.size}, types: #{counts.size}"
puts format("type/token ratio: %.3f", counts.size * 1.0 / words.size)

curve = growth_curve(words, 20)
puts "growth:"
curve.each do |n, v|
  puts format("  %3d tokens %3d types  ttr %.2f  %s", n, v, v * 1.0 / n, "*" * (v / 5))
end
k, beta = fit_loglog(curve)
puts format("Heaps' law fit: V = %.2f * N^%.3f", k, beta)
predicted = k * (1000.0 ** beta)
puts format("predicted types at 1000 tokens: %.0f", predicted)

spectrum = frequency_spectrum(counts)
puts "frequency spectrum:"
spectrum.keys.sort.each { |c| puts format("  %2d occurrence(s): %3d types", c, spectrum[c]) }
hapax = spectrum[1]
dis = spectrum[2]
puts format("hapax %d, dis %d, hapax ratio %.2f", hapax, dis, hapax * 1.0 / counts.size)

ranked = counts.to_a.sort_by { |w, c| [-c, w] }
puts "zipf check (rank * freq):"
ranked.take(8).each_with_index do |(w, c), i|
  puts format("  %d %-10s %2d %3d", i + 1, w, c, (i + 1) * c)
end

first_seen = {}
words.each_with_index { |w, i| first_seen[w] ||= i }
late = first_seen.keys.select { |w| first_seen[w] > words.size * 3 / 4 && counts[w] == 1 }
puts "new words in last quarter: #{late.size} (#{late.take(6).join(", ")}...)"
