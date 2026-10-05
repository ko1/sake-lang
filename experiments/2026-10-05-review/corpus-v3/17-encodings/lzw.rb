# LZW compression with a growing dictionary
# (variable code width, frozen once full), and the matching decompressor, including the
# tricky "cScSc" case.

MAX_CODE = 511

def initial_dict
  (0...256).to_h { |i| [i.chr, i] }
end

def compress(text)
  dict = initial_dict
  next_code = 256
  codes = []
  w = +""
  text.each_char do |c|
    wc = w + c
    if dict.key?(wc)
      w = wc
    else
      codes << dict[w]
      if next_code <= MAX_CODE
        dict[wc] = next_code
        next_code += 1
      end
      w = c
    end
  end
  codes << dict[w] unless w.empty?
  codes
end

def decompress(codes)
  dict = (0...256).to_h { |i| [i, i.chr] }
  next_code = 256
  return "" if codes.empty?
  w = dict[codes.first]
  out = w.dup
  codes.drop(1).each do |k|
    entry = dict[k]
    if entry.nil?
      raise ArgumentError, "bad code #{k}" if k != next_code
      entry = w + w[0]
    end
    out << entry
    if next_code <= MAX_CODE
      dict[next_code] = w + entry[0]
      next_code += 1
    end
    w = entry
  end
  out
end

def bit_width(n)
  w = 9
  w += 1 while (1 << w) <= n
  w
end

def packed_bits(codes)
  # code width grows as the dictionary grows: 9 bits until code 511 is assigned
  total = 0
  dict_size = 256
  codes.each do
    total += bit_width(dict_size)
    dict_size += 1 if dict_size <= MAX_CODE
  end
  total
end

SAMPLE_TEXTS = [
  "TOBEORNOTTOBEORTOBEORNOT",
  "abababababababababababab",
  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "the rain in spain stays mainly in the plain; the rain in spain stays mainly in the plain",
  "xyz"
]

SAMPLE_TEXTS.each do |text|
  codes = compress(text)
  back = decompress(codes)
  bits = packed_bits(codes)
  raw_bits = text.size * 8
  shown = codes.size > 12 ? codes.take(12).join(" ") + " ..." : codes.join(" ")
  puts text
  puts "  codes(#{codes.size}): #{shown}"
  puts format("  %d -> %d bits (%.1f%%) roundtrip=%s", raw_bits, bits, 100.0 * bits / raw_bits, back == text)
  high = codes.max
  puts "  highest code: #{high}" if high
end

long = "ab" * 600 + "c"
codes = compress(long)
puts "long input: #{long.size} chars, #{codes.size} codes, max #{codes.max}, ok=#{decompress(codes) == long}"

begin
  decompress([65, 66, 300])
rescue ArgumentError => e
  puts "corrupt stream: #{e.message}"
end
