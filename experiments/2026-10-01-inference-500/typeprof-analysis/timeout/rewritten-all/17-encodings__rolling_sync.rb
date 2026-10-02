# rsync-style delta: Adler-32 and Fletcher-16 checksums, a rolling weak checksum over a
# sliding window, and a block-matching delta between an old and a new file.

class BlockSig
  attr_reader :index, :weak, :strong

  def initialize(index, weak, strong)
    @index = index
    @weak = weak
    @strong = strong
  end
end

def adler32(bytes)
  a = 1
  b = 0
  bytes.each do |x|
    a = (a + x) % 65521
    b = (b + a) % 65521
  end
  (b << 16) | a
end

def fletcher16(bytes)
  s1 = 0
  s2 = 0
  bytes.each do |x|
    s1 = (s1 + x) % 255
    s2 = (s2 + s1) % 255
  end
  (s2 << 8) | s1
end

# rsync's weak checksum: a = sum of bytes, b = weighted sum; both mod 2^16
def weak_parts(bytes)
  n = bytes.size
  a = bytes.sum
  b = bytes.each_with_index.sum { |e__0| x, i = e__0; (n - i) * x }
  [a & 0xFFFF, b & 0xFFFF]
end

def roll(a, b, out_byte, in_byte, n)
  a2 = (a - out_byte + in_byte) & 0xFFFF
  b2 = (b - n * out_byte + a2) & 0xFFFF
  [a2, b2]
end

def signatures(old, size)
  sigs = Hash.new { |h, k| h[k] = [] }
  old.each_slice(size).with_index do |block, index|
    a, b = weak_parts(block)
    weak = (b << 16) | a
    sigs[weak] << BlockSig.new(index, weak, adler32(block))
  end
  sigs
end

def delta(new_bytes, sigs, size)
  ops = []
  literal = []
  i = 0
  n = new_bytes.size
  a, b = weak_parts(new_bytes.take(size))
  while i + size <= n
    window = new_bytes[i...(i + size)]
    candidates = sigs.fetch((b << 16) | a, nil)
    strong = candidates ? adler32(window) : 0
    hit = candidates&.find { |s| s.strong == strong }
    if hit
      ops << [:literal, literal] unless literal.empty?
      literal = []
      ops << [:copy, hit.index]
      i += size
      a, b = weak_parts(new_bytes[i...(i + size)] || []) if i + size <= n
    else
      literal << new_bytes[i]
      a, b = roll(a, b, new_bytes[i], new_bytes[i + size] || 0, size) if i + size < n
      i += 1
    end
  end
  literal.concat(new_bytes[i...n] || [])
  ops << [:literal, literal] unless literal.empty?
  ops
end

def text_of(bytes) = bytes.map(&:chr).join

puts "adler32(Wikipedia)   = #{format("%08x", adler32("Wikipedia".bytes))}"
puts "fletcher16(abcde)    = #{fletcher16("abcde".bytes)}"
puts "fletcher16(abcdef)   = #{fletcher16("abcdef".bytes)}"

sample = "the rolling checksum slides one byte at a time".bytes
a, b = weak_parts(sample.take(8))
ok = true
(1..(sample.size - 8)).each do |i|
  a, b = roll(a, b, sample[i - 1], sample[i + 7], 8)
  ok = false if weak_parts(sample[i...(i + 8)]) != [a, b]
end
puts "rolling agrees with direct computation: #{ok}"

old_text = "The quick brown fox jumps over the lazy dog. Pack my box with five dozen jugs."
new_text = "The quick brown cat jumps over the lazy dog. Pack my box with five dozen liquor jugs!"
size = 8
sigs = signatures(old_text.bytes, size)
ops = delta(new_text.bytes, sigs, size)
copied = 0
sent = 0
ops.each do |kind, arg|
  case kind
  in :copy
    copied += size
    puts "  copy block #{arg}"
  in :literal
    sent += arg.size
    puts "  literal #{text_of(arg).inspect}"
  end
end
puts "new file #{new_text.size} bytes: #{copied} copied, #{sent} sent literally"

old_blocks = old_text.bytes.each_slice(size).to_a
rebuilt = ops.flat_map do |e__1| kind, arg = e__1;
  case kind
  in :copy then old_blocks.fetch(arg)
  in :literal then arg
  end
end
puts "rebuilt matches new file: #{text_of(rebuilt) == new_text}"
