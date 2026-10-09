# jwt (ruby-jwt 3.2)

`require "jwt"` → `sakelib/jwt.sake`. Test: `test/sakelib/jwt.{sake,rb}` (the .rb uses the real gem, jwt
3.2.0; identical output: 14 tokens byte for byte, 40 decodes, 35 error cases). Built on `sakelib/digest.sake`
(it has SHA256/SHA384/SHA512, so HMAC is 20 lines here, RFC 2104), `sakelib/json.sake`, and the built-in
`Array.pack` / `String.unpack1` with `"m0"` for Base64url. 20 functions (8 public: `encode`, `decode`,
`decode_error?`, `base64url_encode/decode`, `hmac_sha256/384/512`).

## API

| Gem | Sake | |
|---|---|---|
| `JWT.encode(payload, key, "HS256")` | `JWT.encode(payload, key, "HS256")` | same (payload a Hash; keys in order; Symbol keys allowed) |
| `JWT.encode(payload, key, alg, header_fields)` | same | same (fields before `alg`, as the gem) |
| algorithms `HS256`, `HS384`, `HS512`, `none`; case-insensitive names | same | same |
| `RS256`, `ES256`, `PS256`, `EdDSA` | — | missing: no RSA / EC (would be a bignum RSA in Sake; `OpenSSL` is not a built-in) |
| `JWT.decode(token, key, verify, {algorithm:, algorithms:, leeway:, exp_leeway:, nbf_leeway:, verify_expiration:, verify_not_before:, verify_iat:, verify_iss:, iss:, verify_aud:, aud:, verify_sub:, sub:, verify_jti:})` | `JWT.decode(token, key = nil, verify = true, algorithm: "HS256", ...)` | same; the options Hash is keyword parameters; gives the Tuple `[payload, header]` |
| `JWT::ExpiredSignature`, `ImmatureSignature`, `InvalidIatError`, `VerificationError`, `IncorrectAlgorithm`, `InvalidIssuerError`, `InvalidAudError`, `InvalidSubError`, `InvalidJtiError`, `InvalidPayload`, `Base64DecodeError`, `DecodeError`, `EncodeError` | `JWTExpiredSignature`, ... `JWTDecodeError`, `JWTEncodeError` | same names and messages; **no hierarchy**: `rescue JWTDecodeError` catches only that one; `JWT.decode_error?(e)` is `rescue JWT::DecodeError` |
| `verify_jti: proc`, `verify_iss: proc`, `required_claims:`, `JWT.decode { \|header\| key }` (key finder block), JWK, `JWT::Token`/`EncodedToken` (3.x object API), `JWT.configuration` | — | missing: callables, or beyond the brief |
| `iat_leeway:` | — | missing on purpose: the gem (3.2) ignores it (no leeway on `iat`), and so does Sake |
| `JWT::Base64.url_encode/url_decode` | `JWT.base64url_encode/decode` | same (strict decoding, `Base64DecodeError`) |
| `OpenSSL::HMAC.digest("SHA256", key, s)` | `JWT.hmac_sha256(key, s)` (`384`, `512`) | same bytes (RFC 4231 vectors in the test) |

## できたこと / できなかったこと

