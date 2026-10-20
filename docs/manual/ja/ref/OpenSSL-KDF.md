# OpenSSL::KDF

OpenSSL::KDF は、Ruby の openssl でパスワードから鍵を導出します。`OpenSSL::KDF.pbkdf2_hmac` は PBKDF2（RFC 8018）で、ActiveSupport::KeyGenerator が `secret_key_base` から署名付き・暗号化クッキーの鍵を導出するのに使うものです。組み込みで、OpenSSL の速さで動きます（Rails の 1000 回の反復で約 1 ミリ秒）。同じ関数を位置引数で呼ぶのが [OpenSSL::PKCS5](OpenSSL-PKCS5.md)`.pbkdf2_hmac` です。エラーは `OpenSSL::KDF::KDFError`（反復回数が 1 未満）と `OpenSSL::Digest::DigestError`（知らないダイジェスト）で、どちらも `OpenSSL::OpenSSLError` の下にあります（[例外](Exceptions.md)）。

```ruby
key = OpenSSL::KDF.pbkdf2_hmac("password", salt: "salt", iterations: 4096, length: 20, hash: "sha1")
puts(String.unpack1(key, "H*"))   # => 4b007901b765489abead49d926f721d065a429c1
```

## pbkdf2_hmac

`OpenSSL::KDF.pbkdf2_hmac(String, [salt: String], [iterations: Integer], [length: Integer], [hash: String])`

`pass` から導出した鍵です: ダイジェスト `hash`（`"sha256"` のような名前）上の HMAC による PBKDF2 を `salt` と `iterations` で計算した `length` バイト（バイナリの String）。Ruby と同じく 4 つのキーワードはすべて必須で、欠けると `ArgumentError`（`missing keywords: :iterations, :length`）です。ダイジェストは String で、Ruby の `OpenSSL::Digest` オブジェクトではありません。

```ruby
k = OpenSSL::KDF.pbkdf2_hmac("secret", salt: "authenticated encrypted cookie", iterations: 1000, length: 32, hash: "sha256")
p(String.bytesize(k))             # => 32
begin
  OpenSSL::KDF.pbkdf2_hmac("pw", salt: "s", iterations: 0, length: 16, hash: "sha1")
rescue OpenSSL::KDF::KDFError => e
  puts(Exception.message(e))      # => PKCS5_PBKDF2_HMAC: invalid iteration count
end
begin
  OpenSSL::KDF.pbkdf2_hmac("pw", salt: "s")
rescue ArgumentError => e
  puts(Exception.message(e))      # => missing keywords: :iterations, :length, :hash
end
```
