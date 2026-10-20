# OpenSSL::HMAC

OpenSSL::HMAC は、Ruby の openssl で鍵付きのメッセージダイジェスト（RFC 2104）を計算します。Ruby の `OpenSSL::HMAC.hexdigest("SHA256", key, data)` と同じです。組み込みなので require は要りません（Ruby と同じく `require "openssl"` も書けます）。ActiveSupport::MessageVerifier はこれでメッセージに署名し、署名付きクッキーもこれで署名されます。

ダイジェストは String の名前で指定し、大文字小文字は問いません: `"SHA1"`、`"SHA256"`、`"SHA384"`、`"SHA512"`、`"MD5"`、ほかに OpenSSL が知っているもの（`"SHA3-256"`）。Ruby のダイジェストオブジェクトを渡す形（`OpenSSL::Digest.new("SHA256")`）と、少しずつ計算する `OpenSSL::HMAC.new(key, digest)` はありません。知らない名前は `OpenSSL::Digest::DigestError` を投げ、メッセージは OpenSSL のものです。`SQLite3::SQLException` と同じく入れ子の名前で、`rescue` に書き、`Exception.message(e)` で読みます（[例外](Exceptions.md)）。`rescue OpenSSL::OpenSSLError` は他の `OpenSSL::` のエラーと一緒にこれも捕まえます。鍵とデータは String で、そのバイト列として使います。`digest` の結果はバイナリの String（ASCII-8BIT）です。

```ruby
puts(OpenSSL::HMAC.hexdigest("SHA256", "Jefe", "what do ya want for nothing?"))
# => 5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843
begin
  OpenSSL::HMAC.hexdigest("XYZ", "key", "data")
rescue OpenSSL::Digest::DigestError => e
  puts(String.split(Exception.message(e), ":")[0])   # => unsupported digest algorithm
end
```

## digest

`OpenSSL::HMAC.digest(String, String, String)`

ダイジェスト `alg` による、`key` での `data` の HMAC を、ダイジェストの長さ（SHA256 なら 32 バイト）のバイナリの String で返します。

```ruby
mac = OpenSSL::HMAC.digest("SHA256", "key", "data")
p(String.bytesize(mac), String.encoding(mac))   # => 32
                                                # => "ASCII-8BIT"
p(String.bytesize(OpenSSL::HMAC.digest("sha512", "key", "data")))   # => 64
```

## hexdigest

`OpenSSL::HMAC.hexdigest(String, String, String)`

HMAC を小文字の 16 進数で返します（1 バイトにつき 2 文字）。

```ruby
puts(OpenSSL::HMAC.hexdigest("SHA1", "key", "The quick brown fox jumps over the lazy dog"))
# => de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9
```

## base64digest

`OpenSSL::HMAC.base64digest(String, String, String)`

HMAC を Base64 で返します（strict。改行を入れません）。

```ruby
puts(OpenSSL::HMAC.base64digest("SHA1", "key", "data"))   # => EEFSxb/coHvGM+69RhmfAlXJ9J0=
```
