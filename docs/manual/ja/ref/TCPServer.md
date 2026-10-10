# TCPServer

TCPServer は TCP の接続を受け付ける待ち受けソケットの型です（Ruby の `TCPServer`）。`TCPServer.new(host, port)` がポートを開き、`TCPServer.accept(s)` が次の接続を待って `Socket` を返します。受け付けた接続は [Socket](Socket.md) の操作で読み書きします（[組み込み](../09-builtins.md)）。リテラルはありません。

ポートを開けない（使用中、権限が無い）、閉じたサーバで accept する、などの失敗は `IOError` です（[例外](../08-exceptions.md)）。

TCPServer に演算子はありません（`==` も定義されていません）。例は `127.0.0.1` のポート 0（空いているポートを OS が選ぶ）で立て、同じプログラムの Thread から接続します。

## new

`TCPServer.new(String, Integer)`

`host` のアドレスの `port` で待ち受けを始め、TCPServer を返します。`host` は `"127.0.0.1"`（ローカルだけ）、`"0.0.0.0"`（すべてのインターフェース）、`"localhost"` などで、省略できません（Ruby の `TCPServer.new(port)` の形はありません）。`port` が 0 なら空いているポートを OS が選び、`TCPServer.port` で分かります。使用中のポートや権限の無いポート（1024 未満）は `IOError`。

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

待ち受けているポート番号（Integer）。`TCPServer.new` に 0 を渡したときに、実際のポートを知るために使います。閉じたサーバでは Ruby の `IOError` でプログラムが止まります（rescue できる形になりません）。

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
p(port >= 1024)                     # => true
p(TCPServer.port(srv) == port)      # => true
TCPServer.close(srv)
```

## accept

`TCPServer.accept(x)`

次の接続が来るまで待ち、それを `Socket` として返します。接続は `TCPServer.new` の時点から OS が溜めるので、`accept` を呼ぶ前に相手が接続していても失われません。閉じたサーバでは `IOError`。待ち時間の上限はないので、別の Thread から接続するか、時間を区切るなら `Thread.join(t, limit)` と組み合わせます。

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
p(Array.sort(Array.map(clients) { |t| Thread.value(t) }))   # => ["hi a\n", "hi b\n"]
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

待ち受けを止めてポートを離し、nil を返します。既に `accept` した `Socket` はそのまま使えます。もう一度閉じても何も起きません。

```ruby
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
p(TCPServer.close(srv))             # => nil
p(TCPServer.close(srv))             # => nil
again = TCPServer.new("127.0.0.1", port)
p(TCPServer.port(again) == port)    # => true
TCPServer.close(again)
```
