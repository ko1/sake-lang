# bcrypt

`require "bcrypt"`: the bcrypt gem's (bcrypt-ruby 3.1) `BCrypt::Password` and `BCrypt::Engine`, for
ActiveModel::SecurePassword (2026-10-20). The hash itself is the built-in `String.crypt` (Ruby's `String#crypt`),
which on Linux is libxcrypt's bcrypt: openwall's crypt_blowfish, the same code the gem bundles, so digests are the
gem's (the OpenBSD vectors in test/samples/bcrypt.strict.sake match). Salts are `$2a$`, the cost and 16 bytes of
`OpenSSL::Random` in bcrypt's base64, as the gem makes them. Where libc's crypt has no bcrypt (macOS),
`hash_secret` raises `BCrypt::Errors::InvalidSalt`.

## API

| Ruby | Sake | |
|---|---|---|
| `BCrypt::Password.create(secret, cost: 4)` | the same | same |
| `BCrypt::Password.new(digest)` | the same | same; an invalid hash raises `BCrypt::Errors::InvalidHash` |
| `pw == secret`, `pw.is_password?(secret)` | `pw == secret`, `BCrypt::Password.is_password?(pw, secret)` | same |
| `pw.salt`, `pw.cost`, `pw.version`, `pw.checksum`, `pw.to_s` | `BCrypt::Password.salt(pw)`, ... | same |
| `BCrypt::Engine.hash_secret(secret, salt)`, `generate_salt(cost)`, `valid_salt?`, `autodetect_cost` | the same | same |
| `BCrypt::Engine::MIN_COST`, `DEFAULT_COST`, `MAX_COST`, `MAX_SECRET_BYTESIZE` | `BCrypt::Engine.MIN_COST`, ... | constants are functions |
| `BCrypt::Engine.cost = 10` | — | no global state: `Engine.cost` is the default, 12 |
| `rescue BCrypt::Errors::BCryptError` | the same | BCryptError is a module the four error classes include |

The gem's Password is a String subclass; here it is a class holding the String (`raw`), whose `to_s` and
`inspect` are the String's, so `"#{pw}"` and `p(pw)` print as in Ruby. Its `==` takes a String (a secret) or
another Password (equal hashes), since Sake's `==` of a class is also used to compare two of its values.

## Not ported

`BCrypt::Engine.calibrate`, the gem's `cost=` setter, JRuby's path. Secrets longer than 72 bytes are cut at 72 by
crypt, as by the gem's C code.

## Tests

`test/samples/bcrypt.strict.sake` (create / new / == with cost 4, three OpenBSD vectors, the parts of a hash, the
errors). There is no Ruby comparison: the bcrypt gem is not installed on this machine.
