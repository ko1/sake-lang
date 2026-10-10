# TCPServer

TCPServer is the type of a listening socket that accepts TCP connections (Ruby's `TCPServer`). `TCPServer.new(host, port)` opens the port; `TCPServer.accept(s)` waits for the next connection and returns it as a `Socket`. An accepted connection is read and written with the [Socket](Socket.md) operations ([Built-ins](../09-builtins.md)). There is no literal.

A failure (the port cannot be opened because it is in use or not permitted, `accept` on a closed server, ...) is an `IOError` ([Exceptions](../08-exceptions.md)).

The only operators on TCPServers are `==` and `!=` (equal for the same server). The examples listen on port 0 of `127.0.0.1` (the OS picks a free port) and connect from a Thread of the same program.

## new

`TCPServer.new(String, Integer)`

Starts listening on `port` at the address `host` and returns a TCPServer. `host` is `"127.0.0.1"` (local only), `"0.0.0.0"` (every interface), `"localhost"`, and so on; it cannot be omitted (there is no `TCPServer.new(port)` as in Ruby). With `port` 0 the OS picks a free port, which `TCPServer.port` reports. A port in use, or one not permitted (below 1024), is an `IOError`.

```ruby
srv = TCPServer.new("127.0.0.1", 0)
p(srv)                              # => #<TCPServer>
p(TCPServer.port(srv) > 0)          # => true
TCPServer.close(srv)
```

```ruby error
srv = TCPServer.new("127.0.0.1", 0)
TCPServer.new("127.0.0.1", TCPServer.port(srv))   # !> IOError: TCPServer.new: Address already in use
```

## port

`TCPServer.port(x)`

The port number being listened on (an Integer), to learn the actual port after `TCPServer.new` with 0. A closed server is an `IOError` (`closed stream`).

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
p(port >= 1024)                     # => true
p(TCPServer.port(srv) == port)      # => true
TCPServer.close(srv)
```

```ruby error
srv = TCPServer.new("127.0.0.1", 0)
TCPServer.close(srv)
TCPServer.port(srv)                 # !> IOError: TCPServer.port: closed stream
```

## accept

`TCPServer.accept(x)`

Waits for the next connection and returns it as a `Socket`. Connections queue up in the OS from `TCPServer.new` on, so a peer that connects before `accept` is called is not lost. A closed server is an `IOError`. There is no time limit, so connect from another Thread, or combine with `Thread.join(t, limit)` to bound the wait.

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
clients = Array.map(Array["a", "b"]) { |name|
  Thread.new {
    s = Socket.connect("127.0.0.1", port)
    Socket.write(s, name + "\n")
    reply = Socket.gets(s)
    Socket.close(s)
    reply
  }
}
served = Array[]
Array.each(clients) { |_|
  c = TCPServer.accept(srv)
  p(c)                              # => #<Socket>
                                    # => #<Socket>
  line = Socket.gets(c)
  if line
    Array.push(served, String.chomp(line))
    Socket.write(c, "hi " + line)
  end
  Socket.close(c)
}
replies = Array.compact(Array.map(clients) { |t| Thread.value(t) })   # Socket.gets may be nil: compact before sorting
p(Array.sort(replies))              # => ["hi a\n", "hi b\n"]
p(Array.sort(served))               # => ["a", "b"]
TCPServer.close(srv)
```

```ruby error
srv = TCPServer.new("127.0.0.1", 0)
TCPServer.close(srv)
TCPServer.accept(srv)               # !> IOError: TCPServer.accept: closed stream
```

## close

`TCPServer.close(x)`

Stops listening, releases the port, and returns nil. Sockets already returned by `accept` stay usable. Closing again does nothing.

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
p(TCPServer.close(srv))             # => nil
p(TCPServer.close(srv))             # => nil
again = TCPServer.new("127.0.0.1", port)
p(TCPServer.port(again) == port)    # => true
TCPServer.close(again)
```

## ==, !=

`TCPServer.==(x, Any)`

`TCPServer.!=(x, Any)`

Two values are equal when they are the same server (`!=` is the negation). Every `TCPServer.new` is a different value. A value that is not a TCPServer is never equal; the function form gives false for it too (no error).

```ruby
srv = TCPServer.new("127.0.0.1", 0)
other = TCPServer.new("127.0.0.1", 0)
p(srv == srv)                       # => true
p(srv == other)                     # => false
p(srv != other)                     # => true
p(TCPServer.==(srv, 1))             # => false
TCPServer.close(srv)
TCPServer.close(other)
```
