# OpenSSL::Random

OpenSSL::Random gives cryptographically strong random bytes from OpenSSL's generator (Ruby's `OpenSSL::Random`). It is built in; salts and keys are made from it (sakelib/bcrypt.sake's salts, `OpenSSL::Cipher.random_key`).

```ruby
p(String.bytesize(OpenSSL::Random.random_bytes(16)))   # => 16
```

## random_bytes

`OpenSSL::Random.random_bytes(Integer)`

A binary String of `n` random bytes. A negative `n` is an `ArgumentError`.

```ruby
b = OpenSSL::Random.random_bytes(8)
p(String.bytesize(b), String.encoding(b))   # => 8
                                            # => "ASCII-8BIT"
p(OpenSSL::Random.random_bytes(0))          # => ""
```
