class DecodeError < StandardError
  attr_reader :offset

  def initialize(message, offset)
    super(message)
    @offset = offset
  end
end

def rle_encode(s)
  out = +""
  chars = s.chars
  i = 0
  while i < chars.size
    c = chars[i]
    run = 1
    run += 1 while i + run < chars.size && chars[i + run] == c && run < 99
    out << (run >= 3 || c.match?(/\d/) ? format("%02d%s", run, c) : c * run)
    i += run
  end
  out
end

def rle_decode(s)
  out = +""
  chars = s.chars
  i = 0
  while i < chars.size
    c = chars[i]
    if c.match?(/\d/)
      digits = +""
      while i < chars.size && digits.size < 2
        digits << chars[i]
        i += 1
      end
      ch = chars[i]
      raise DecodeError.new("count #{digits} without a character", i) if ch.nil?
      out << ch * digits.to_i
    else
      out << c
    end
    i += 1
  end
  out
end

def bwt(s)
  text = s + "$"
  rotations = (0...text.size).map { |i| text[i..] + text[0...i] }
  rotations.sort.map { |r| r[-1] }.join
end

def inverse_bwt(last)
  n = last.size
  col = last.chars
  table = Array.new(n, "")
  n.times do
    table = (0...n).map { |i| col[i] + table[i] }.sort
  end
  row = table.find { |r| r.end_with?("$") }
  raise DecodeError.new("no end marker", 0) unless row
  row[0...-1]
end

def move_to_front(s)
  alphabet = s.chars.uniq.sort
  s.each_char.map do |c|
    idx = alphabet.index(c)
    alphabet.delete_at(idx)
    alphabet.unshift(c)
    idx
  end
end

def ratio(a, b) = format("%.0f%%", 100.0 * b.size / a.size)

samples = ["banana_bandana", "aaaaaaaaaabbbbbbbbbbcccccccccc", "abracadabra abracadabra abracadabra",
           "tick tock tick tock tick tock", "ab3cd"]
samples.each do |s|
  direct = rle_encode(s)
  b = bwt(s)
  via_bwt = rle_encode(b)
  back = inverse_bwt(rle_decode(via_bwt))
  mtf = move_to_front(b)
  zeros = mtf.count(0)
  puts "text:     #{s}"
  puts "  rle:    #{direct} (#{ratio(s, direct)})"
  puts "  bwt:    #{b}"
  puts "  bwt+rle #{via_bwt} (#{ratio(s, via_bwt)})"
  puts "  mtf:    #{mtf.join(" ")}  zeros=#{zeros}/#{mtf.size}"
  puts "  round trip: #{back == s ? "ok" : "MISMATCH " + back}"
end

["03a02b", "12x", "4", "04"].each do |enc|
  puts "decode #{enc.inspect} -> #{rle_decode(enc).inspect}"
rescue DecodeError => e
  puts "decode #{enc.inspect} failed at #{e.offset}: #{e.message}"
end
