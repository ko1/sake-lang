# Vigenere and autokey ciphers, with key-length estimation by the index of coincidence
# and key recovery by per-column frequency matching.

def letters_only(s) = s.upcase.gsub(/[^A-Z]/, "")

def shift(c, k, dir) = ((c.ord - 65 + dir * (k.ord - 65) + 26) % 26 + 65).chr

def vigenere(text, key, dir)
  text.chars.each_with_index.map { |c, i| shift(c, key[i % key.size], dir) }.join
end

def autokey_encrypt(text, key)
  stream = key + text
  text.chars.each_with_index.map { |c, i| shift(c, stream[i], 1) }.join
end

def autokey_decrypt(cipher, key)
  stream = key.dup
  cipher.chars.each_with_index.map do |c, i|
    p = shift(c, stream[i], -1)
    stream << p
    p
  end.join
end

def index_of_coincidence(s)
  n = s.size
  return 0.0 if n < 2
  total = s.chars.tally.sum { |_, f| f * (f - 1) }
  total.fdiv(n * (n - 1))
end

def columns(s, period)
  cols = Array.new(period) { +"" }
  s.chars.each_with_index { |c, i| cols[i % period] << c }
  cols
end

def guess_period(cipher, max)
  scored = (1..max).map do |p|
    ics = columns(cipher, p).map { |col| index_of_coincidence(col) }
    { period: p, ic: ics.sum / ics.size }
  end
  scored.find { |r| r[:ic] > 0.058 } || scored.max_by { |r| r[:ic] }
end

ENGLISH = [8.2, 1.5, 2.8, 4.3, 12.7, 2.2, 2.0, 6.1, 7.0, 0.15, 0.77, 4.0, 2.4,
           6.7, 7.5, 1.9, 0.095, 6.0, 6.3, 9.1, 2.8, 0.98, 2.4, 0.15, 2.0, 0.074]

def best_shift(col)
  counts = col.chars.tally
  n = col.size
  best = (0..25).min_by do |k|
    ENGLISH.each_with_index.sum(0.0) do |pct, j|
      letter = ((j + k) % 26 + 65).chr
      expected = n * pct / 100.0
      d = counts.fetch(letter, 0) - expected
      d * d / expected
    end
  end
  ((best || 0) + 65).chr
end

plain = letters_only("It was the best of times, it was the worst of times, it was the age of wisdom, " \
                     "it was the age of foolishness, it was the epoch of belief, it was the epoch " \
                     "of incredulity, it was the season of light, it was the season of darkness")
key = "DICKENS"
cipher = vigenere(plain, key, 1)
puts "cipher: #{cipher[0...60]}..."
puts format("IC plain=%.4f cipher=%.4f", index_of_coincidence(plain), index_of_coincidence(cipher))

guess = guess_period(cipher, 10)
if guess
  period = guess[:period]
  puts format("guessed period %d (IC %.4f)", period, guess[:ic])
  recovered = columns(cipher, period).map { |col| best_shift(col) }.join
  puts "recovered key: #{recovered}"
  puts "decrypted: #{vigenere(cipher, recovered, -1)[0...60]}..."
  puts "correct: #{recovered == key}"
end

puts "-- autokey --"
ak = autokey_encrypt("ATTACKATDAWN", "QUEENLY")
puts "#{ak} -> #{autokey_decrypt(ak, "QUEENLY")}"
puts "vigenere with same key: #{vigenere("ATTACKATDAWN", "QUEENLY", 1)}"
