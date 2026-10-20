# OpenSSL::Cipher

OpenSSL::Cipher is a symmetric cipher of Ruby's openssl (`OpenSSL::Cipher.new("aes-256-gcm")`), the type of a value that holds one encryption or decryption in progress. ActiveSupport::MessageEncryptor, and so Rails' encrypted cookies and its default cookie session store, encrypt with AES-256-GCM (and AES-256-CBC for older messages) through these operations. It is built in; the native backends do not support it.

Ruby's methods map to operations with the cipher first, and Ruby's setters `c.key = k` to `OpenSSL::Cipher.set_key(c, k)` (`set_iv`, `set_auth_tag`, `set_auth_data`, `set_padding`, `set_iv_len`), as a class's writers are named. The order of calls is OpenSSL's: `new`, then `encrypt` or `decrypt`, then the key and the IV, then (for GCM) the authenticated data, then `update` as many times as needed and `final` once; for GCM the tag is read after `final` when encrypting, and given before `final` when decrypting. Keys, IVs, tags and the output are binary Strings (ASCII-8BIT); decrypted text is binary too (`String.force_encoding(s, "UTF-8")` gives the text back).

The errors are Ruby's: `OpenSSL::Cipher::CipherError` (an unknown cipher name, a missing key, a wrong key at `final`: `bad decrypt`) and `OpenSSL::Cipher::AuthTagError` (a GCM tag that does not match), which `rescue OpenSSL::Cipher::CipherError` also catches, as in Ruby; both are under `OpenSSL::OpenSSLError`. A key or IV of the wrong length is an `ArgumentError` (`key must be 32 bytes`). Like `SQLite3::SQLException` these are nested names ([Exceptions](Exceptions.md)). The only operators are `==` and `!=` (the same cipher).

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

A new cipher of the algorithm `name`, in OpenSSL's spelling and any case: `"aes-256-gcm"`, `"aes-256-cbc"`, `"aes-128-gcm"`, `"chacha20-poly1305"`, ... An unknown name raises `OpenSSL::Cipher::CipherError`.

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

The names of every cipher OpenSSL offers, an Array of Strings (in lowercase).

```ruby
p(Array.include?(OpenSSL::Cipher.ciphers, "aes-256-gcm"))   # => true
```

## encrypt, decrypt

`OpenSSL::Cipher.encrypt(x)`
`OpenSSL::Cipher.decrypt(x)`

Set the cipher to encrypt or to decrypt, and return it. Call one of them first, before the key.

```ruby
c = OpenSSL::Cipher.decrypt(OpenSSL::Cipher.new("aes-256-gcm"))
p(OpenSSL::Cipher.key_len(c))     # => 32
```

## set_key, set_iv

`OpenSSL::Cipher.set_key(x, String)`
`OpenSSL::Cipher.set_iv(x, String)`

Ruby's `c.key = key` and `c.iv = iv`: the key (exactly `key_len` bytes) and the initialization vector (`iv_len` bytes). Each returns the String given. Another length is an `ArgumentError`. An IV must never be used twice with the same key: `random_iv` makes one.

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

Ruby's `c.auth_data = s`: data that is authenticated by the tag but not encrypted (AEAD ciphers such as GCM). Set it after the key and IV, before `update`, on both sides; MessageEncryptor sets `""`.

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

`auth_tag(c, len)` reads the authentication tag (16 bytes unless `len` is given) after `final` of a GCM encryption; `set_auth_tag(c, tag)` (Ruby's `c.auth_tag = tag`) gives it to a decryption before `final`, which then raises `OpenSSL::Cipher::AuthTagError` when the data, the authenticated data or the tag were changed.

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

Encrypts or decrypts the next part of the data and returns what is ready of the output (a block cipher such as CBC keeps a partial block for the next call or `final`).

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "v" * 16)
p(String.bytesize(OpenSSL::Cipher.update(c, "short")))   # => 0
p(String.bytesize(OpenSSL::Cipher.final(c)))             # => 16
```

## final

`OpenSSL::Cipher.final(x)`

Finishes the operation and returns the rest of the output: the padded last block of a CBC encryption, nothing more for GCM. Decrypting, it checks the padding (CBC; a wrong key usually ends in `bad decrypt`) or the tag (GCM), raising `OpenSSL::Cipher::CipherError`.

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

Make a random IV (or key) of the cipher's length from OpenSSL's generator, set it, and return it: the IV is sent along with the encrypted data.

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-gcm"))
p(String.bytesize(OpenSSL::Cipher.random_key(c)), String.bytesize(OpenSSL::Cipher.random_iv(c)))   # => 32
                                                                                                    # => 12
```

## reset

`OpenSSL::Cipher.reset(x)`

Starts the operation again with the same key and IV, and returns the cipher.

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

Ruby's `c.padding = n`: 0 turns off the PKCS#7 padding of a block cipher, so that the data must be a whole number of blocks; 1 (the default) turns it on.

```ruby
c = OpenSSL::Cipher.encrypt(OpenSSL::Cipher.new("aes-256-cbc"))
OpenSSL::Cipher.set_key(c, "k" * 32)
OpenSSL::Cipher.set_iv(c, "v" * 16)
OpenSSL::Cipher.set_padding(c, 0)
p(String.bytesize(OpenSSL::Cipher.update(c, "sixteen bytes!!!") + OpenSSL::Cipher.final(c)))   # => 16
```

## set_iv_len

`OpenSSL::Cipher.set_iv_len(x, Integer)`

Ruby's `c.iv_len = n`: another IV length for an AEAD cipher (GCM takes 12 by default). Set it before the IV.

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

The cipher's name (OpenSSL's, in capitals), its key and IV lengths and block size in bytes, and whether it is an AEAD cipher with a tag (`MessageEncryptor.key_len` and its AEAD mode come from these).

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

Two ciphers are `==` when they are the same cipher value.

```ruby
a = OpenSSL::Cipher.new("aes-256-gcm")
p(a == a, a == OpenSSL::Cipher.new("aes-256-gcm"))   # => true
                                                     # => false
```
