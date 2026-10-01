# xxd-style hex dump of a byte buffer, the reverse operation (parsing a dump back into
# bytes), and a byte-level comparison of two buffers.

def printable(b) = b >= 32 && b < 127 ? b.chr : "."

def dump_lines(bytes, width)
  bytes.each_slice(width).with_index.map do |row, i|
    hex = row.each_slice(2).map { |pair| pair.map { |b| format("%02x", b) }.join }.join(" ")
    full = width / 2 * 5 - 1
    ascii = row.map { |b| printable(b) }.join
    format("%08x: %s  %s", i * width, hex.ljust(full), ascii)
  end
end

def parse_dump(lines)
  bytes = []
  expected = 0
  lines.each do |line|
    m = line.match(/\A([0-9a-f]{8}): ((?:[0-9a-f]{2,4} ?)+)/)
    raise ArgumentError, "unparseable line: #{line}" if !m    
    offset = m[1].hex
    raise ArgumentError, format("offset %x, expected %x", offset, expected) if offset != expected
    m[2].strip.split(" ").each do |group|
      group.scan(/../) { |h| bytes << h.hex }
    end
    expected = bytes.size
  end
  bytes
end

def compare(a, b)
  n = [a.size, b.size].max
  (0...n).filter_map { |i| [i, a[i], b[i]] if a[i] != b[i] }
end

def show(v) = !v     ? "--" : format("%02x", v)

text = "Sake-lang\x00\x01\x02 dumps bytes: \x7f\xff\xfe and tabs\tand\nnewlines.\r\n"
bytes = text.bytes
lines = dump_lines(bytes, 16)
lines.each { |l| puts l }

back = parse_dump(lines)
puts "parsed back #{back.size} bytes, identical=#{back == bytes}"

puts "-- 8 wide --"
dump_lines(bytes.take(20), 8).each { |l| puts l }

puts "-- compare --"
patched = bytes.dup
patched[0] = 0x73
patched[12] = 0x41
patched.push(0x00, 0x2a)
diffs = compare(bytes, patched)
diffs.each do |i, x, y|
  puts format("  @%04x  %s -> %s", i, show(x), show(y))
end
puts "#{diffs.size} differences"

puts "-- bad dumps --"
[
  ["00000000: 4142 4344  ABCD", "00000010: 4546  EF"],
  ["00000000: 4142  AB", "garbage"]
].each do |dump|
  parse_dump(dump)
  puts "ok"
rescue ArgumentError => e
  puts "error: #{e.message}"
end
