# Base64 (standard and URL-safe) encoder/decoder written by hand.

class DecodeError < StandardError
  attr_reader :position

  def initialize(message, position)
    super(message)
    @position = position
  end
end

STD_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
URL_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

def encode(bytes, alphabet, pad)
  out = +""
  bytes.each_slice(3) do |chunk|
    b0, b1, b2 = chunk[0], chunk[1] || 0, chunk[2] || 0
    triple = (b0 << 16) | (b1 << 8) | b2
    out << alphabet[(triple >> 18) & 63]
    out << alphabet[(triple >> 12) & 63]
    if chunk.size > 1
      out << alphabet[(triple >> 6) & 63]
    elsif pad
      out << "="
    end
    if chunk.size > 2
      out << alphabet[triple & 63]
    elsif pad
      out << "="
    end
  end
  out
end

def reverse_table(alphabet)
  alphabet.chars.each_with_index.to_h
end

def decode(text, alphabet)
  table = reverse_table(alphabet)
  clean = text.delete("=\n ")
  bytes = []
  buffer = 0
  bits = 0
  clean.chars.each_with_index do |c, pos|
    v = table[c]
    raise DecodeError.new("invalid character #{c.inspect}", pos) if v.nil?
    buffer = (buffer << 6) | v
    bits += 6
    if bits >= 8
      bits -= 8
      bytes << ((buffer >> bits) & 255)
    end
  end
  raise DecodeError.new("dangling bits", bytes.size) if bits >= 6
  bytes
end

def bytes_to_string(bytes) = bytes.map(&:chr).join

def hex(bytes) = bytes.map { |b| format("%02x", b) }.join(" ")

samples = ["", "f", "fo", "foo", "foob", "fooba", "foobar",
           "Many hands make light work.", "subjects?_d>>"]

samples.each do |s|
  enc = encode(s.bytes, STD_ALPHABET, true)
  back = bytes_to_string(decode(enc, STD_ALPHABET))
  status = back == s ? "ok" : "MISMATCH"
  puts format("%-30s -> %-40s %s", s.inspect, enc, status)
end

puts "-- url-safe, unpadded --"
binary = [251, 255, 191, 0, 62, 63, 254]
puts "bytes: #{hex(binary)}"
puts "std  : #{encode(binary, STD_ALPHABET, true)}"
url = encode(binary, URL_ALPHABET, false)
puts "url  : #{url}"
puts "url decoded: #{hex(decode(url, URL_ALPHABET))}"

puts "-- wrapped input --"
wrapped = "TWFu\nIGlz IGRp\nc3Rp\nbmd1aXNoZWQ="
puts bytes_to_string(decode(wrapped, STD_ALPHABET))

puts "-- errors --"
["SGVsbG8*", "QUJD$EFG", "QQ", "Q"].each do |bad|
  result = decode(bad, STD_ALPHABET)
  puts "#{bad}: decoded #{result.size} bytes: #{hex(result)}"
rescue DecodeError => e
  puts "#{bad}: error at #{e.position}: #{e.message}"
end
