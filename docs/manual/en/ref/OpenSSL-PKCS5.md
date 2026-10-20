# OpenSSL::PKCS5

OpenSSL::PKCS5 is Ruby's older name for PBKDF2, with positional arguments: `OpenSSL::PKCS5.pbkdf2_hmac(pass, salt, iterations, length, digest)` is `OpenSSL::KDF.pbkdf2_hmac(pass, salt:, iterations:, length:, hash:)` ([OpenSSL::KDF](OpenSSL-KDF.md)). ActiveSupport::KeyGenerator calls this form. It is built in; the errors are those of OpenSSL::KDF.

```ruby
puts(String.unpack1(OpenSSL::PKCS5.pbkdf2_hmac("password", "salt", 4096, 20, "sha1"), "H*"))
# => 4b007901b765489abead49d926f721d065a429c1
```

## pbkdf2_hmac

`OpenSSL::PKCS5.pbkdf2_hmac(String, String, Integer, Integer, String)`

`length` bytes of PBKDF2 of `pass` with `salt`, `iterations` and HMAC over the digest named `digest` (Ruby also takes an `OpenSSL::Digest` object there; Sake a name).

```ruby
k = OpenSSL::PKCS5.pbkdf2_hmac("secret_key_base", "signed cookie", 1000, 64, "sha1")
p(String.bytesize(k))             # => 64
p(k == OpenSSL::KDF.pbkdf2_hmac("secret_key_base", salt: "signed cookie", iterations: 1000, length: 64, hash: "sha1"))   # => true
```

## pbkdf2_hmac_sha1

`OpenSSL::PKCS5.pbkdf2_hmac_sha1(String, String, Integer, Integer)`

`pbkdf2_hmac` with SHA1.

```ruby
puts(String.unpack1(OpenSSL::PKCS5.pbkdf2_hmac_sha1("password", "salt", 2, 20), "H*"))
# => ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957
```