- **できた**: HS256/384/512 end to end, byte-identical tokens, including a 100-byte key (hashed to the
  block), a 64-byte key, UTF-8 payload and key, Float `exp`, `header_fields`, and the gem's whole decode
  path order: segment count (3, or 2 without verification or with `alg: none`), header, payload, algorithm
  check (`IncorrectAlgorithm`), key presence (`No verification key available`, `HMAC key cannot be empty`),
  signature (`VerificationError`), then the claims in the gem's order with its messages (`Invalid issuer.
  Expected ["you"], received me`, `Missing jti`). `none` is rejected unless `algorithm: "none"` is passed.
- **できなかった**: RSA/ECDSA (no bignum-exponentiation-based crypto worth writing in two hours; `Integer.pow(a,
  b, mod)` exists, so RS256 is possible later), the key-finder block of `decode` and the proc verifiers
  (stored callables), `rescue JWT::DecodeError` as a family (no exception hierarchy; `decode_error?` instead).

## 書き心地

1. **`exp = expected in Array ? expected : Array[expected]`** → `syntax error: unexpected '?'` with the hint
   `x in T needs its own parentheses here: (x in T)`. Wrote `(expected in Array) ? ...`. The hint named the fix.
2. **Decoded strings came back as `"\xC3\xA9"`**: Base64 gives a binary String and `JSON.parse` kept it
   binary. `String.force_encoding(s, "UTF-8")` before parsing; found by the diff with the gem, not by the
   checker (an encoding is not a type).
3. **Keyword parameters are the gem's options Hash, checked**: `JWT.decode(t, k, true, algorithm: "HS512")`;
   a misspelled `algorithms: "HS512"` (String for the Array option) would be a type report at the
   `Array.map` inside; `exp_leway:` is `has no keyword parameter` before running. The 17 keywords are
   written once, in the signature, instead of `options.fetch(:leeway, 0)` fifteen times.
4. **The claim's type is stated where it is read**: `v = payload[name]; case v in Integer | Float | Rational
   then Arithmetic.to_i(v) in String then String.to_i(v) in nil then 0 else raise JWTInvalidPayload`. The
   gem writes `payload['exp'].to_i`, which is why its decode of `{"exp":"x"}` says *ExpiredSignature*
   (`"x".to_i == 0`) while its encode says *InvalidPayload*; the diff found the difference, the `case` made
   it explicit. With `--strict`, `Arithmetic.to_i(v)` on `v = payload[name]` (a Hash value: anything) is a
   `type` report until the `case`; a Ruby port would have passed `"x".to_i` silently.
5. **HMAC in Sake reads as the RFC**: `hmac_key(key, 64, 0x36) { |k| SHA256.digest(k) }` (the block hashes a
   long key, so one function serves three digests), `Array.pack(Array.map(bytes) { |b| b ^ pad }, "C*")`,
   `SHA256.digest(k_opad + SHA256.digest(k_ipad + String.b(msg)))`. Binary and UTF-8 Strings concatenated
   without an `EncodingError` as long as the UTF-8 side is ASCII (`String.b(msg)` for the message to be safe).
6. **Exception types without hierarchy**: 13 `class JWTX < Exception; end` lines, and the test's
   `show_error(e)` is a 13-branch `case e in JWTDecodeError then ...`. The Ruby twin's `case/when` needs
   `JWT::DecodeError` *last* (the subclasses match it first); Sake's has no such order trap, but also no way
   to say "any JWT error" except the `decode_error?` pattern `e in A | B | ... | M`.
7. **Where the checker helped**: `numeric_claim` returned `Arithmetic.to_i(v)` on `v => Integer | Float |
   Rational` at first; when the gem's `"x".to_i` behaviour had to be matched, adding the String branch was a
   `case` edit with every other reader of the value unchanged. `base64url_decode`'s `String.unpack1(t, "m0")
   || ""` is the `String | nil` of unpack1 made a String in one place.

## Built-ins requested

- `OpenSSL::HMAC` / `Digest.hmac`: HMAC is 20 lines here, but a built-in would be constant-time and fast
  (digest.sake's SHA256 is interpreted Sake: ~1 ms per block).
- `String.force_encoding` exists; a `String.unpack1(s, "m0")` that gives UTF-8 when the bytes are valid UTF-8
  would remove the one encoding trap found (or a `JSON.parse` that forces UTF-8, as Ruby's does).
- Exception families: a way to name a set of exception types once (`rescue JWTErrors`) instead of the
  `decode_error?(e)` pattern; Sake's "no hierarchy" is fine, a named union would do.
- `Integer.pow(a, b, mod)` exists; RS256 needs only PKCS#1 v1.5 padding and an ASN.1/PEM reader on top, if
  the port is ever wanted.
