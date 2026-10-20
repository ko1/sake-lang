# OpenSSL::Cipher

OpenSSL::Cipher は Ruby の openssl の共通鍵暗号（`OpenSSL::Cipher.new("aes-256-gcm")`）で、進行中の 1 回の暗号化または復号を持つ値の型です。ActiveSupport::MessageEncryptor は、つまり Rails の暗号化クッキーと既定のクッキーセッションストアは、これらの操作で AES-256-GCM（古いメッセージには AES-256-CBC）を使って暗号化します。組み込みで、ネイティブバックエンドは対応していません。

Ruby のメソッドは暗号を先頭の引数に取る操作になり、Ruby のセッター `c.key = k` は、クラスの書き込み関数の名前と同じく `OpenSSL::Cipher.set_key(c, k)` になります（`set_iv`、`set_auth_tag`、`set_auth_data`、`set_padding`、`set_iv_len`）。呼ぶ順序は OpenSSL のとおりです: `new`、次に `encrypt` か `decrypt`、次に鍵と IV、次に（GCM なら）認証付きデータ、次に必要なだけの `update` と 1 回の `final`。GCM のタグは、暗号化では `final` の後に読み、復号では `final` の前に渡します。鍵、IV、タグ、出力はバイナリの String（ASCII-8BIT）です。復号した文もバイナリです（`String.force_encoding(s, "UTF-8")` で文字列に戻ります）。

エラーは Ruby のものです: `OpenSSL::Cipher::CipherError`（知らない暗号名、鍵が無い、`final` での鍵の誤り: `bad decrypt`）と `OpenSSL::Cipher::AuthTagError`（GCM のタグが合わない）で、後者は Ruby と同じく `rescue OpenSSL::Cipher::CipherError` でも捕まえられます。どちらも `OpenSSL::OpenSSLError` の下にあります。長さの違う鍵や IV は `ArgumentError`（`key must be 32 bytes`）です。`SQLite3::SQLException` と同じく入れ子の名前です（[例外](Exceptions.md)）。使える演算子は `==`、`!=` だけです（同じ暗号なら等しい）。

```ruby
key = OpenSSL::KDF.pbkdf2_hmac("secret", salt: "encrypted cookie", iterations: 1000, length: 32, hash: "sha256")
c = OpenSSL::Cipher.new("aes-256-gcm")
OpenSSL::Cipher.encrypt(c)
OpenSSL::Cipher.set_key(c, key)
iv = OpenSSL::Cipher.random_iv(c)
OpenSSL::Cipher.set_auth_data(c, "")
data = OpenSSL::Cipher.update(c, "hello") + OpenSSL::Cipher.final(c)
tag = OpenSSL::Cipher.auth_tag(c)

d = OpenSSL::Cipher.new("aes-256-gcm")
OpenSSL::Cipher.decrypt(d)
OpenSSL::Cipher.set_key(d, key)
OpenSSL::Cipher.set_iv(d, iv)
OpenSSL::Cipher.set_auth_tag(d, tag)
OpenSSL::Cipher.set_auth_data(d, "")
p(OpenSSL::Cipher.update(d, data) + OpenSSL::Cipher.final(d))   # => "hello"
```

## new

`OpenSSL::Cipher.new(String)`

アルゴリズム `name` の新しい暗号です。名前は OpenSSL の綴りで、大文字小文字は問いません: `"aes-256-gcm"`、`"aes-256-cbc"`、`"aes-128-gcm"`、`"chacha20-poly1305"` など。知らない名前は `OpenSSL::Cipher::CipherError` を投げます。

```ruby
c = OpenSSL::Cipher.new("AES-256-CBC")
p(c, OpenSSL::Cipher.name(c))     # => #<OpenSSL::Cipher>
                                  # => "AES-256-CBC"
begin
  OpenSSL::Cipher.new("aes-999-xyz")
rescue OpenSSL::Cipher::CipherError => e
  puts(String.split(Exception.message(e), ":")[0])   # => unsupported cipher algorithm
end
```

## ciphers

`OpenSSL::Cipher.ciphers()`

