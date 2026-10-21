# Credentials (railties fork)

Rails' encrypted credentials: `config/credentials.yml.enc` decrypted with `config/master.key` (or `RAILS_MASTER_KEY`),
read as YAML into nested OrderedOptions, written back, and the `secret_key_base` lookup the application's key
generator and cookies start from. The test decrypts the file `rails new` wrote for blog_rb (copied to
`test/sakelib/rails/railties/fixtures/config/`), and a file Sake writes is read by Ruby's ActiveSupport (checked by hand).

| Ruby (8.1.3 lib/) | Sake | Ruby code lines | Sake code lines |
|---|---|---:|---:|
| activesupport active_support/encrypted_file.rb | rails/activesupport/active_support/encrypted_file.sake (with Marshal of a String, 30 lines) | 89 | 121 |
| activesupport active_support/encrypted_configuration.rb | encrypted_configuration.sake | 75 | 74 |
| railties rails/application.rb (credentials, encrypted), application/configuration.rb (secret_key_base, secret_key_base=, credentials_defaults, generate_local_secret), commands/credentials/credentials_command.rb (show, fetch, missing_credentials!) | rails/railties/rails/application/credentials.sake | ≈60 of 130 + ≈40 | 67 |

## API (what Rails::Application calls)

```ruby
content_path, key_path = Rails::Credentials.credentials_defaults(root, env)       # config.credentials' defaults
creds = Rails::Credentials.encrypted(root, content_path, key_path: key_path, env_key: "RAILS_MASTER_KEY", require_master_key: false)
secret = Rails::Credentials.secret_key_base(root, env, creds)                      # config.secret_key_base (memoize it)
Rails::Credentials.checked_secret_key_base(root, env, value)                       # config.secret_key_base = value
Rails::Credentials.show(creds, key_path, content_path)                             # bin/rails credentials:show (raises MissingCredentials)
Rails::Credentials.fetch(creds, "aws.access_key_id", key_path, content_path)       # bin/rails credentials:fetch
ActiveSupport::EncryptedConfiguration.option(creds, :secret_key_base)              # creds.secret_key_base
ActiveSupport::EncryptedConfiguration.dig(creds, :aws, :access_key_id)             # creds.dig(...); also [], config, read, write, change
```

## The shape

- `class EncryptedConfiguration < EncryptedFile` is a paste; Ruby's `super` in `read` is EncryptedFile's body under a
  second name, `encrypted_file_read`, which the configuration's `read` calls (rescuing MissingContentError → "").
- `delegate_missing_to :options` became the four calls an app makes (`[]`, `dig`, `option`, `keys`), each forwarding
  to the OrderedOptions of the config. `creds.secret_key_base` is `EC.option(creds, :secret_key_base)` (OrderedOptions'
  method_missing form, so `:secret_key_base!` raises for a blank value as Ruby's). `key?` is EncryptedFile's (has a
  key), not delegated: Ruby's class answers it first, and Sake reports the clash of two `key?` functions.
- **Marshal.** Rails' EncryptedFile encrypts `Marshal.dump(contents)` (`serializer: Marshal`); the port's
  MessageEncryptor serializes with JSON only. The file dumps and loads the one value it holds, a String
  (`\x04\bI"<len>...\x06:\x06ET`, Marshal's w_long lengths; a binary String without the encoding ivar), and calls the
  encryptor's `encrypt`/`decrypt` (`sign`/`verify` are the identity in aes-128-gcm) as `encrypt_and_sign` does without
  metadata. Anything else in the plaintext is InvalidMessage. A Marshal built-in would make this a one-line
  serializer, but a String is all credentials ever hold, so it is not asked for.
- Paths are Strings (`Rails.root.join(p)` = `File.expand_path(p, root)`); the per-environment
  `config/credentials/<env>.yml.enc` and `.key` come first, as Rails.
- secret_key_base: `SECRET_KEY_BASE_DUMMY` → tmp/local_secret.txt; else `ENV["SECRET_KEY_BASE"]`, the credentials',
  and in development/test the local secret (made with SecureRandom.hex(64) if missing); then the setter's checks with
  Rails' two ArgumentError messages.

## Left out

- `credentials:edit` (an editor; `EncryptedFile.change` is there, writing through a temp file as Rails), `diff` (git
  attributes), `encrypted:*` commands, the credentials generator (`rails new` writes the file: the lead's generator
  can call `EncryptedFile.generate_key` and `write`).
- InvalidContentError's YAML message is sakelib/yaml's, not Psych's (the test does not compare it).
- The Ruby test resets Rails' memoized `@secret_key_base` with instance_variable_set between cases (a new process
  would look again); the Sake functions do not memoize.

## Test

`test/sakelib/rails/railties/credentials.{sake,rb}`: the app's credentials (paths, secret_key_base, keys, dig, `!`),
`credentials:show`, a new key and file written/read/changed (nested keys, an Array, UTF-8), fetch of a dotted path,
the wrong key (InvalidMessage "AEAD authentication tag verification failed"), MissingKeyError, no key / no file,
InvalidKeyLengthError, a key from ENV, secret_key_base from credentials / ENV / the local secret, and the production
errors. Same output on both sides. `bin/sake -c --strict`: 1.24-1.28 s, 59 MB (load 1.2).

## Friction (what I wrote first → the message → what I wrote instead)

1. `String.force_encoding(String.dup(body), ...)` → "undefined function `String.dup`; `dup` is defined in
   `Kernel.dup`, `Array.dup`, `Hash.dup`" → `dup(body)`. The hint named the fix.
2. `def key?(c, key)` (delegated) next to the pasted `key?(f)` of EncryptedFile: I deleted it before checking; in
   Ruby the class's own method wins over method_missing, so the delegation was wrong anyway.
3. `p nokey.key?` prints the key in Ruby (a String or nil), which is random per run → both sides print `key? != nil`.
   EncryptedFile#key? first returned a Boolean in my port; Ruby's returns the key, so it does now too.

What read well: the binary work (`Array.pack(Any[k], "H*")`, `String.getbyte`, `Integer.chr`, `String.b`, byteslice)
behaved as Ruby's, and the whole test matched on its first run after the one name error. The MessageEncryptor of
part 10 decrypted Rails' aes-128-gcm file unchanged.
