require "websocket"

# the random key and accept lines are replaced so that the output is reproducible
def hide(s) = s.gsub(/^(Sec-WebSocket-(Key|Accept)): \S+/, "\\1: <...>")
def hex(s) = s.unpack1("H*")

# client handshake from a URL
client = WebSocket::Handshake::Client.new(url: "ws://example.com:8080/chat?room=1", origin: "http://example.com")
p [client.host, client.port, client.path, client.query, client.secure, client.version, client.uri, client.state]
puts hide(client.to_s).inspect
p client.should_respond?

# the server reads the request
server = WebSocket::Handshake::Server.new
server << client.to_s
p [server.state, server.finished?, server.valid?, server.version, server.path, server.query, server.host, server.port, server.uri]
p server.headers["sec-websocket-version"]
puts hide(server.to_s).inspect
p server.should_respond?

# the client checks the response; bytes after the header are the leftovers
client << server.to_s + "  leftover data\n"
p [client.state, client.valid?, client.error]
p client.leftovers

# the example of RFC 6455 1.3: a known key gives a known accept
server = WebSocket::Handshake::Server.new
server << "GET /chat HTTP/1.1\r\nHost: server.example.com\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n" \
          "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nOrigin: http://example.com\r\n" \
          "Sec-WebSocket-Protocol: chat, superchat\r\nSec-WebSocket-Version: 13\r\n\r\n"
p server.valid?
puts server.to_s.inspect

# a request in two pieces: unfinished until the empty line
server = WebSocket::Handshake::Server.new(protocols: ["superchat"])
server << "GET /x HTTP/1.1\r\nHost: localhost:9000\r\n"
p [server.state, server.finished?, server.valid?]
server << "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Protocol: chat\r\nSec-WebSocket-Protocol: superchat\r\nSec-WebSocket-Version: 8\r\n\r\n"
p [server.state, server.valid?, server.version, server.host, server.port, server.uri]
p server.headers["sec-websocket-protocol"]
puts server.to_s.inspect

# subprotocols, wss, extra headers, the older Sec-WebSocket-Origin of drafts before 11
client = WebSocket::Handshake::Client.new(url: "wss://example.com/", protocols: ["chat", "superchat"], headers: {"X-Token" => "abc"}, origin: "http://o.example", version: 8)
p [client.secure, client.port, client.uri]
puts hide(client.to_s).inspect
server = WebSocket::Handshake::Server.new(protocols: ["superchat"], secure: true)
server << client.to_s
puts hide(server.to_s).inspect
client << server.to_s
p [client.valid?, client.error]
client = WebSocket::Handshake::Client.new(host: "example.com", path: "/p", protocols: ["mqtt"])
server = WebSocket::Handshake::Server.new(protocols: ["chat"])
server << client.to_s
client << server.to_s
p [client.uri, client.valid?, client.error, client.state]

# handshake errors: the error is kept as a Symbol
client = WebSocket::Handshake::Client.new(path: "/nohost")
p [client.state, client.error, client.to_s]
client = WebSocket::Handshake::Client.new(url: "ws://a.example/", version: 99)
p [client.state, client.error]
client = WebSocket::Handshake::Client.new(url: "ws://a.example/")
client << "HTTP/1.1 200 OK\r\n\r\n"
p [client.state, client.error, client.valid?]
client = WebSocket::Handshake::Client.new(url: "ws://a.example/")
client << "HTTP/1.1 101 Switching Protocols\r\nSec-WebSocket-Accept: wrong\r\n\r\n"
p [client.state, client.valid?, client.error]
client = WebSocket::Handshake::Client.new(url: "ws://a.example/")
client << "garbage\r\n\r\n"
p [client.state, client.error]
server = WebSocket::Handshake::Server.new
server << "POST /chat HTTP/1.1\r\nSec-WebSocket-Version: 13\r\n\r\n"
p [server.state, server.error, server.valid?, server.to_s]
server = WebSocket::Handshake::Server.new
server << "GET /chat HTTP/1.1\r\nSec-WebSocket-Version: 13\r\n\r\n"
p [server.state, server.valid?, server.error]

# from a Rack env
server = WebSocket::Handshake::Server.new
server.from_rack({"HTTP_HOST" => "example.org:81", "HTTP_SEC_WEBSOCKET_KEY" => "dGhlIHNhbXBsZSBub25jZQ==", "HTTP_SEC_WEBSOCKET_VERSION" => "13", "REQUEST_PATH" => "/rack", "QUERY_STRING" => "a=b"})
p [server.state, server.valid?, server.version, server.path, server.query, server.host, server.port, server.uri]

# outgoing server frames (unmasked)
[[:text, "Hello"], [:binary, "\x00\xff".b], [:ping, "p"], [:pong, ""], [:text, "é"]].each do |type, data|
  frame = WebSocket::Frame::Outgoing::Server.new(version: 13, data: data, type: type)
  puts "#{type}: #{hex(frame.to_s)} #{frame.supported?} #{frame.require_sending?}"
