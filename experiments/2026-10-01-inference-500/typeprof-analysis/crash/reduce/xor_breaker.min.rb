# Repeating-key XOR: encrypt, guess the key length from normalised Hamming distances,
# then recover each key byte by scoring single-byte XOR candidates as English text.

def xor_with_key(bytes, key)
  k = key.bytes
end



def key_size_scores(bytes, max_size)
  scores = (2..max_size).map do |size|
    total = 0.0
    pairs = 0
    [size, pairs == 0 ? 99.0 : total / pairs]
  end
  scores.sort_by { |_, s| s }
end





plain = "Burning them they found a trail of tears, and the night was cold and the wind " \
        "blew over the hills. Nobody spoke of it again, but every one of them remembered."
key = "CODEX"
cipher = xor_with_key(plain.bytes, key)

ranked = key_size_scores(cipher, 8)

found = nil
