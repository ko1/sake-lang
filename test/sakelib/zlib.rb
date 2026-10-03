require "zlib"

inputs = ["", "a", "abc", "hello world", "日本語のテキスト", "héllo ✓ 😀", "xyz" * 100,
          "q" * 6000, [0, 255, 128, 1, 127].pack("C*")]
inputs.each do |s|
  puts("#{s.bytesize} bytes: crc32 #{Zlib.crc32(s)} adler32 #{Zlib.adler32(s)}")
end

crc = 0
adler = 1
["The quick ", "brown fox ", "", "jumps over the lazy dog"].each do |piece|
  crc = Zlib.crc32(piece, crc)
  adler = Zlib.adler32(piece, adler)
end
p crc
p Zlib.crc32("The quick brown fox jumps over the lazy dog")
p adler
p Zlib.adler32("The quick brown fox jumps over the lazy dog")
p Zlib.crc32("", 12345)
p Zlib.adler32("abc", 0)
p Zlib.crc32("abc", 0xffffffff)

a = "hello, "
b = "日本語 world"
p Zlib.crc32_combine(Zlib.crc32(a), Zlib.crc32(b), b.bytesize)
p Zlib.crc32(a + b)
p Zlib.adler32_combine(Zlib.adler32(a), Zlib.adler32(b), b.bytesize)
p Zlib.adler32(a + b)
p Zlib.crc32_combine(Zlib.crc32(a), Zlib.crc32(""), 0)
p Zlib.adler32_combine(Zlib.adler32(a), Zlib.adler32(""), 0)

p Zlib.crc_table.size
p Zlib.crc_table.take(4)
p Zlib.crc_table.last

p Zlib.crc32
p Zlib.adler32
p Zlib.crc32(nil, 5)
p Zlib.adler32(nil, 5)
p Zlib.crc32("a", -1)
p Zlib.crc32("a", 2 ** 32 + 5)
