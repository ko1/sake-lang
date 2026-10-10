# Socket

Socket は TCP 接続の型です。値は `Socket.connect(host, port)`（平文）、`Socket.connect_ssl(host, port)`（TLS）、そしてサーバ側の `TCPServer.accept` から来ます（[TCPServer](TCPServer.md)）。どれも同じ型 `Socket` で、同じ操作で読み書きします（Ruby の `TCPSocket` と `OpenSSL::SSL::SSLSocket`。[組み込み](../09-builtins.md)）。読む操作は `IO` と同じ形（`gets`、`read`）ですが、Socket は `IO` ではなく、`IO.puts` などには渡せません。

接続できない・切れた・名前が解けないといったネットワークの失敗は `IOError` です（Ruby の `Errno::ECONNREFUSED`、`SocketError`、`OpenSSL::SSL::SSLError` などをまとめたもの。[例外](../08-exceptions.md)）。読み書きの待ち時間は `set_timeout` で決め、過ぎると `IOError`。`gets` と `read` が返す String はバイナリ（エンコーディング `ASCII-8BIT`）で、文字列として使うには `String.force_encoding(s, "UTF-8")` を通します。UDP や Unix ドメインソケットはありません。

Socket に演算子はありません（`==` も定義されておらず、同じ値どうしを `==` で比べても false です。同じかどうかは `Kernel.equal?`）。例は `127.0.0.1` のポート 0 に `TCPServer` を立て、同じプログラムの Thread から接続します。

## connect

`Socket.connect(String, Integer, [Integer|Float|Rational])`

`host`（名前か IP アドレス）の `port` に TCP で接続し、Socket を返します。第 3 引数は接続を待つ秒数で、過ぎると `IOError`（省略時は OS の既定まで待ちます）。接続を拒まれたときも `IOError`。名前が解けないときは Ruby の `Socket::ResolutionError` でプログラムが止まります（`IOError` になりません）。

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

## connect_ssl

`Socket.connect_ssl(String, Integer, [Integer|Float|Rational])`

`host` の `port` に TCP で接続し、その上で TLS のハンドシェイクをして Socket を返します。相手の証明書は OS の信頼ストアで検証し、`host` を SNI とホスト名の検査に使います（Ruby の `OpenSSL::SSL::SSLSocket` に `VERIFY_PEER`）。第 3 引数は TCP の接続を待つ秒数。接続の失敗もハンドシェイクの失敗（TLS を話さない相手、検証できない証明書）も `IOError`。`close` は TLS と TCP の両方を閉じます。外部に繋ぐ例は検査器の中では走らせられないので、ここでは形だけ示します:

```
s = Socket.connect_ssl("example.com", 443, 10)
Socket.write(s, "GET / HTTP/1.0\r\nHost: example.com\r\n\r\n")
p(Socket.gets(s))                   # "HTTP/1.0 200 OK\r\n" など
Socket.close(s)
```

TLS を話さないサーバに繋ぐとハンドシェイクが `IOError` になります:

```ruby error
srv = TCPServer.new("127.0.0.1", 0)
port = TCPServer.port(srv)
t = Thread.new { c = TCPServer.accept(srv); Socket.close(c) }
Socket.connect_ssl("127.0.0.1", port)   # !> IOError: Socket.connect_ssl:
```

## set_timeout

`Socket.set_timeout(x, Integer|Float|Rational|Nil)`

以後の `gets`、`read`、`write` が待つ秒数を決め、Socket を返します（Ruby の `IO#timeout=`）。過ぎると `IOError`（`Blocking operation timed out!`）。nil で無制限（既定）に戻ります。

```ruby
srv = TCPServer.new("127.0.0.1", 0)
s = Socket.connect("127.0.0.1", TCPServer.port(srv))
p(Kernel.equal?(Socket.set_timeout(s, 0.05), s))   # => true
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

次の 1 行を改行を含めて返し、相手が書き込み側を閉じて（`close_write` か `close`）データが尽きたら nil です。結果は `String | nil` で、`--strict`（レベル 2）は確かめずに使うことを `nil` の問題として報告します。`set_timeout` の時間を過ぎると `IOError`。

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

ちょうど `n` バイト読んで返します。`n` バイト溜まるまで待ち、その前に相手が閉じれば残りだけを返し、もう何も無ければ nil です（`String | nil`、レベル 2。`n` が 0 なら常に `""`）。負の `n` は `ArgumentError`。Ruby の `read` と違い、引数無しの形（終端まで読む）はありません。

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

文字列を送り、送ったバイト数（Integer）を返します。改行は加えません。閉じた Socket や `close_write` の後は `IOError`。

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

書き込み側だけを閉じて nil を返します（TCP の半閉鎖）。相手の `gets` や `read` はデータが尽きた後 nil を受け取り、こちらは引き続き相手からの返事を読めます。「全部送ったら返事を待つ」プロトコルに使います。この後の `write` は `IOError`。

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

接続を閉じて nil を返します（TLS なら TCP も閉じます）。もう一度閉じても何も起きません。閉じた後の読み書きは `IOError`。

```ruby
srv = TCPServer.new("127.0.0.1", 0)
s = Socket.connect("127.0.0.1", TCPServer.port(srv))
p(Socket.close(s))                  # => nil
p(Socket.close(s))                  # => nil
TCPServer.close(srv)
```
