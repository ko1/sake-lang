# Base32 in two flavours sharing one bit-packing core: RFC 4648 (padded, for bytes) and
# Crockford (for integer IDs, with ambiguous-letter normalisation and a mod-37 check symbol).

module Base32
  def encode_bytes(bytes)
    alphabet = chars
    out = +""
    buffer = 0
    bits = 0
    bytes.each do |b|
      buffer = (buffer << 8) | b
      bits += 8
      while bits >= 5
        bits -= 5
        out << alphabet[(buffer >> bits) & 31]
      end
    end
    out << alphabet[(buffer << (5 - bits)) & 31] if bits > 0
    pad(out)
  end

  def decode_bytes(text)
    bytes = []
    buffer = 0
    bits = 0
    normalize(text).each_char do |c|
      v = value_of(c)
      raise ArgumentError, "invalid symbol #{c.inspect}" if !v    
      buffer = (buffer << 5) | v
      bits += 5
      if bits >= 8
        bits -= 8
        bytes << ((buffer >> bits) & 0xFF)
      end
    end
    bytes
  end

  def value_of(c) = chars.index(c)
end

class Rfc4648
  include Base32
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
  def pad(s) = s.size % 8 == 0 ? s : s + "=" * (8 - s.size % 8)
  def normalize(s) = s.upcase.delete("=")
end

class Crockford
  include Base32
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def chars = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  def check_chars = "0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U"
  def pad(s) = s
  def normalize(s) = s.upcase.delete("-").tr("ILO", "110")

  def encode_id(n)
    digits = +""
    v = n
    loop do
      digits.prepend(chars[v % 32])
      v /= 32
      break if v == 0
    end
    digits + check_chars[n % 37]
  end

  def decode_id(text)
    clean = normalize(text)
    body = clean[0...(clean.size - 1)]
    check = clean[-1]
    n = body.each_char.reduce(0) do |acc, ch|
      v = value_of(ch)
      raise ArgumentError, "invalid symbol #{ch.inspect}" if !v    
      acc * 32 + v
    end
    expected = check_chars[n % 37]
    raise ArgumentError, "check symbol #{check} should be #{expected}" if check != expected
    n
  end
end

def text_of(bytes) = bytes.map(&:chr).join

rfc = Rfc4648.new("rfc4648")
crock = Crockford.new("crockford")

puts "== RFC 4648 =="
["", "f", "fo", "foo", "foob", "fooba", "foobar"].each do |s|
  enc = rfc.encode_bytes(s.bytes)
  back = text_of(rfc.decode_bytes(enc))
  puts format("%-8s %-18s %s", s.inspect, enc, back == s ? "ok" : "MISMATCH")
end

puts "== same bytes, both codecs =="
data = "Sake!".bytes
[rfc, crock].each do |codec|
  enc = codec.encode_bytes(data)
  puts "#{codec.name}: #{enc} -> #{text_of(codec.decode_bytes(enc))}"
end

puts "== Crockford IDs =="
[0, 1, 31, 32, 1234, 987654321, 18446744073709551615].each do |id|
  code = crock.encode_id(id)
  puts format("%20d -> %-16s -> %d", id, code, crock.decode_id(code))
end

puts "== typed by hand =="
["16JD", "16jd", "1-6-J-D", "I6JD", "16JE", "1U6JD", "O0", "l0*"].each do |typed|
  puts "#{typed} -> #{crock.decode_id(typed)}"
rescue ArgumentError => e
  puts "#{typed} -> rejected: #{e.message}"
end