end
frame = WebSocket::Frame::Outgoing::Server.new(version: 13, data: "bye", type: :close, code: 1001)
puts hex(frame.to_s)
frame = WebSocket::Frame::Outgoing::Server.new(version: 13, type: :close)
puts hex(frame.to_s)
frame = WebSocket::Frame::Outgoing::Server.new(version: 13, data: "x", type: :close, code: 999)
frame.to_s
p [frame.error, frame.error?, frame.require_sending?]
frame = WebSocket::Frame::Outgoing::Server.new(version: 13, data: "x", type: :continuation)
frame.to_s
p [frame.error, frame.supported?]

# the length takes 1, 3 or 9 bytes
[125, 126, 65535, 65536].each do |n|
  s = WebSocket::Frame::Outgoing::Server.new(version: 13, data: "a" * n, type: :binary).to_s
  puts "#{n}: #{s.bytesize} #{hex(s[0, 10])}"
end

# older drafts: other opcodes, and no FIN bit before draft 04
[3, 4, 5, 7].each do |version|
  s = WebSocket::Frame::Outgoing::Server.new(version: version, data: "a", type: :text).to_s
  c = WebSocket::Frame::Outgoing::Server.new(version: version, data: "", type: :close).to_s
  puts "#{version}: #{hex(s)} #{hex(c)}"
end
frame = WebSocket::Frame::Outgoing::Server.new(version: 99, data: "x", type: :text)
p frame.error

# a client masks its frames; the server unmasks them
outgoing = WebSocket::Frame::Outgoing::Client.new(version: 13, data: "Hello, server", type: :text)
s = outgoing.to_s
p [s.bytesize, s.getbyte(0), s.getbyte(1) & 0x80, s.getbyte(1) & 0x7f]
incoming = WebSocket::Frame::Incoming::Server.new(version: 13)
incoming << s
frame = incoming.next
p [frame.type, frame.data, frame.decoded?, frame.version]
p incoming.next

# frames arriving byte by byte, and two frames in one buffer
incoming = WebSocket::Frame::Incoming::Client.new(version: 13)
"\x81\x05Hello".b.each_char do |c|
  incoming << c
  frame = incoming.next
  p frame && [frame.type, frame.data]
end
incoming << "\x89\x01!\x82\x02\x01\x02".b
frame = incoming.next
p [frame.type, frame.data]
frame = incoming.next
p [frame.type, hex(frame.data)]

# a fragmented message: text without FIN, then continuations
incoming = WebSocket::Frame::Incoming::Client.new(version: 13)
incoming << "\x01\x03Hel".b + "\x00\x01l".b + "\x80\x01o".b
frame = incoming.next
p [frame.type, frame.data]

# a close frame carries a code
incoming = WebSocket::Frame::Incoming::Client.new(version: 13)
incoming << WebSocket::Frame::Outgoing::Server.new(version: 13, data: "going away", type: :close, code: 1001).to_s
frame = incoming.next
p [frame.type, frame.code, frame.data]

# a long frame
incoming = WebSocket::Frame::Incoming::Client.new(version: 13)
incoming << WebSocket::Frame::Outgoing::Server.new(version: 13, data: "z" * 70000, type: :binary).to_s
frame = incoming.next
p [frame.type, frame.data.bytesize]

# malformed frames: next gives nil and keeps the error
bad = ["\xf1\x00".b, "\x83\x00".b, "\x81\x02\xff\xfe".b, "\x88\x02\x03\xe7".b, "\x09\x00".b, "\x80\x01a".b, "\x89\x7e\x00\x80".b, "\x01\x01a\x81\x01b".b]
bad.each do |bytes|
  incoming = WebSocket::Frame::Incoming::Client.new(version: 13)
  incoming << bytes
  frame = incoming.next
  p [hex(bytes), frame, incoming.error, incoming.error?]
end
WebSocket.max_frame_size = 10
incoming = WebSocket::Frame::Incoming::Client.new(version: 13)
incoming << ("\x82\x0b".b + "a" * 11)
p [incoming.next, incoming.error, WebSocket.max_frame_size]
WebSocket.max_frame_size = 20 * 1024 * 1024

# should_raise: the error is raised instead
WebSocket.should_raise = true
incoming = WebSocket::Frame::Incoming::Client.new(version: 13)
incoming << "\x83\x00".b
begin
  incoming.next
rescue WebSocket::Error::Frame::UnknownOpcode => e
  puts "error: #{e.message}"
end
begin
  WebSocket::Handshake::Client.new(path: "/")
rescue WebSocket::Error::Handshake::NoHostProvided => e
  puts "error: #{e.message}"
end
WebSocket.should_raise = false
p WebSocket.should_raise
