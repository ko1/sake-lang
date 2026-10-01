# Protocol-buffers style wire format: LEB128 varints, zigzag signed ints, fixed32 and
# length-delimited fields. Encodes a few records, then decodes them by field number.

class Field
  attr_reader :number, :wire, :value

  def initialize(number, wire, value)
    @number = number
    @wire = wire
    @value = value
  end
end

class WireError < StandardError
  attr_reader :offset

  def initialize(message, offset)
    super(message)
    @offset = offset
  end
end

def varint(n)
  out = []
  while n >= 0x80
    out << ((n & 0x7F) | 0x80)
    n >>= 7
  end
  out << n
end

def zigzag(n) = n >= 0 ? n * 2 : -n * 2 - 1
def unzigzag(z) = z.even? ? z / 2 : -(z + 1) / 2

def key(number, wire) = varint((number << 3) | wire)

def encode_field(f)
  case f.wire
  in 0
    key(f.number, 0) + varint(f.value)
  in 5
    key(f.number, 5) + (0...4).map { |i| (f.value >> (8 * i)) & 0xFF }
  in 2
    data = f.value.bytes
    key(f.number, 2) + varint(data.size) + data
  end
end

def read_varint(bytes, pos)
  result = 0
  shift = 0
  loop do
    b = bytes[pos]
    raise WireError.new("truncated varint", pos) if b.nil?
    result |= (b & 0x7F) << shift
    pos += 1
    shift += 7
    break if b < 0x80
  end
  [result, pos]
end

def decode(bytes)
  fields = []
  pos = 0
  while pos < bytes.size
    k, pos = read_varint(bytes, pos)
    number = k >> 3
    wire = k & 7
    case wire
    when 0
      v, pos = read_varint(bytes, pos)
      fields << Field.new(number, 0, v)
    when 5
      raise WireError.new("truncated fixed32", pos) if pos + 4 > bytes.size
      v = (0...4).sum { |i| bytes[pos + i] << (8 * i) }
      pos += 4
      fields << Field.new(number, 5, v)
    when 2
      len, pos = read_varint(bytes, pos)
      raise WireError.new("length #{len} past end", pos) if pos + len > bytes.size
      s = bytes[pos, len].map(&:chr).join
      pos += len
      fields << Field.new(number, 2, s)
    else
      raise WireError.new("unsupported wire type #{wire}", pos)
    end
  end
  fields
end

def person(id, name, delta, score)
  [Field.new(1, 0, id), Field.new(2, 2, name), Field.new(3, 0, zigzag(delta)), Field.new(4, 5, score)]
end

def hex(bytes) = bytes.map { |b| format("%02x", b) }.join(" ")

puts "== varints =="
[0, 1, 127, 128, 300, 16384, 2147483647].each do |n|
  enc = varint(n)
  back, used = read_varint(enc, 0)
  puts format("%10d -> %-16s back=%d (%d bytes)", n, hex(enc), back, used)
end
puts "zigzag: #{[0, -1, 1, -2, 2, -64, 64].map { |n| "#{n}=>#{zigzag(n)}" }.join(" ")}"

puts "== records =="
records = [person(150, "Ada", -3, 1000), person(7, "Grace Hopper", 42, 65535),
           person(123456, "", 0, 4294967295)]
records.each do |rec|
  bytes = rec.flat_map { |f| encode_field(f) }
  puts hex(bytes)
  by_number = decode(bytes).to_h { |f| [f.number, f.value] }
  delta = by_number[3]
  delta_s = delta.is_a?(Integer) ? unzigzag(delta).to_s : "?"
  puts "  id=#{by_number[1]} name=#{by_number[2].inspect} delta=#{delta_s} score=#{by_number[4]} (#{bytes.size} bytes)"
end

puts "== damaged =="
[[0x08, 0x96], [0x12, 0x05, 0x41, 0x42], [0x1b, 0x00], [0x25, 0x01, 0x02]].each do |bytes|
  fs = decode(bytes)
  puts "#{hex(bytes)}: #{fs.size} fields"
rescue WireError => e
  puts "#{hex(bytes)}: #{e.message} (at #{e.offset})"
end