OpenSSL が提供するすべての暗号の名前で、String の Array です（小文字）。

```ruby
p(Array.include?(OpenSSL::Cipher.ciphers, "aes-256-gcm"))   # => true
```

## encrypt, decrypt

`OpenSSL::Cipher.encrypt(x)`
`OpenSSL::Cipher.decrypt(x)`

暗号を暗号化用または復号用にして、それを返します。鍵より前に、まずどちらかを呼びます。

```ruby
c = OpenSSL::Cipher.decrypt(OpenSSL::Cipher.new("aes-256-gcm"))
p(OpenSSL::Cipher.key_len(c))     # => 32
```

## set_key, set_iv

`OpenSSL::Cipher.set_key(x, String)`
`OpenSSL::Cipher.set_iv(x, String)`

Ruby の `c.key = key` と `c.iv = iv` です: 鍵（ちょうど `key_len` バイト）と初期化ベクタ（`iv_len` バイト）。どちらも渡した String を返します。他の長さは `ArgumentError` です。同じ鍵で IV を 2 度使ってはいけません。`random_iv` が作ります。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "v" * 16)
puts(String.unpack1(OpenSSL::Cipher.update(c, "sixteen bytes!!!") + OpenSSL::Cipher.final(c), "H*"))
# => d31961d7928eadb6794c6548a346a00a4f2044b1f86ca311a7f7de5383c228ac
begin
  OpenSSL::Cipher.set_key(c, "short")
rescue ArgumentError => e
  puts(Exception.message(e))      # => key must be 32 bytes
end
```

## set_auth_data

`OpenSSL::Cipher.set_auth_data(x, String)`

Ruby の `c.auth_data = s` です: タグで認証されるが暗号化はされないデータ（GCM のような AEAD 暗号）。鍵と IV の後、`update` の前に、両側で設定します。MessageEncryptor は `""` を設定します。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-gcm"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "i" * 12)
OpenSSL::Cipher.set_auth_data(c, "header")
OpenSSL::Cipher.final(c)
p(String.bytesize(OpenSSL::Cipher.auth_tag(c)))   # => 16
```

## auth_tag, set_auth_tag

`OpenSSL::Cipher.auth_tag(x, [Integer])`
`OpenSSL::Cipher.set_auth_tag(x, String)`

`auth_tag(c, len)` は GCM の暗号化の `final` の後に認証タグを読みます（`len` を渡さなければ 16 バイト）。`set_auth_tag(c, tag)`（Ruby の `c.auth_tag = tag`）は `final` の前に復号へタグを渡し、データ、認証付きデータ、タグのどれかが変えられていれば `final` が `OpenSSL::Cipher::AuthTagError` を投げます。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-gcm"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "i" * 12)
data = OpenSSL::Cipher.update(c, "hello, sake") + OpenSSL::Cipher.final(c)
puts(String.unpack1(OpenSSL::Cipher.auth_tag(c, 16), "H*"))   # => 8847fd8a01364df615d735eb75fd76e6
d = OpenSSL::Cipher.decrypt(OpenSSL::Cipher.new("aes-256-gcm"))
OpenSSL::Cipher.set_key(d, "k" * 32)
OpenSSL::Cipher.set_iv(d, "i" * 12)
OpenSSL::Cipher.set_auth_tag(d, "x" * 16)
OpenSSL::Cipher.update(d, data)
begin
  OpenSSL::Cipher.final(d)
rescue OpenSSL::Cipher::CipherError => e
  puts(Exception.message(e))      # => AEAD authentication tag verification failed
end
```

## update

`OpenSSL::Cipher.update(x, String)`

データの次の部分を暗号化または復号し、出力のうちできあがった分を返します（CBC のようなブロック暗号は、半端なブロックを次の呼び出しか `final` まで持ち越します）。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "v" * 16)
p(String.bytesize(OpenSSL::Cipher.update(c, "short")))   # => 0
p(String.bytesize(OpenSSL::Cipher.final(c)))             # => 16
```

## final

`OpenSSL::Cipher.final(x)`

