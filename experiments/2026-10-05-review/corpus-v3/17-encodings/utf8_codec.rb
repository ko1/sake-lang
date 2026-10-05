# A UTF-8 encoder and validating decoder working on raw byte arrays.
# The decoder reports overlong forms, surrogates, bad continuation bytes and truncation.

class Utf8Error < StandardError
  attr_reader :offset

  def initialize(message, offset)
    super(message)
    @offset = offset
  end
end

def encode_cp(cp)
  if cp < 0x80
    [cp]
  elsif cp < 0x800
    [0xC0 | (cp >> 6), 0x80 | (cp & 0x3F)]
  elsif cp < 0x10000
    raise Utf8Error.new(format("surrogate U+%04X", cp), 0) if cp.between?(0xD800, 0xDFFF)
    [0xE0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F)]
  elsif cp <= 0x10FFFF
    [0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F)]
  else
    raise Utf8Error.new(format("out of range U+%X", cp), 0)
  end
end

def encode(cps) = cps.flat_map { |cp| encode_cp(cp) }

def sequence_info(lead)
  if lead < 0x80
    [1, lead, 0]
  elsif lead & 0xE0 == 0xC0
    [2, lead & 0x1F, 0x80]
  elsif lead & 0xF0 == 0xE0
    [3, lead & 0x0F, 0x800]
  elsif lead & 0xF8 == 0xF0
    [4, lead & 0x07, 0x10000]
  else
    [0, 0, 0]
  end
end

def decode(bytes)
  cps = []
  i = 0
  n = bytes.size
  while i < n
    len, cp, min = sequence_info(bytes[i])
    raise Utf8Error.new(format("invalid lead byte %02X", bytes[i]), i) if len == 0
    raise Utf8Error.new("truncated sequence", i) if i + len > n
    (1...len).each do |k|
      b = bytes[i + k]
      raise Utf8Error.new(format("bad continuation byte %02X", b), i + k) if b & 0xC0 != 0x80
      cp = (cp << 6) | (b & 0x3F)
    end
    raise Utf8Error.new(format("overlong encoding of U+%04X", cp), i) if cp < min
    raise Utf8Error.new(format("surrogate U+%04X", cp), i) if cp.between?(0xD800, 0xDFFF)
    raise Utf8Error.new(format("out of range U+%X", cp), i) if cp > 0x10FFFF
    cps << cp
    i += len
  end
  cps
end

def hex_bytes(bytes) = bytes.map { |b| format("%02X", b) }.join(" ")
def show_cps(cps) = cps.map { |c| format("U+%04X", c) }.join(" ")

puts "== encoding code points =="
[0x41, 0xE9, 0x20AC, 0x3042, 0x1F600, 0x10FFFF].each do |cp|
  bytes = encode_cp(cp)
  puts format("U+%06X -> %-12s (%d bytes)", cp, hex_bytes(bytes), bytes.size)
end

puts "== agreeing with the host strings =="
["héllo", "€100", "日本語", "naïve café"].each do |s|
  host = s.bytes
  cps = decode(host)
  same = encode(cps) == host
  puts "#{s}: #{host.size} bytes, #{cps.size} code points, re-encoded same=#{same}"
  puts "  #{show_cps(cps)}"
end

puts "== invalid input =="
bad_inputs = [
  [0x48, 0x69, 0xFF],
  [0xC0, 0xAF],
  [0xE2, 0x82],
  [0xE2, 0x28, 0xA1],
  [0xED, 0xA0, 0x80],
  [0xF4, 0x90, 0x80, 0x80],
  [0xF0, 0x9F, 0x98, 0x80, 0x41]
]
errors = 0
bad_inputs.each do |bytes|
  cps = decode(bytes)
  puts "#{hex_bytes(bytes)}: ok #{show_cps(cps)}"
rescue Utf8Error => e
  errors += 1
  puts "#{hex_bytes(bytes)}: #{e.message} at offset #{e.offset}"
end
puts "#{errors} of #{bad_inputs.size} rejected"

[0xD800, 0x110000].each do |cp|
  encode_cp(cp)
rescue Utf8Error => e
  puts "encode: #{e.message}"
end
