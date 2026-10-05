# Run-length encoding for text ("3A2B") and for monochrome bitmap rows, with a decoder
# that reports malformed input.

class RleError < StandardError
  attr_reader :offset

  def initialize(message, offset)
    super(message)
    @offset = offset
  end
end

def runs(items)
  result = []
  items.each do |x|
    last = result.last
    if last && last.first == x
      last[1] += 1
    else
      result << [x, 1]
    end
  end
  result
end

def encode_text(s)
  runs(s.chars).map { |c, n| n == 1 ? c : "#{n}#{c}" }.join
end

def decode_text(s)
  out = +""
  count = +""
  s.chars.each_with_index do |c, i|
    if c.match?(/\d/)
      count << c
    else
      n = count.empty? ? 1 : count.to_i
      raise RleError.new("zero-length run", i) if n == 0
      out << c * n
      count = +""
    end
  end
  raise RleError.new("trailing count #{count}", s.size) unless count.empty?
  out
end

def encode_row(bits)
  # rows start with a white run (possibly 0), then alternate
  lengths = []
  current = 0
  len = 0
  bits.each do |b|
    if b == current
      len += 1
    else
      lengths << len
      current = b
      len = 1
    end
  end
  lengths << len
end

def decode_row(lengths)
  bits = []
  color = 0
  lengths.each do |n|
    n.times { bits << color }
    color = 1 - color
  end
  bits
end

BITMAP = [
  "................",
  "....######......",
  "...#......#.....",
  "..#..#..#..#....",
  "..#........#....",
  "..#..####..#....",
  "...#......#.....",
  "....######......"
]

puts "== text =="
["WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWWWWWWWWWWWWWWWWWWWWWWBWWWWWWWWWWWWWW",
 "abc", "aabcccccaaa", "", "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"].each do |s|
  enc = encode_text(s)
  dec = decode_text(enc)
  puts format("%3d -> %3d  %s  %s", s.size, enc.size, enc, dec == s ? "ok" : "FAIL")
end

puts "== bitmap =="
total_raw = 0
total_enc = 0
rows = BITMAP.map { |line| line.chars.map { |c| c == "#" ? 1 : 0 } }
rows.each_with_index do |bits, y|
  lengths = encode_row(bits)
  same = decode_row(lengths) == bits
  total_raw += bits.size
  total_enc += lengths.size
  puts format("row %d: %-24s %s", y, lengths.join(","), same ? "" : "MISMATCH")
end
puts format("raw %d pixels, %d run lengths, ratio %.2f", total_raw, total_enc,
            total_enc.fdiv(total_raw))

longest = rows.max_by { |bits| bits.count(1) }
puts "darkest row has #{longest.count(1)} dark pixels" if longest

puts "== errors =="
["3a0b", "12", "4x2y1"].each do |bad|
  puts "#{bad} -> #{decode_text(bad)}"
rescue RleError => e
  puts "#{bad} -> error at #{e.offset}: #{e.message}"
end
