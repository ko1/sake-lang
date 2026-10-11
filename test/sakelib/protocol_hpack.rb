require "protocol/hpack"

def hex(s) = s.unpack1("H*")

def show_table(ctx)
  puts "table size=#{ctx.table_size} used=#{ctx.compute_current_table_size} entries=#{ctx.table.size}"
  ctx.table.each_with_index { |(k, v), i| puts "  [#{i + 62}] #{k}: #{v}" }
end

# integers (RFC 7541 C.1): 10 on 5 bits, 1337 on 5 bits, 42 on 8 bits
[[10, 5], [1337, 5], [42, 8], [31, 5], [0, 7]].each do |value, bits|
  buffer = String.new.b
  compressor = Protocol::HPACK::Compressor.new(buffer)
  compressor.write_integer(value, bits)
  decompressor = Protocol::HPACK::Decompressor.new(buffer)
  puts "#{value}/#{bits}: #{hex(buffer)} -> #{decompressor.read_integer(bits)}"
end

# Huffman coding (RFC 7541 C.4.1)
encoded = Protocol::HPACK::Huffman.encode("www.example.com")
puts hex(encoded)
p Protocol::HPACK::Huffman.decode(encoded)
["", "a", "no-cache", "custom-key", "Mon, 21 Oct 2013 20:13:21 GMT", "\x00\xff~"].each do |s|
  e = Protocol::HPACK::Huffman.encode(s.b)
  puts "#{s.bytesize} -> #{e.bytesize}: #{hex(e)} #{Protocol::HPACK::Huffman.decode(e) == s.b}"
end

# malformed Huffman input
["\xff\xff\xff\xff".b, "\x00".b, "\xfe".b].each do |bad|
  begin
    p Protocol::HPACK::Huffman.decode(bad)
  rescue Protocol::HPACK::CompressionError => e
    puts "error: #{e.message}"
  end
end

# requests without Huffman (RFC 7541 C.3), one context across three header lists
requests = [
  [[":method", "GET"], [":scheme", "http"], [":path", "/"], [":authority", "www.example.com"]],
  [[":method", "GET"], [":scheme", "http"], [":path", "/"], [":authority", "www.example.com"], ["cache-control", "no-cache"]],
  [[":method", "GET"], [":scheme", "https"], [":path", "/index.html"], [":authority", "www.example.com"], ["custom-key", "custom-value"]],
]
compressor_context = Protocol::HPACK::Context.new(nil, huffman: :never)
decompressor_context = Protocol::HPACK::Context.new
requests.each do |headers|
  buffer = String.new.b
  compressor = Protocol::HPACK::Compressor.new(buffer, compressor_context)
  puts hex(compressor.encode(headers))
  decompressor = Protocol::HPACK::Decompressor.new(buffer, decompressor_context)
  p decompressor.decode
end
show_table(decompressor_context)

# the same requests with Huffman (RFC 7541 C.4)
compressor_context = Protocol::HPACK::Context.new(nil, huffman: :always)
decompressor_context = Protocol::HPACK::Context.new
requests.each do |headers|
  buffer = String.new.b
  puts hex(Protocol::HPACK::Compressor.new(buffer, compressor_context).encode(headers))
  p Protocol::HPACK::Decompressor.new(buffer, decompressor_context).decode == headers
end
show_table(decompressor_context)

# responses with a 256-byte table: entries are evicted (RFC 7541 C.5)
responses = [
  [[":status", "302"], ["cache-control", "private"], ["date", "Mon, 21 Oct 2013 20:13:21 GMT"], ["location", "https://www.example.com"]],
  [[":status", "307"], ["cache-control", "private"], ["date", "Mon, 21 Oct 2013 20:13:21 GMT"], ["location", "https://www.example.com"]],
  [[":status", "200"], ["cache-control", "private"], ["date", "Mon, 21 Oct 2013 20:13:22 GMT"], ["location", "https://www.example.com"], ["content-encoding", "gzip"], ["set-cookie", "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1"]],
]
compressor_context = Protocol::HPACK::Context.new(nil, huffman: :shorter, table_size: 256)
decompressor_context = Protocol::HPACK::Context.new(nil, table_size: 256)
responses.each do |headers|
  buffer = String.new.b
  puts hex(Protocol::HPACK::Compressor.new(buffer, compressor_context).encode(headers))
  p Protocol::HPACK::Decompressor.new(buffer, decompressor_context).decode.size
  show_table(decompressor_context)
end

# index modes: :never and :static never touch the dynamic table
[:never, :static, :all].each do |mode|
  context = Protocol::HPACK::Context.new(nil, huffman: :never, index: mode)
  commands = context.encode([[":method", "GET"], ["x-a", "1"], ["x-a", "1"], ["host", "h"]])
  puts "#{mode}: #{commands.map { |c| "#{c[:type]}:#{c[:name]}" }.join(" ")} table=#{context.table.size}"
end

# commands read back from a buffer
buffer = String.new.b
compressor = Protocol::HPACK::Compressor.new(buffer, Protocol::HPACK::Context.new(nil, huffman: :never, index: :never))
compressor.encode([["x-key", "v"]])
decompressor = Protocol::HPACK::Decompressor.new(buffer)
command = decompressor.read_header
p [command[:type], command[:name], command[:value], decompressor.offset, decompressor.end?]

# a table size update before the headers; a limit on the decoder
buffer = String.new.b
compressor = Protocol::HPACK::Compressor.new(buffer, Protocol::HPACK::Context.new, table_size_limit: 100)
puts hex(compressor.encode([["x-long-header", "v" * 80]]))
p compressor.context.table.size
decompressor = Protocol::HPACK::Decompressor.new(buffer, Protocol::HPACK::Context.new, table_size_limit: 100)
p decompressor.decode
p decompressor.context.table_size
begin
  Protocol::HPACK::Decompressor.new(buffer.dup, Protocol::HPACK::Context.new, table_size_limit: 50).decode
rescue Protocol::HPACK::CompressionError => e
  puts "error: #{e.message}"
end

# shrinking the table evicts entries
context = Protocol::HPACK::Context.new
context.encode([["a", "1"], ["b", "2"], ["c", "3"]])
show_table(context)
command = context.change_table_size(70)
p [command[:type], command[:value]]
show_table(context)

# dereference: static, dynamic, too large
p context.dereference(1)
p context.dereference(61)
begin
  context.dereference(70)
rescue Protocol::HPACK::CompressionError => e
  puts "error: #{e.message}"
end

# malformed buffers
["\x80".b, "\xff\x00".b, "\x20".b, "\x00\x05ab".b].each do |bad|
  begin
    p Protocol::HPACK::Decompressor.new(bad).decode
  rescue Protocol::HPACK::CompressionError => e
    puts "error: #{e.message}"
  end
end

# UTF-8 values pass through as bytes
buffer = String.new.b
Protocol::HPACK::Compressor.new(buffer).encode([["x-name", "café ☕"]])
pair = Protocol::HPACK::Decompressor.new(buffer).decode.first
p pair
p pair[1].encoding.to_s if pair
