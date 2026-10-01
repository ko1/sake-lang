# Extended Hamming(8,4) SECDED code: encode a message nibble by nibble, push it through a
# noisy channel with scripted bit flips, then correct single errors and detect double errors.

class Decoded
  attr_reader :nibble, :status, :flipped

  def initialize(nibble, status, flipped)
    @nibble = nibble
    @status = status
    @flipped = flipped
  end
end

def bit(v, i) = (v >> i) & 1

# Codeword bit layout (index 1..7 Hamming positions, index 0 overall parity):
# pos: 1=p1 2=p2 3=d0 4=p4 5=d1 6=d2 7=d3
def encode_nibble(n)
  d0, d1, d2, d3 = bit(n, 0), bit(n, 1), bit(n, 2), bit(n, 3)
  p1 = d0 ^ d1 ^ d3
  p2 = d0 ^ d2 ^ d3
  p4 = d1 ^ d2 ^ d3
  word = (p1 << 1) | (p2 << 2) | (d0 << 3) | (p4 << 4) | (d1 << 5) | (d2 << 6) | (d3 << 7)
  overall = (1..7).reduce(0) { |acc, i| acc ^ bit(word, i) }
  word | overall
end

def extract(word) = bit(word, 3) | (bit(word, 5) << 1) | (bit(word, 6) << 2) | (bit(word, 7) << 3)

def decode_word(word)
  syndrome = (1..7).reduce(0) { |acc, i| bit(word, i) == 1 ? acc ^ i : acc }
  parity = (0..7).reduce(0) { |acc, i| acc ^ bit(word, i) }
  if syndrome == 0 && parity == 0
    Decoded.new(extract(word), :ok, nil)
  elsif parity == 1
    fixed = word ^ (1 << syndrome)
    Decoded.new(extract(fixed), :corrected, syndrome)
  else
    Decoded.new(nil, :double, nil)
  end
end

def to_nibbles(text)
  text.bytes.flat_map { |b| [b >> 4, b & 15] }
end

def from_nibbles(nibbles)
  nibbles.each_slice(2).map do |hi, lo|
    !hi     || !lo     ? "?" : ((hi << 4) | lo).chr
  end.join
end

message = "SECDED!"
nibbles = to_nibbles(message)
words = nibbles.map { |n| encode_nibble(n) }
puts "message: #{message}"
puts "codewords: #{words.map { |w| format("%02x", w) }.join(" ")}"

# scripted noise: word index -> bits to flip
noise = { 1 => [4], 3 => [0], 6 => [2, 5], 9 => [7], 12 => [1, 6] }

received = words.each_with_index.map do |w, i|
  (noise[i] || []).reduce(w) { |acc, b| acc ^ (1 << b) }
end

counts = Hash.new(0)
out_nibbles = []
received.each_with_index do |w, i|
  r = decode_word(w)
  counts[r.status] += 1
  case r.status
  in :ok
    out_nibbles << r.nibble
  in :corrected
    puts format("word %2d: %08b -> fixed bit %d", i, w, r.flipped)
    out_nibbles << r.nibble
  in :double
    puts format("word %2d: %08b -> double error, nibble lost", i, w)
    out_nibbles << nil
  end
end

puts "decoded: #{from_nibbles(out_nibbles)}"
puts "ok=#{counts[:ok]} corrected=#{counts[:corrected]} double=#{counts[:double]}"

all_ok = (0..15).all? do |n|
  w = encode_nibble(n)
  (0..7).all? { |b| decode_word(w ^ (1 << b)).nibble == n }
end
puts "every single-bit error corrected for all 16 nibbles: #{all_ok}"
