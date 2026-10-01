# Transposition ciphers: rail fence (zigzag) and keyed columnar transposition,
# plus a double transposition built from the columnar one, and a brute-force rail search.

def rail_pattern(n, rails)
  pattern = []
  rail = 0
  step = 1
  n.times do
    pattern << rail
    if rails > 1
      step = 1 if rail == 0
      step = -1 if rail == rails - 1
      rail += step
    end
  end
  pattern
end

def rail_encrypt(text, rails)
  pattern = rail_pattern(text.size, rails)
  chars = text.chars
  (0...rails).map do |r|
    chars.each_index.select { |i| pattern[i] == r }.map { |i| chars[i] }.join
  end.join
end

def rail_decrypt(cipher, rails)
  n = cipher.size
  pattern = rail_pattern(n, rails)
  order = (0...n).sort_by { |i| [pattern[i], i] }
  result = Array.new(n, "")
  order.each_with_index { |pos, k| result[pos] = cipher[k] }
  result.join
end

def column_order(key)
  (0...key.size).sort_by { |i| [key[i], i] }
end

def columnar_encrypt(text, key)
  cols = key.size
  column_order(key).map do |c|
    (c...text.size).step(cols).map { |i| text[i] }.join
  end.join
end

def columnar_decrypt(cipher, key)
  cols = key.size
  n = cipher.size
  full_rows = n / cols
  extra = n % cols
  result = Array.new(n, "")
  pos = 0
  column_order(key).each do |c|
    height = full_rows + (c < extra ? 1 : 0)
    height.times do |r|
      result[r * cols + c] = cipher[pos]
      pos += 1
    end
  end
  result.join
end

COMMON_WORDS = ["THE", "AND", "ATTACK", "DAWN", "ARE", "WE"]

def score(text) = COMMON_WORDS.count { |w| text.include?(w) }

plain = "WEAREDISCOVEREDFLEEATONCE"
[2, 3, 4].each do |rails|
  enc = rail_encrypt(plain, rails)
  puts "rails=#{rails}: #{enc} -> #{rail_decrypt(enc, rails)}"
end
puts "pattern: #{rail_pattern(12, 4).join}"

key = "ZEBRAS"
puts "order for #{key}: #{column_order(key).join(",")}"
enc = columnar_encrypt(plain, key)
puts "columnar: #{enc}"
puts "back    : #{columnar_decrypt(enc, key)}"

double = columnar_encrypt(columnar_encrypt("ATTACKATDAWNXX", "SECRET"), "KEY")
puts "double  : #{double}"
puts "undone  : #{columnar_decrypt(columnar_decrypt(double, "KEY"), "SECRET")}"

intercepted = rail_encrypt("WEATTACKTHEFORTATDAWNANDHOLDTHERIDGE", 5)
puts "intercepted: #{intercepted}"
candidates = (2..8).map { |r| [r, rail_decrypt(intercepted, r)] }
best = candidates.max_by { |_, text| score(text) }
candidates.each { |r, text| puts format("  %d rails: %s (%d)", r, text, score(text)) }
if best
  r, text = best
  puts "best guess: #{r} rails -> #{text}"
end
