# Repeating-key XOR: encrypt, guess the key length from normalised Hamming distances,
# then recover each key byte by scoring single-byte XOR candidates as English text.

def xor_with_key(bytes, key)
  k = key.bytes
  bytes.each_with_index.map { |b, i| b ^ k[i % k.size] }
end

def popcount(n)
  c = 0
  while n > 0
    c += n & 1
    n >>= 1
  end
  c
end

def hamming(a, b)
  a.each_with_index.sum { |x, i| popcount(x ^ b[i]) }
end

def key_size_scores(bytes, max_size)
  scores = (2..max_size).map do |size|
    blocks = [4, bytes.size / size].min
    total = 0.0
    pairs = 0
    (0...(blocks - 1)).each do |i|
      a = bytes[(i * size)...((i + 1) * size)]
      b = bytes[((i + 1) * size)...((i + 2) * size)]
      total += hamming(a, b).fdiv(size)
      pairs += 1
    end
    [size, pairs == 0 ? 99.0 : total / pairs]
  end
  scores.sort_by { |_, s| s }
end

def english_score(bytes)
  bytes.sum do |b|
    if b == 32
      3
    elsif b.between?(97, 122)
      b.chr =~ /[etaoinshr]/ ? 3 : 2
    elsif b.between?(65, 90)
      1
    elsif b < 32 && b != 10
      -10
    elsif b >= 127
      -10
    else
      0
    end
  end
end

def best_single_byte(column)
  # keys are printable text
  (32..126).max_by { |k| english_score(column.map { |b| b ^ k }) }
end

def transpose(bytes, size)
  columns = Array.new(size) { [] }
  bytes.each_with_index { |b, i| columns[i % size] << b }
  columns
end

def to_text(bytes) = bytes.map(&:chr).join

plain = "Burning them they found a trail of tears, and the night was cold and the wind " \
        "blew over the hills. Nobody spoke of it again, but every one of them remembered."
key = "CODEX"
cipher = xor_with_key(plain.bytes, key)
puts "cipher head: #{cipher.take(16).map { |b| format("%02x", b) }.join}"
puts "hamming('this is a test', 'wokka wokka!!!') = #{hamming("this is a test".bytes, "wokka wokka!!!".bytes)}"

ranked = key_size_scores(cipher, 8)
ranked.take(3).each { |size, s| puts format("key size %d: %.3f", size, s) }

found = nil
ranked.take(3).each do |size, _|
  guess = to_text(transpose(cipher, size).map { |col| best_single_byte(col) })
  text = to_text(xor_with_key(cipher, guess))
  puts "size #{size}: key=#{guess.inspect} -> #{text[0...40]}"
  found ||= guess if guess == key
end
puts(found ? "recovered key: #{found}" : "key not recovered")
