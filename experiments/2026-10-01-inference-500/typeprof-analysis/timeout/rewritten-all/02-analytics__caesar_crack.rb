def english_freq
  {
    "a" => 8.2, "b" => 1.5, "c" => 2.8, "d" => 4.3, "e" => 12.7, "f" => 2.2, "g" => 2.0,
    "h" => 6.1, "i" => 7.0, "j" => 0.15, "k" => 0.77, "l" => 4.0, "m" => 2.4, "n" => 6.7,
    "o" => 7.5, "p" => 1.9, "q" => 0.095, "r" => 6.0, "s" => 6.3, "t" => 9.1, "u" => 2.8,
    "v" => 0.98, "w" => 2.4, "x" => 0.15, "y" => 2.0, "z" => 0.074
  }
end

def alphabet = "abcdefghijklmnopqrstuvwxyz"

def shift_char(c, k)
  lower = c.downcase
  i = alphabet.index(lower)
  return c if i.nil? || lower.size != 1
  shifted = alphabet[(i + k) % 26]
  c == lower ? shifted : shifted.upcase
end

def shift_text(text, k) = text.chars.map { |c| shift_char(c, k) }.join

def letter_counts(text)
  counts = Hash.new(0)
  text.downcase.each_char { |c| counts[c] += 1 if alphabet.include?(c) }
  counts
end

def chi_squared(text)
  counts = letter_counts(text)
  total = counts.values.sum
  return 1.0e9 if total == 0
  score = 0.0
  english_freq.each do |c, pct|
    expected = total * pct / 100.0
    diff = counts[c] - expected
    score += diff * diff / expected
  end
  score
end

def crack(cipher)
  scores = {}
  26.times { |k| scores[k] = chi_squared(shift_text(cipher, 26 - k)) }
  scores.min_by { |e__0| _, s = e__0; s }
end

def histogram(text, width)
  counts = letter_counts(text)
  top = counts.to_a.sort_by { |e__1| c, n = e__1; -n * 100 + c.ord }.take(6)
  maxn = counts.values.max
  top.map do |e__2| c, n = e__2;
    "#{c} #{("*" * (n * width / maxn)).ljust(width)} #{n}"
  end
end

messages = [
  ["Attack at dawn, the bridge is lightly guarded and the river is low.", 3],
  ["Meet me by the old oak tree when the clock strikes seven tonight.", 11],
  ["Frequency analysis breaks every simple substitution given enough text.", 19],
  ["Hello", 7]
]

messages.each do |plain, key|
  cipher = shift_text(plain, key)
  puts "cipher: #{cipher}"
  found = crack(cipher)
  if found
    k, score = found
    decoded = shift_text(cipher, 26 - k)
    status = k == key ? "ok" : "WRONG (true key #{key})"
    puts format("  key=%2d chi2=%8.2f %s", k, score, status)
    puts "  plain: #{decoded}"
  end
end

sample = "It is a truth universally acknowledged that a single man in possession of a good fortune must be in want of a wife"
puts "letter histogram:"
histogram(sample, 20).each { |line| puts "  #{line}" }
rot13 = shift_text(sample, 13)
puts "rot13 round trip ok: #{shift_text(rot13, 13) == sample}"
