# Socket

Socket is the type of a TCP connection. Values come from `Socket.connect(host, port)` (plain), `Socket.connect_ssl(host, port)` (TLS), and, on the server side, `TCPServer.accept` ([TCPServer](TCPServer.md)). All are the same type `Socket` and are read and written with the same operations (Ruby's `TCPSocket` and `OpenSSL::SSL::SSLSocket`, see [Built-ins](../09-builtins.md)). The reading operations have the shape of `IO`'s (`gets`, `read`), but a Socket is not an `IO` and cannot be passed to `IO.puts` and the like.

A network failure (cannot connect, connection lost, name not resolved) is an `IOError` (Ruby's `Errno::ECONNREFUSED`, `SocketError`, `OpenSSL::SSL::SSLError`, and the like, all in one; see [Exceptions](../08-exceptions.md)). How long a read or write waits is set by `set_timeout`; past it, an `IOError`. The Strings that `gets` and `read` return are binary (encoding `ASCII-8BIT`); pass them through `String.force_encoding(s, "UTF-8")` to use them as text. There is no UDP and no Unix domain socket.

The only operators on Sockets are `==` and `!=` (equal for the same connection). The examples start a `TCPServer` on port 0 of `127.0.0.1` and connect from a Thread of the same program.

## connect

`Socket.connect(String, Integer, [Integer|Float|Rational])`

Connects by TCP to `port` of `host` (a name or an IP address) and returns a Socket. The third argument is how many seconds to wait for the connection; past it, an `IOError` (when omitted, the OS's default applies). A refused connection is an `IOError` too, and so is a name that cannot be resolved (Ruby's `Socket::ResolutionError`; the message is the resolver's, `getaddrinfo(3): Name or service not known` or the like).

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
client = Thread.new {
  s = Socket.connect("127.0.0.1", port, 5)
  Socket.write(s, "ping\n")
  reply = Socket.gets(s)
  Socket.close(s)
  reply
}
conn = TCPServer.accept(srv)
p(Socket.gets(conn))                # => "ping\n"
Socket.write(conn, "pong\n")
Socket.close(conn)
p(Thread.value(client))             # => "pong\n"
TCPServer.close(srv)
```

```ruby error
Socket.connect("127.0.0.1", 1)      # !> IOError: Socket.connect: Connection refused
```

```ruby error
Socket.connect("no-such-host.invalid", 80)   # !> IOError: Socket.connect: getaddrinfo
```

## connect_ssl

`Socket.connect_ssl(String, Integer, [Integer|Float|Rational])`

Connects by TCP to `port` of `host`, performs the TLS handshake over it, and returns a Socket. The peer's certificate is verified against the OS's trust store, and `host` is used for SNI and the host name check (Ruby's `OpenSSL::SSL::SSLSocket` with `VERIFY_PEER`). The third argument is how many seconds to wait for the TCP connection. A failed connection and a failed handshake (a peer that does not speak TLS, a certificate that cannot be verified) are both an `IOError`. `close` closes TLS and TCP. An example that reaches an outside host cannot run under the checker, so only its shape is shown:

```
s = Socket.connect_ssl("example.com", 443, 10)
Socket.write(s, "GET / HTTP/1.0\r\nHost: example.com\r\n\r\n")
p(Socket.gets(s))                   # "HTTP/1.0 200 OK\r\n" or the like
Socket.close(s)
```

Against a server that does not speak TLS the handshake is an `IOError`:

```ruby error
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
t = Thread.new { c = TCPServer.accept(srv); Socket.close(c) }
Socket.connect_ssl("127.0.0.1", port)   # !> IOError: Socket.connect_ssl:
```

## set_timeout

`Socket.set_timeout(x, Integer|Float|Rational|Nil)`

Sets how many seconds the following `gets`, `read`, and `write` wait, and returns the Socket (Ruby's `IO#timeout=`). Past the time, an `IOError` (`Blocking operation timed out!`). nil restores no limit (the default).

```ruby
srv = TCPServer.new("127.0.0.1", 0)
s = Socket.connect("127.0.0.1", TCPServer.port(srv))
p(Socket.set_timeout(s, 0.05) == s)   # => true
begin
  Socket.gets(s)
rescue IOError => e
  p(Exception.message(e))           # => "Blocking operation timed out!"
end
Socket.set_timeout(s, nil)
Socket.close(s)
TCPServer.close(srv)
```

## gets

`Socket.gets(x)`

The next line including its newline, or nil once the peer has closed its writing side (`close_write` or `close`) and the data is used up. The result is `String | nil`; `--strict` (level 2) reports using it unchecked as a `nil` problem. Past the `set_timeout` time, an `IOError`.

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
t = Thread.new {
  s = Socket.connect("127.0.0.1", port)
  Socket.write(s, "a\nb\n")
  Socket.close(s)
}
c = TCPServer.accept(srv)
while (line = Socket.gets(c))
  p(line)                           # => "a\n"
                                    # => "b\n"
end
p(Socket.gets(c))                   # => nil
Thread.join(t)
TCPServer.close(srv)
```

## read

`Socket.read(x, Integer)`

Reads exactly `n` bytes and returns them. It waits until `n` bytes have arrived; when the peer closes first it returns what is left, and nil when nothing is left (`String | nil`, level 2; with `n` 0 it is always `""`). A negative `n` is an `ArgumentError`. Unlike Ruby's `read` there is no form without a length (read to the end).

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
t = Thread.new {
  s = Socket.connect("127.0.0.1", port)
  Socket.write(s, "hello")
  Socket.close(s)
}
c = TCPServer.accept(srv)
p(Socket.read(c, 2))                # => "he"
p(Socket.read(c, 10))               # => "llo"
p(Socket.read(c, 10))               # => nil
p(Socket.read(c, 0))                # => ""
Thread.join(t)
TCPServer.close(srv)
```

```ruby error
srv = TCPServer.new("127.0.0.1", 0)
s = Socket.connect("127.0.0.1", TCPServer.port(srv))
Socket.read(s, -1)                  # !> ArgumentError: Socket.read: negative size -1
```

## write

`Socket.write(x, String)`

Sends the string and returns the number of bytes sent (an Integer). No newline is added. A closed Socket, or one after `close_write`, is an `IOError`.

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
t = Thread.new {
  s = Socket.connect("127.0.0.1", port)
  n = Socket.write(s, "日本\n")
  Socket.close(s)
  n
}
c = TCPServer.accept(srv)
got = Socket.gets(c)
if got
  p(String.encoding(got))           # => "ASCII-8BIT"
  p(String.force_encoding(got, "UTF-8"))   # => "日本\n"
end
p(Thread.value(t))                  # => 7
TCPServer.close(srv)
```

```ruby error
srv = TCPServer.new("127.0.0.1", 0)
s = Socket.connect("127.0.0.1", TCPServer.port(srv))
Socket.close(s)
Socket.write(s, "x")                # !> IOError: Socket.write: closed stream
```

## close_write

`Socket.close_write(x)`

Closes only the writing side and returns nil (a TCP half-close). The peer's `gets` and `read` get nil once the data is used up, while this side can still read the peer's reply. It is for protocols of the form "send everything, then wait for the answer". A `write` afterwards is an `IOError`.

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
client = Thread.new {
  s = Socket.connect("127.0.0.1", port)
  Socket.write(s, "1 2 3")
  Socket.close_write(s)
  reply = Socket.gets(s)
  Socket.close(s)
  reply
}
c = TCPServer.accept(srv)
body = Socket.read(c, 100)
if body
  Socket.write(c, String.upcase(body) + "\n")
end
Socket.close(c)
p(Thread.value(client))             # => "1 2 3\n"
TCPServer.close(srv)
```

## close

`Socket.close(x)`

Closes the connection and returns nil (for TLS, the TCP connection too). Closing again does nothing. Reading or writing afterwards is an `IOError`.

```ruby
srv = TCPServer.new("127.0.0.1", 0)
s = Socket.connect("127.0.0.1", TCPServer.port(srv))
p(Socket.close(s))                  # => nil
p(Socket.close(s))                  # => nil
TCPServer.close(srv)
```

## ==, !=

`Socket.==(x, Any)`

`Socket.!=(x, Any)`

Two values are equal when they are the same Socket (`!=` is the negation). The two ends of one connection (the client's `connect` and the server's `accept`) are different Sockets. A value that is not a Socket is never equal; the function form gives false for it too (no error).

```ruby
srv = TCPServer.new("127.0.0.1", 0)
s = Socket.connect("127.0.0.1", TCPServer.port(srv))
c = TCPServer.accept(srv)
p(s == s)                           # => true
p(s == c)                           # => false
p(s != c)                           # => true
p(Socket.==(s, 1))                  # => false
Socket.close(s)
Socket.close(c)
TCPServer.close(srv)
```
