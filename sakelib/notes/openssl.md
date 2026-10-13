# openssl

`require "openssl"` gives `OpenSSL::HMAC` only (2026-10-13), a keyed digest (RFC 2104) written in Sake over
`sakelib/digest.sake`. It was asked for by the web experiment (experiments/2026-10-12-web): Sinatra's signed
session cookie and jwt each had their own HMAC.

## API

| Ruby | Sake | |
|---|---|---|
| `OpenSSL::HMAC.hexdigest("SHA256", key, data)` | the same | same |
| `OpenSSL::HMAC.digest("SHA256", key, data)` | the same | same (a binary String) |
| `OpenSSL::HMAC.base64digest("SHA256", key, data)` | the same | same |
| `OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("SHA256"), ...)` | — | missing: the digest is named by a String |
| `OpenSSL::HMAC.new(key, digest)`, `update`, `<<` | — | missing |
| an unknown digest name | `OpenSSL::Digest::DigestError` | differs: the message is Ruby's first part, `unsupported digest algorithm: XYZ` |

Digests: MD5, SHA1, SHA256, SHA384, SHA512, in any case (`"sha256"`), as OpenSSL takes them.

## Not ported

Ciphers, keys, certificates, SSL (Sake's TLS socket is the built-in `TCPSocket.connect_ssl`), and
`OpenSSL::Digest` itself (`Digest::SHA256` is digest.sake's).

## Size

46 lines with comments. The test (`test/sakelib/openssl.{sake,rb}`) runs 6 names × 6 keys (empty, the block size,
longer than the block, non-ASCII) × 4 messages, RFC 4231's test case 2, and the error.
