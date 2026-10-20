# OpenSSL::KDF

OpenSSL::KDF derives keys from a password with Ruby's openssl. `OpenSSL::KDF.pbkdf2_hmac` is PBKDF2 (RFC 8018), as ActiveSupport::KeyGenerator derives the keys of signed and encrypted cookies from `secret_key_base`. It is built in, and runs at OpenSSL's speed (Rails' 1000 iterations take about a millisecond). The same function with positional arguments is [OpenSSL::PKCS5](OpenSSL-PKCS5.md)`.pbkdf2_hmac`. Errors are `OpenSSL::KDF::KDFError` (an iteration count below 1) and `OpenSSL::Digest::DigestError` (an unknown digest), both under `OpenSSL::OpenSSLError` ([Exceptions](Exceptions.md)).

```ruby
key = OpenSSL::KDF.pbkdf2_hmac("password", salt: "salt", iterations: 4096, length: 20, hash: "sha1")
puts(String.unpack1(key, "H*"))   # => 4b007901b765489abead49d926f721d065a429c1
```

## pbkdf2_hmac

`OpenSSL::KDF.pbkdf2_hmac(String, [salt: String], [iterations: Integer], [length: Integer], [hash: String])`

The key derived from `pass`: `length` bytes (a binary String) of PBKDF2 with HMAC over the digest `hash` (a name such as `"sha256"`), `salt` and `iterations`. All four keywords are required, as in Ruby: a missing one is an `ArgumentError` (`missing keywords: :iterations, :length`). The digest is a String, not Ruby's `OpenSSL::Digest` object.

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
