# A serial-line frame parser: 0x7E sync, type, length, payload, XOR checksum.
# It resynchronises after garbage, rejects bad checksums, and decodes payloads by type
# into different record types.

class Temperature
  attr_reader :sensor, :centi

  def initialize(sensor, centi)
    @sensor = sensor
    @centi = centi
  end
end

class Position
  attr_reader :lat, :lon

  def initialize(lat, lon)
    @lat = lat
    @lon = lon
  end
end

class Note
  attr_reader :text

  def initialize(text)
    @text = text
  end
end

class Stats
  attr_accessor :frames, :bad_checksum, :skipped, :unknown

  def initialize(frames, bad_checksum, skipped, unknown)
    @frames = frames
    @bad_checksum = bad_checksum
    @skipped = skipped
    @unknown = unknown
  end

  def inspect = "#<struct Stats frames=#{frames}, bad_checksum=#{bad_checksum}, skipped=#{skipped}, unknown=#{unknown}>"
end

SYNC = 0x7E

def checksum(bytes) = bytes.reduce(0) { |acc, b| acc ^ b }

def frame(type, payload)
  body = [type, payload.size] + payload
  [SYNC] + body + [checksum(body)]
end

def s16(hi, lo)
  v = (hi << 8) | lo
  v >= 0x8000 ? v - 0x10000 : v
end

def s32(bytes, at)
  v = (bytes[at] << 24) | (bytes[at + 1] << 16) | (bytes[at + 2] << 8) | bytes[at + 3]
  v >= 0x80000000 ? v - 0x100000000 : v
end

def be16(v) = [(v >> 8) & 0xFF, v & 0xFF]
def be32(v) = [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF]

def decode_payload(type, p)
  case type
  in 1 then Temperature.new(p[0], s16(p[1], p[2]))
  in 2 then Position.new(s32(p, 0), s32(p, 4))
  in 3 then Note.new(p.map(&:chr).join)
  else nil
  end
end

def parse(stream, stats)
  messages = []
  i = 0
  n = stream.size
  while i < n
    if stream[i] != SYNC
      stats.skipped += 1
      i += 1
      next
    end
    break if i + 3 > n
    type = stream[i + 1]
    len = stream[i + 2]
    last = i + 3 + len
    break if last >= n
    body = stream[(i + 1)...last]
    if checksum(body) != stream[last]
      stats.bad_checksum += 1
      i += 1
      next
    end
    msg = decode_payload(type, stream[(i + 3)...last])
    if msg
      messages << msg
    else
      stats.unknown += 1
    end
    stats.frames += 1
    i = last + 1
  end
  messages
end

def describe(msg)
  case msg
  in Temperature
    c = msg.centi
    format("temp   sensor %d: %s%d.%02d C", msg.sensor, c < 0 ? "-" : "", c.abs / 100, c.abs % 100)
  in Position
    format("pos    %.5f, %.5f", msg.lat / 1.0e7, msg.lon / 1.0e7)
  in Note
    "note   #{msg.text.inspect}"
  end
end

stream = [0x00, 0xFF]
stream.concat(frame(1, [3] + be16(2150)))
stream.concat(frame(2, be32(356_812_362) + be32(0x100000000 - 1_223_456_789)))
stream.concat([0x13, 0x37])
stream.concat(frame(3, "door open".bytes))
bad = frame(1, [4] + be16(0x10000 - 1250))
bad[4] ^= 0x01
stream.concat(bad)
stream.concat(frame(1, [4] + be16(0x10000 - 1250)))
stream.concat(frame(9, [1, 2, 3]))
stream.concat(frame(3, "".bytes))
stream.concat(frame(3, "truncated".bytes).take(6))

puts "stream: #{stream.size} bytes"
stats = Stats.new(0, 0, 0, 0)
msgs = parse(stream, stats)
msgs.each { |m| puts describe(m) }
p stats

temps = msgs.grep(Temperature)
unless temps.empty?
  total = temps.sum(&:centi)
  puts format("average of %d readings: %.2f C", temps.size, total / 100.0 / temps.size)
end
