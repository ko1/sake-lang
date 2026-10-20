# openssl

OpenSSL is built into the interpreter (2026-10-20, for the Rails port: lib/sake/stdlib_openssl.rb over Ruby's
openssl). `sakelib/openssl.sake` is kept only so that `require "openssl"` works as in Ruby; it defines nothing.
From 2026-10-13 to 10-20 it held `OpenSSL::HMAC` written in Sake over `sakelib/digest.sake` (about 20 ms per
HMAC, so Rails' 1000-iteration PBKDF2 took about 20 s per key); the built-in is OpenSSL's speed.

## API

| Ruby | Sake | |
|---|---|---|
| `OpenSSL::HMAC.hexdigest("SHA256", key, data)` (`digest`, `base64digest`) | the same | same |
| `OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("SHA256"), ...)` | — | the digest is named by a String |
| `OpenSSL::KDF.pbkdf2_hmac(pw, salt:, iterations:, length:, hash:)` | the same | same (hash: a String) |
| `OpenSSL::PKCS5.pbkdf2_hmac(pw, salt, iter, len, digest)`, `pbkdf2_hmac_sha1` | the same | same (digest: a String) |
| `OpenSSL::Random.random_bytes(n)` | the same | same |
| `c = OpenSSL::Cipher.new("aes-256-gcm")`, `c.encrypt`, `c.decrypt` | `OpenSSL::Cipher.new(...)`, `OpenSSL::Cipher.encrypt(c)` | a native value, like SQLite3::Database |
| `c.key = k`, `c.iv = iv`, `c.auth_tag = t`, `c.auth_data = s`, `c.padding = 0`, `c.iv_len = n` | `OpenSSL::Cipher.set_key(c, k)`, `set_iv`, `set_auth_tag`, `set_auth_data`, `set_padding`, `set_iv_len` | Sake's writer names |
| `c.update(s)`, `c.final`, `c.auth_tag(16)`, `c.random_iv`, `c.random_key`, `c.reset` | `OpenSSL::Cipher.update(c, s)`, ... | same |
| `c.name`, `key_len`, `iv_len`, `block_size`, `authenticated?`, `OpenSSL::Cipher.ciphers` | the same, subject first | same |
| `OpenSSL::Digest::DigestError`, `OpenSSL::Cipher::CipherError`, `AuthTagError`, `OpenSSL::KDF::KDFError`, `OpenSSL::HMACError`, `OpenSSL::OpenSSLError` | rescuable by these names | same parents (`AuthTagError < CipherError`, all `< OpenSSLError`) |

## Not ported

`OpenSSL::Digest` objects (`Digest::SHA256` is sakelib/digest.sake's, in Sake), incremental `OpenSSL::HMAC.new`,
public keys (`OpenSSL::PKey`), certificates, SSL contexts (Sake's TLS socket is the built-in `Socket.connect_ssl`).

## Tests

`test/sakelib/openssl.{sake,rb}` (HMAC: 6 names × 6 keys × 4 messages, RFC 4231 case 2, the error),
`test/sakelib/openssl_cipher.{sake,rb}` (PBKDF2 both ways, GCM and CBC round trips as MessageEncryptor runs
them, a bad tag), and the goldens `test/samples/openssl*.sake`.
