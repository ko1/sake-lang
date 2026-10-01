# Caesar cipher with ROT13 and a frequency-based cracker.

ENGLISH_FREQ = {
  "a" => 8.2, "b" => 1.5, "c" => 2.8, "d" => 4.3, "e" => 12.7, "f" => 2.2,
  "g" => 2.0, "h" => 6.1, "i" => 7.0, "j" => 0.15, "k" => 0.77, "l" => 4.0,
  "m" => 2.4, "n" => 6.7, "o" => 7.5, "p" => 1.9, "q" => 0.095, "r" => 6.0,
  "s" => 6.3, "t" => 9.1, "u" => 2.8, "v" => 0.98, "w" => 2.4, "x" => 0.15,
  "y" => 2.0, "z" => 0.074
}

def shift_char(c, k)
  o = c.ord
  if o.between?(65, 90)
    ((o - 65 + k) % 26 + 65).chr
  elsif o.between?(97, 122)
    ((o - 97 + k) % 26 + 97).chr
  else
    c
  end
end

def encrypt(text, k) = text.chars.map { |c| shift_char(c, k) }.join

def decrypt(text, k) = encrypt(text, 26 - k % 26)

def rot13(text) = encrypt(text, 13)

def letter_counts(text)
  counts = Hash.new(0)
  text.downcase.each_char { |c| counts[c] += 1 if c.match?(/[a-z]/) }
  counts
end

def chi_squared(text)
  counts = letter_counts(text)
  total = counts.sum { |_, n| n }
  return 1.0e9 if total == 0
  ENGLISH_FREQ.sum(0.0) do |letter, pct|
    expected = total * pct / 100.0
    diff = counts.fetch(letter, 0) - expected
    diff * diff / expected
  end
end

def crack(cipher)
  candidates = (0..25).map do |k|
    plain = decrypt(cipher, k)
    { key: k, score: chi_squared(plain), plain: plain }
  end
  candidates.sort_by { |c| c[:score] }.take(3)
end

messages = [
  "Meet me at the old bridge after sunset",
  "The quick brown fox jumps over the lazy dog",
  "Attack at dawn, hold the northern ridge!",
  "Cryptography is the art of writing secret messages"
]
keys = [3, 11, 19, 7]

messages.each_with_index do |msg, i|
  k = keys[i]
  enc = encrypt(msg, k)
  puts "plain : #{msg}"
  puts "key #{k}: #{enc}"
  puts "roundtrip ok: #{decrypt(enc, k) == msg}"
  top = crack(enc)
  top.each do |cand|
    puts format("  guess k=%2d chi2=%9.2f %s", cand[:key], cand[:score], cand[:plain][0...30])
  end
  best = top.first
  puts "  cracked: #{best[:key] == k ? "yes" : "no"}" if best
end

puts rot13("Why did the chicken cross the road?")
puts rot13(rot13("Why did the chicken cross the road?"))
