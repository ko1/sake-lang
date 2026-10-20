# ActiveSupport::MessageEncryptor (AES-256-GCM and AES-256-CBC with its verifier, purpose, expiry, url_safe) on a key from KeyGenerator.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/message_encryptor"
require "active_support/key_generator"
require "active_support/core_ext/time"   # Time#advance, for expires_in
require "json"

ActiveSupport::Messages::Metadata.use_message_serializer_for_metadata = true   # Rails 7.1's default
ME = ActiveSupport::MessageEncryptor
p([ME.key_len, ME.key_len("aes-256-gcm"), ME.key_len("aes-128-gcm"), ME.default_cipher])
key = "k" * 32
gcm = ME.new(key, cipher: "aes-256-gcm", serializer: JSON)
cbc = ME.new(key, cipher: "aes-256-cbc", serializer: JSON)
puts("messages made by Ruby's gem (the IV is random, so these are fixed here):")
p(gcm.decrypt_and_verify("jy4M+IWt8jai1l/G7SWEZQcCsikJ5g7epH+Fq1A5ZrRTU8cbeAe9FYbJ6Oz5aqQ=--i+vQZDjceBOzq1F1--xp9zTiy32HCorpjnirgDBw==", purpose: :login))
p(gcm.decrypt_and_verify("jy4M+IWt8jai1l/G7SWEZQcCsikJ5g7epH+Fq1A5ZrRTU8cbeAe9FYbJ6Oz5aqQ=--i+vQZDjceBOzq1F1--xp9zTiy32HCorpjnirgDBw==", purpose: :other))
p(cbc.decrypt_and_verify("U3lHZGp4NW1tWHlMWm95RWJZTFRRUT09LS0zMFNZMDNiMjg5UUNUb3FUdVpydG9RPT0=--b620e2b50f40af56c27de11782a3bac5a1a00368"))
url = ME.new(key, cipher: "aes-256-gcm", serializer: JSON, url_safe: true)
p(url.decrypt_and_verify("EqiKdThqAbZsHg--g0M6FvBsVIejHibT--SiH13b-WcA6RTpQjJwRjLA"))
puts("round trips:")
m = gcm.encrypt_and_sign({ "user_id" => 7, "role" => "admin" })
p([m.split("--").map(&:size)[1..], gcm.decrypt_and_verify(m)])
m2 = cbc.encrypt_and_sign("hello", purpose: :share)
p([m2.count("-"), cbc.decrypt_and_verify(m2, purpose: :share), cbc.decrypt_and_verify(m2)])
m3 = gcm.encrypt_and_sign([1, 2], expires_at: Time.utc(2000, 1, 1))
p(gcm.decrypt_and_verify(m3))
m4 = gcm.encrypt_and_sign(42, expires_in: 3600)
p(gcm.decrypt_and_verify(m4))
m5 = url.encrypt_and_sign("a/b?c>>>")
p([m5.include?("+") || m5.include?("/") || m5.include?("="), url.decrypt_and_verify(m5)])
puts("errors:")
def try(label)
  print(label, ": ")
  p(yield)
rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
  puts("InvalidMessage: #{e.message}")
end
data, iv, tag = m.split("--")
try("tampered data") { gcm.decrypt_and_verify("#{data.reverse}--#{iv}--#{tag}") }
try("tampered tag") { gcm.decrypt_and_verify("#{data}--#{iv}--#{tag.sub(/\A./) { |c| c == "A" ? "B" : "A" }}") }
try("truncated tag") { gcm.decrypt_and_verify("#{data}--#{iv}--#{tag[0, 20]}") }
try("missing separator") { gcm.decrypt_and_verify("#{data}#{iv}#{tag}") }
try("wrong key") { ME.new("j" * 32, cipher: "aes-256-gcm", serializer: JSON).decrypt_and_verify(m) }
try("cbc, wrong signature") { cbc.decrypt_and_verify(m2.sub(/.\z/) { |c| c == "0" ? "1" : "0" }) }
try("cbc, another sign secret") { ME.new(key, "other", cipher: "aes-256-cbc", serializer: JSON).decrypt_and_verify(m2) }
begin
  ME.new("short", cipher: "aes-256-gcm", serializer: JSON).encrypt_and_sign("x")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
puts("with KeyGenerator (Rails' 1000 iterations, the encrypted cookie salt):")
kg = ActiveSupport::KeyGenerator.new("secret_key_base", iterations: 1000)
secret = kg.generate_key("authenticated encrypted cookie", ME.key_len("aes-256-gcm"))
puts(secret.unpack1("H*"))
cookie = ME.new(secret, cipher: "aes-256-gcm", serializer: JSON)
p(cookie.decrypt_and_verify(cookie.encrypt_and_sign({ "session_id" => "abc" }, purpose: "cookie.session"), purpose: "cookie.session"))
