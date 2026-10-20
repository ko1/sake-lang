# OpenSSL::HMAC

OpenSSL::HMAC computes a keyed message digest (RFC 2104) with Ruby's openssl, as `OpenSSL::HMAC.hexdigest("SHA256", key, data)` does in Ruby. It is built in: nothing needs to be required (`require "openssl"` still works, as in Ruby). ActiveSupport::MessageVerifier signs messages with it, and signed cookies with it.

The digest is named by a String, in any case: `"SHA1"`, `"SHA256"`, `"SHA384"`, `"SHA512"`, `"MD5"`, and the others OpenSSL knows (`"SHA3-256"`). Ruby's form with a digest object (`OpenSSL::Digest.new("SHA256")`) and the incremental `OpenSSL::HMAC.new(key, digest)` do not exist. An unknown name raises `OpenSSL::Digest::DigestError`, with OpenSSL's message; like `SQLite3::SQLException` it is a nested name, written in `rescue` and read with `Exception.message(e)` ([Exceptions](Exceptions.md)), and `rescue OpenSSL::OpenSSLError` catches it with every other `OpenSSL::` error. The key and the data are Strings, used as their bytes; the result of `digest` is a binary String (ASCII-8BIT).

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

The HMAC of `data` with `key` under the digest `alg`, as a binary String of the digest's length (32 bytes for SHA256).

```ruby
mac = OpenSSL::HMAC.digest("SHA256", "key", "data")
p(String.bytesize(mac), String.encoding(mac))   # => 32
                                                # => "ASCII-8BIT"
p(String.bytesize(OpenSSL::HMAC.digest("sha512", "key", "data")))   # => 64
```

## hexdigest

`OpenSSL::HMAC.hexdigest(String, String, String)`

The HMAC as lowercase hexadecimal, two characters per byte.

```ruby
puts(OpenSSL::HMAC.hexdigest("SHA1", "key", "The quick brown fox jumps over the lazy dog"))
# => de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9
```

## base64digest

`OpenSSL::HMAC.base64digest(String, String, String)`

The HMAC in Base64 (strict: no line breaks).

```ruby
puts(OpenSSL::HMAC.base64digest("SHA1", "key", "data"))   # => EEFSxb/coHvGM+69RhmfAlXJ9J0=
```