操作を終え、出力の残りを返します: CBC の暗号化ならパディングした最後のブロック、GCM なら何もありません。復号では、パディング（CBC。鍵が違うとたいてい `bad decrypt` になります）またはタグ（GCM）を検査し、`OpenSSL::Cipher::CipherError` を投げます。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "v" * 16)
secret = OpenSSL::Cipher.update(c, "sixteen bytes!!!") + OpenSSL::Cipher.final(c)
d = OpenSSL::Cipher.decrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(d, "j" * 32)
OpenSSL::Cipher.set_iv(d, "v" * 16)
OpenSSL::Cipher.update(d, secret)
begin
  OpenSSL::Cipher.final(d)
rescue OpenSSL::Cipher::CipherError => e
  puts(Exception.message(e))      # => cipher final failed: bad decrypt
end
```

## random_iv, random_key

`OpenSSL::Cipher.random_iv(x)`
`OpenSSL::Cipher.random_key(x)`

暗号の長さの乱数の IV（または鍵）を OpenSSL の生成器で作り、設定して、それを返します。IV は暗号化したデータと一緒に送ります。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-gcm"))
p(String.bytesize(OpenSSL::Cipher.random_key(c)), String.bytesize(OpenSSL::Cipher.random_iv(c)))   # => 32
                                                                                                    # => 12
```

## reset

`OpenSSL::Cipher.reset(x)`

同じ鍵と IV で操作をやり直し、暗号を返します。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "v" * 16)
a = OpenSSL::Cipher.update(c, "x") + OpenSSL::Cipher.final(c)
OpenSSL::Cipher.reset(c)
p(a == OpenSSL::Cipher.update(c, "x") + OpenSSL::Cipher.final(c))   # => true
```

## set_padding

`OpenSSL::Cipher.set_padding(x, Integer)`

Ruby の `c.padding = n` です: 0 はブロック暗号の PKCS#7 パディングを切り、データはブロックの整数倍でなければならなくなります。1（既定）はパディングを入れます。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "v" * 16)
OpenSSL::Cipher.set_padding(c, 0)
p(String.bytesize(OpenSSL::Cipher.update(c, "sixteen bytes!!!") + OpenSSL::Cipher.final(c)))   # => 16
```

## set_iv_len

`OpenSSL::Cipher.set_iv_len(x, Integer)`

Ruby の `c.iv_len = n` です: AEAD 暗号の IV を別の長さにします（GCM の既定は 12）。IV より前に設定します。

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-gcm"))
OpenSSL::Cipher.set_iv_len(c, 16)
p(OpenSSL::Cipher.iv_len(c))      # => 16
```

## name, key_len, iv_len, block_size, authenticated?

`OpenSSL::Cipher.name(x)`
`OpenSSL::Cipher.key_len(x)`
`OpenSSL::Cipher.iv_len(x)`
`OpenSSL::Cipher.block_size(x)`
`OpenSSL::Cipher.authenticated?(x)`

暗号の名前（OpenSSL のもので、大文字）、鍵と IV の長さとブロックの大きさ（バイト）、タグを持つ AEAD 暗号かどうかです（`MessageEncryptor.key_len` と、その AEAD のモードはここから来ます）。

```ruby
Array.each(Any["aes-256-gcm", "aes-256-cbc"]) { |n|
  c = OpenSSL::Cipher.new(n)
  p([OpenSSL::Cipher.name(c), OpenSSL::Cipher.key_len(c), OpenSSL::Cipher.iv_len(c), OpenSSL::Cipher.block_size(c), OpenSSL::Cipher.authenticated?(c)])
}
# => ["AES-256-GCM", 32, 12, 1, true]
# => ["AES-256-CBC", 32, 16, 16, false]
```

## ==, !=

`OpenSSL::Cipher.==(x, Any)`
`OpenSSL::Cipher.!=(x, Any)`

同じ暗号の値なら `==` です。

```ruby
a = OpenSSL::Cipher.new("aes-256-gcm")
p(a == a, a == OpenSSL::Cipher.new("aes-256-gcm"))   # => true
                                                     # => false
```
