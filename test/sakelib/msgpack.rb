require "msgpack"

# Packs a value, prints the bytes, and unpacks them again.
def round_trip(v)
  s = MessagePack.pack(v)
  p([s, s.encoding.to_s, MessagePack.unpack(s)])
end

# scalars and the shortest integer forms
round_trip(nil)
round_trip(true)
round_trip(false)
[0, 1, 127, 128, 255, 256, 65535, 65536, 4294967295, 4294967296, 18446744073709551615,
 -1, -32, -33, -128, -129, -32768, -32769, -2147483648, -2147483649, -9223372036854775808].each do |n|
  p([n, MessagePack.pack(n)])
end
round_trip(1.5)
round_trip(-0.0)
round_trip(1e100)

# strings: UTF-8 is str, ASCII-8BIT is bin; Symbols are packed as str
round_trip("")
round_trip("hello")
round_trip("日本語")
round_trip("a" * 31)
round_trip("a" * 32)
round_trip("a" * 256)
round_trip("\xFF\x00".b)
round_trip(:sym)
p(MessagePack.pack("a" * 40).bytesize)

# containers
round_trip([])
round_trip([1, [2, [3]], {"k" => "v"}])
round_trip({"a" => 1, "b" => [true, nil], "c" => {"d" => 1.25}})
round_trip({1 => "int key", nil => "nil key"})
round_trip(Array.new(16) { |i| i })
p(MessagePack.pack(Array.new(16) { |i| i }).bytesize)
p(MessagePack.pack(Hash[(0...16).map { |i| [i, i] }])[0, 3])
p(MessagePack.pack({a: 1, b: :c}))
p(MessagePack.unpack(MessagePack.pack({"a" => {"b" => 1}}), symbolize_keys: true))

# to_msgpack on core types, and dump/load
p("abc".to_msgpack)
p([1, 2].to_msgpack)
p({"x" => 1}.to_msgpack)
p(42.to_msgpack)
p(MessagePack.load(MessagePack.dump([1, "two", 3.0])))

# Packer: write calls chain; headers for hand-built containers
pk = MessagePack::Packer.new
pk.write_array_header(3).write(1).write_string("two").write_nil
p(pk.to_s)
p(pk.size)
p(pk.empty?)
pk.reset
p(pk.empty?)
pk.write_map_header(1).write_symbol(:k).write_float32(1.5)
p(pk.to_s)
p(MessagePack.unpack(pk.to_s))
pk = MessagePack::Packer.new
pk.write_true.write_false.write_int(-1).write_bin("\x01\x02").write_hash({"a" => [1]})
p(pk.to_s)
p(MessagePack::Packer.new(nil, compatibility_mode: true).write("a" * 40).to_s.bytesize)
p(MessagePack::Packer.new(nil, compatibility_mode: true).write("\x01".b).to_s)

# Unpacker: streaming with partial input
u = MessagePack::Unpacker.new
u.feed("\x93\x01")
u.each { |obj| p(obj) }
u.feed("\x02\x03\xA1a\xC3")
u.each { |obj| p(obj) }
p(u.buffer.size)
u.feed_each(MessagePack.pack("x") + MessagePack.pack({"k" => nil})) { |obj| p(obj) }
u.feed("\x01\x02")
p(u.read)
p(u.read)
begin
  u.read
rescue EOFError => e
  puts("EOFError: #{e.message}")
end
u.feed("\x92\x01\x02")
p(u.read_array_header)
p(u.read)
p(u.read)
u.feed("\x81\xA1k\xC0\xC0\x05")
p(u.read_map_header)
p(u.read)
p(u.skip_nil)
p(u.skip_nil)
p(u.skip_nil)
p(u.read)
u.feed("\x01")
begin
  u.read_map_header
rescue MessagePack::UnexpectedTypeError => e
  puts("UnexpectedTypeError: #{e.message}")
end
u = MessagePack::Unpacker.new(nil, symbolize_keys: true)
u.feed(MessagePack.pack({"a" => 1}))
p(u.read)

# ext types: ExtensionValue round trips with allow_unknown_ext
[1, 2, 3, 4, 8, 16, 17, 300].each do |n|
  s = MessagePack.pack(MessagePack::ExtensionValue.new(5, "x" * n))
  e = MessagePack.unpack(s, allow_unknown_ext: true)
  p([n, s[0, 4], e.type, e.payload.bytesize, e.payload.encoding.to_s])
end
p(MessagePack::Packer.new.write_ext(-3, "ab").to_s)
p(MessagePack::ExtensionValue.new(1, "a") == MessagePack::ExtensionValue.new(1, "a"))

# Timestamp's ext payload (type -1): 32, 64 and 96 bit forms
[[0, 0], [1, 0], [4294967295, 0], [4294967296, 0], [1, 500], [17179869183, 999999999], [17179869184, 1], [-1, 0]].each do |sec, nsec|
  data = MessagePack::Timestamp.to_msgpack_ext(sec, nsec)
  t = MessagePack::Timestamp.from_msgpack_ext(data)
  p([sec, nsec, data.bytesize, t.sec, t.nsec, t == MessagePack::Timestamp.new(sec, nsec)])
end
p(MessagePack::Timestamp.new(5, 6).to_msgpack_ext)
p(MessagePack::Timestamp.new(5, 6) == MessagePack::Timestamp.new(5, 7))

# errors
def try_unpack(s, options = {})
  p(MessagePack.unpack(s, options))
rescue EOFError => e
  puts("EOFError: #{e.message}")
rescue MessagePack::MalformedFormatError => e
  puts("MalformedFormatError: #{e.message}")
rescue MessagePack::StackError => e
  puts("StackError: #{e.message}")
rescue MessagePack::UnknownExtTypeError => e
  puts("UnknownExtTypeError: #{e.message}")
end
try_unpack("")
try_unpack("\x92\x01")
try_unpack("\xA5abc")
try_unpack("\xC1")
try_unpack("\x01\x02\x03")
try_unpack("\xD4\x01\x02")
try_unpack("\x91" * 128 + "\x01")
try_unpack("\x91" * 129 + "\x01")
try_unpack("\x81" * 129 + "\x01")
begin
  MessagePack.pack(2**64)
rescue RangeError => e
  puts("RangeError: #{e.message}")
end
begin
  MessagePack.pack(-2**63 - 1)
rescue RangeError => e
  puts("RangeError: #{e.message}")
end
begin
  MessagePack::Timestamp.from_msgpack_ext("abc")
rescue MessagePack::MalformedFormatError => e
  puts("MalformedFormatError: #{e.message}")
end
