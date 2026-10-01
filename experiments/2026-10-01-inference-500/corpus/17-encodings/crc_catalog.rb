# Parameterised CRC engine (Rocksoft model) checked against the catalogue "check" values,
# plus a table-driven CRC-32 used to detect corruption in a list of frames.

def reflect(value, width)
  r = 0
  width.times do |i|
    r |= 1 << (width - 1 - i) if (value >> i) & 1 == 1
  end
  r
end

class CrcModel
  attr_reader :name, :width, :poly, :init, :refin, :refout, :xorout, :check

  def initialize(name, width, poly, init, refin, refout, xorout, check)
    @name = name
    @width = width
    @poly = poly
    @init = init
    @refin = refin
    @refout = refout
    @xorout = xorout
    @check = check
  end

  def mask = (1 << @width) - 1

  def compute(bytes)
    top = 1 << (@width - 1)
    crc = @init
    bytes.each do |b|
      b = reflect(b, 8) if @refin
      if @width >= 8
        crc ^= b << (@width - 8)
        8.times do
          crc = crc & top != 0 ? (crc << 1) ^ @poly : crc << 1
          crc &= mask
        end
      else
        8.times do |i|
          bit = (b >> (7 - i)) & 1
          fb = ((crc >> (@width - 1)) & 1) ^ bit
          crc = (crc << 1) & mask
          crc ^= @poly if fb == 1
        end
      end
    end
    crc = reflect(crc, @width) if @refout
    (crc ^ @xorout) & mask
  end

  def hex_digits = (@width + 3) / 4
end

CATALOGUE = [
  CrcModel.new("CRC-8", 8, 0x07, 0x00, false, false, 0x00, 0xF4),
  CrcModel.new("CRC-8/MAXIM", 8, 0x31, 0x00, true, true, 0x00, 0xA1),
  CrcModel.new("CRC-5/USB", 5, 0x05, 0x1F, true, true, 0x1F, 0x19),
  CrcModel.new("CRC-16/CCITT-FALSE", 16, 0x1021, 0xFFFF, false, false, 0x0000, 0x29B1),
  CrcModel.new("CRC-16/ARC", 16, 0x8005, 0x0000, true, true, 0x0000, 0xBB3D),
  CrcModel.new("CRC-16/XMODEM", 16, 0x1021, 0x0000, false, false, 0x0000, 0x31C3),
  CrcModel.new("CRC-32", 32, 0x04C11DB7, 0xFFFFFFFF, true, true, 0xFFFFFFFF, 0xCBF43926),
  CrcModel.new("CRC-32/BZIP2", 32, 0x04C11DB7, 0xFFFFFFFF, false, false, 0xFFFFFFFF, 0xFC891918)
]

def crc32_table
  (0...256).map do |n|
    c = n
    8.times { c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
    c
  end
end

def crc32_fast(table, bytes)
  crc = 0xFFFFFFFF
  bytes.each { |b| crc = table[(crc ^ b) & 0xFF] ^ (crc >> 8) }
  crc ^ 0xFFFFFFFF
end

check_input = "123456789".bytes
puts "model                 result     check      ok"
CATALOGUE.each do |m|
  got = m.compute(check_input)
  digits = m.hex_digits
  puts format("%-20s  %-10s %-10s %s", m.name,
              format("0x%0*X", digits, got), format("0x%0*X", digits, m.check),
              got == m.check ? "yes" : "NO")
end

table = crc32_table
puts format("table[1]=%08x table[128]=%08x table[255]=%08x", table[1], table[128], table[255])

frames = [
  ["hello world", 0x0D4A1185],
  ["The quick brown fox jumps over the lazy dog", 0x414FA339],
  ["frame-0003 payload", 0],
  ["corrupted paylaod", 0x12345678]
]
frames[2] = ["frame-0003 payload", crc32_fast(table, "frame-0003 payload".bytes)]

slow = CATALOGUE.find { |m| m.name == "CRC-32" }
good = 0
frames.each do |text, expected|
  bytes = text.bytes
  fast = crc32_fast(table, bytes)
  agree = slow ? slow.compute(bytes) == fast : false
  status = fast == expected ? "OK" : "BAD"
  good += 1 if status == "OK"
  puts format("%-45s %08x %s engines-agree=%s", text, fast, status, agree)
end
puts "#{good}/#{frames.size} frames intact"
