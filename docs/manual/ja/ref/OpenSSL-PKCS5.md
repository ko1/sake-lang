# OpenSSL::PKCS5

OpenSSL::PKCS5 は Ruby での PBKDF2 の古い名前で、位置引数を取ります: `OpenSSL::PKCS5.pbkdf2_hmac(pass, salt, iterations, length, digest)` は `OpenSSL::KDF.pbkdf2_hmac(pass, salt:, iterations:, length:, hash:)` です（[OpenSSL::KDF](OpenSSL-KDF.md)）。ActiveSupport::KeyGenerator はこの形で呼びます。組み込みで、エラーは OpenSSL::KDF と同じです。

```ruby
puts(String.unpack1(OpenSSL::PKCS5.pbkdf2_hmac("password", "salt", 4096, 20, "sha1"), "H*"))
# => 4b007901b765489abead49d926f721d065a429c1
```

## pbkdf2_hmac

`OpenSSL::PKCS5.pbkdf2_hmac(String, String, Integer, Integer, String)`

`pass` の PBKDF2 を、`salt`、`iterations`、名前 `digest` のダイジェスト上の HMAC で計算した `length` バイトです（Ruby はそこに `OpenSSL::Digest` オブジェクトも取りますが、Sake は名前です）。

```ruby
k = OpenSSL::PKCS5.pbkdf2_hmac("secret_key_base", "signed cookie", 1000, 64, "sha1")
p(String.bytesize(k))             # => 64
p(k == OpenSSL::KDF.pbkdf2_hmac("secret_key_base", salt: "signed cookie", iterations: 1000, length: 64, hash: "sha1"))   # => true
```

## pbkdf2_hmac_sha1

`OpenSSL::PKCS5.pbkdf2_hmac_sha1(String, String, Integer, Integer)`

SHA1 での `pbkdf2_hmac` です。

```ruby
puts(String.unpack1(OpenSSL::PKCS5.pbkdf2_hmac_sha1("password", "salt", 2, 20), "H*"))
# => ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957
```
