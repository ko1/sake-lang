# OpenSSL::Random

OpenSSL::Random は、OpenSSL の生成器から暗号論的に強い乱数のバイト列を返します（Ruby の `OpenSSL::Random`）。組み込みで、ソルトや鍵はこれから作ります（sakelib/bcrypt.sake のソルト、`OpenSSL::Cipher.random_key`）。

```ruby
p(String.bytesize(OpenSSL::Random.random_bytes(16)))   # => 16
```

## random_bytes

`OpenSSL::Random.random_bytes(Integer)`

`n` バイトの乱数のバイナリの String です。負の `n` は `ArgumentError` です。

```ruby
b = OpenSSL::Random.random_bytes(8)
p(String.bytesize(b), String.encoding(b))   # => 8
                                            # => "ASCII-8BIT"
p(OpenSSL::Random.random_bytes(0))          # => ""
```
