def english_freq
  [8.2, 1.5, 2.8, 4.3, 12.7, 2.2, 2.0, 6.1, 7.0, 0.15, 0.77, 4.0, 2.4,
   6.7, 7.5, 1.9, 0.095, 6.0, 6.3, 9.1, 2.8, 0.98, 2.4, 0.15, 2.0, 0.074]
end

def shift_char(c, k)
  case c
  when "a".."z" then ((c.ord - 97 + k) % 26 + 97).chr
  when "A".."Z" then ((c.ord - 65 + k) % 26 + 65).chr
  else c
  end
end

def caesar(text, k) = text.chars.map { |c| shift_char(c, k) }.join

def atbash(text)
  text.chars.map do |c|
    case c
    when "a".."z" then (122 - (c.ord - 97)).chr
    when "A".."Z" then (90 - (c.ord - 65)).chr
    else c
    end
  end.join
end

def vigenere(text, key, direction)
  shifts = key.downcase.chars.map { |c| c.ord - 97 }
  i = 0
  text.each_char.map do |c|
    next c unless c.match?(/[A-Za-z]/)
    shifted = shift_char(c, shifts[i % shifts.size] * direction)
    i += 1
    shifted
  end.join
end

def letter_counts(text)
  counts = Array.new(26, 0)
  text.downcase.each_char { |c| counts[c.ord - 97] += 1 if ("a".."z").cover?(c) }
  counts
end

def chi_squared(text)
  counts = letter_counts(text)
  total = counts.sum
  return 1.0e9 if total == 0
  score = 0.0
  english_freq.each_with_index do |pct, i|
    expected = total * pct / 100.0
    diff = counts[i] - expected
    score += diff * diff / expected
  end
  score
end

def crack_caesar(cipher)
  scored = (0...26).map { |k| [k, chi_squared(caesar(cipher, 26 - k))] }
  best = scored.min_by { |e__0| _, s = e__0; s }
  ranked = scored.sort_by { |e__1| _, s = e__1; s }
  [best[0], ranked.take(3)]
end

def top_letters(text, n)
  counts = letter_counts(text)
  (0...26).sort_by { |i| -counts[i] * 100 + i }.take(n).map { |i| (97 + i).chr }.join
end

plain = "Defend the east wall of the castle. Reinforcements arrive at dawn; hold the gate until then!"
puts "plain:    #{plain}"
rot13 = caesar(plain, 13)
puts "rot13:    #{rot13}"
puts "rot13 x2 round-trips: #{caesar(rot13, 13) == plain}"
puts "atbash:   #{atbash(plain)}"
puts "atbash x2 round-trips: #{atbash(atbash(plain)) == plain}"
v = vigenere(plain, "Lemon", 1)
puts "vigenere: #{v}"
puts "decoded:  #{vigenere(v, "Lemon", -1)}"
puts "top letters plain/vigenere: #{top_letters(plain, 5)} / #{top_letters(v, 5)}"
puts

[3, 11, 22].each do |k|
  secret = caesar(plain, k)
  guess, ranked = crack_caesar(secret)
  candidates = ranked.map { |shift, score| format("%d:%.1f", shift, score) }.join(" ")
  status = guess == k ? "ok" : "WRONG"
  puts "shift #{k.to_s.rjust(2)} -> guessed #{guess.to_s.rjust(2)} #{status}  [#{candidates}]"
end
short = caesar("zzz", 4)
guess, _ranked = crack_caesar(short)
puts "short text #{short.inspect}: guessed #{guess} (too little text)"
