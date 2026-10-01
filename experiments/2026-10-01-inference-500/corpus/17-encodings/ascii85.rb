# Ascii85 (Adobe variant, with <~ ~> delimiters and the "z" shortcut for zero groups),
# encoder and decoder, compared against hex for size overhead.

class A85Error < StandardError
  attr_reader :index

  def initialize(message, index)
    super(message)
    @index = index
  end
end

def encode85(bytes)
  out = bytes.each_slice(4).map do |chunk|
    n = chunk.size
    value = (chunk + [0] * (4 - n)).reduce(0) { |acc, b| (acc << 8) | b }
    if value == 0 && n == 4
      "z"
    else
      digits = []
      5.times do
        digits.unshift((value % 85 + 33).chr)
        value /= 85
      end
      digits.take(n + 1).join
    end
  end.join
  "<~" + out + "~>"
end

def decode85(text)
  body = text.strip
  raise A85Error.new("missing delimiters", 0) unless body.start_with?("<~") && body.end_with?("~>")
  body = body[2...(body.size - 2)].gsub(/\s/, "")
  bytes = []
  group = []
  body.chars.each_with_index do |c, i|
    if c == "z"
      raise A85Error.new("z inside a group", i) unless group.empty?
      bytes.push(0, 0, 0, 0)
      next
    end
    code = c.ord - 33
    raise A85Error.new("invalid character #{c.inspect}", i) if code < 0 || code > 84
    group << code
    if group.size == 5
      bytes.concat(group_bytes(group, 4, i))
      group = []
    end
  end
  unless group.empty?
    raise A85Error.new("final group of one character", body.size) if group.size == 1
    n = group.size - 1
    group << 84 while group.size < 5
    bytes.concat(group_bytes(group, n, body.size))
  end
  bytes
end

def group_bytes(group, keep, at)
  value = group.reduce(0) { |acc, d| acc * 85 + d }
  raise A85Error.new("group overflows 32 bits", at) if value > 0xFFFFFFFF
  [24, 16, 8, 0].map { |s| (value >> s) & 0xFF }.take(keep)
end

def text_of(bytes) = bytes.map(&:chr).join

inputs = ["Man ", "sure.", "Hello, World!", "", "\x00\x00\x00\x00\x00\x00\x00\x00abc",
          "Ascii85 packs four bytes into five printable characters."]
inputs.each do |s|
  bytes = s.bytes
  enc = encode85(bytes)
  back = decode85(enc)
  overhead = bytes.empty? ? 0.0 : 100.0 * (enc.size - 4) / bytes.size - 100.0
  puts s.inspect
  puts format("  %s", enc)
  puts format("  %d bytes -> %d chars (%+.0f%%, hex would be %d) roundtrip=%s",
              bytes.size, enc.size - 4, overhead, bytes.size * 2, text_of(back) == s)
end

puts "-- with whitespace --"
puts text_of(decode85("<~9jqo^BlbD-BleB1DJ+*+F(f,q/0JhKF<GL>Cj@.4Gp$d7F!,L7@<6@)/0JDEF<G%<+EV:2F!,\n O<DJ+*.@<*K0@<6L(Df-\\0Ec5e;DffZ(EZee.Bl.9pF\"AGXBPCsi+DGm>@3BB/F*&OCAfu2/AKY\n i(DIb:@FD,*)+C]U=@3BN#EcYf8ATD3s@q?d$AftVqCh[NqF<G:8+EV:.+Cf>-FD5W8ARlolDIa\n l(DId<j@<?3r@:F%a+D58'ATD4$Bl@l3De:,-DJs`8ARoFb/0JMK@qB4^F!,R<AKZ&-DfTqBG%G\n >uD.RTpAKYo'+CT/5+Cei#DII?(E,9)oF*2M7/c~>"))

puts "-- errors --"
["<~87cURD]i,\"Ebo80~>", "87cURD", "<~87c{URD~>", "<~87cURz~>", "<~s8W-\"s~>", "<~s8W-!~>"].each do |bad|
  b = decode85(bad)
  puts "#{bad} -> #{text_of(b).inspect}"
rescue A85Error => e
  puts "#{bad} -> #{e.message} (at #{e.index})"
end
