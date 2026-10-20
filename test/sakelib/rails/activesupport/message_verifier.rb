# ActiveSupport::MessageVerifier (JSON, purpose, expiry, SHA256, url_safe) and KeyGenerator (PBKDF2).
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/message_verifier"
require "active_support/key_generator"
require "json"

ActiveSupport::Messages::Metadata.use_message_serializer_for_metadata = true   # Rails 7.1's default
v = ActiveSupport::MessageVerifier.new("s3krit", serializer: JSON)
m = v.generate({ "user_id" => 7, "role" => "admin" })
puts(m)
p([v.verified(m), v.valid_message?(m)])
tampered = m[0..-2] + (m[-1] == "0" ? "1" : "0")
p([v.verified(tampered), v.valid_message?(tampered), v.verified(nil), v.verified("garbage")])
begin
  v.verify(tampered)
rescue ActiveSupport::MessageVerifier::InvalidSignature => e
  puts("InvalidSignature: #{e.message}")
end
puts("purpose:")
m2 = v.generate("hello", purpose: :login)
puts(m2)
p([v.verified(m2, purpose: :login), v.verified(m2), v.verified(m2, purpose: :other)])
begin
  v.verify(m2, purpose: :other)
rescue ActiveSupport::MessageVerifier::InvalidSignature => e
  puts("InvalidSignature: #{e.message}")
end
puts("expiry:")
m3 = v.generate([1, 2], expires_at: Time.utc(2000, 1, 1))
puts(m3)
p(v.verified(m3))
begin
  v.verify(m3)
rescue ActiveSupport::MessageVerifier::InvalidSignature => e
  puts("InvalidSignature: #{e.message}")
end
m4 = v.generate(42, expires_at: Time.utc(2100, 1, 1, 12, 30, 15), purpose: "share")
puts(m4)
p(v.verified(m4, purpose: "share"))
puts("SHA256, url_safe:")
v2 = ActiveSupport::MessageVerifier.new("s3krit", serializer: JSON, digest: "SHA256", url_safe: true)
m5 = v2.generate("a/b?c>>>")
puts(m5)
p([v2.verified(m5), v.verified(m5)])
puts("a signed message that is not JSON:")
bad = Base64.strict_encode64("not json")
bad = "#{bad}--#{OpenSSL::HMAC.hexdigest("SHA1", "s3krit", bad)}"
begin
  v.verified(bad)
rescue JSON::ParserError => e
  puts("JSON::ParserError")
end
puts("key generator:")
kg = ActiveSupport::KeyGenerator.new("secret_key_base", iterations: 3)
k1 = kg.generate_key("signed cookie", 32)
puts(k1.unpack1("H*"))
kg256 = ActiveSupport::KeyGenerator.new("secret_key_base", iterations: 2, hash_digest_class: OpenSSL::Digest::SHA256)
puts(kg256.generate_key("authenticated encrypted cookie", 32).unpack1("H*"))
puts(ActiveSupport::KeyGenerator.new("secret_key_base").generate_key("signed cookie").unpack1("H*"))   # the default 2**16 iterations, 64 bytes
caching = ActiveSupport::CachingKeyGenerator.new(kg)
p(caching.generate_key("signed cookie", 32) == k1)
v3 = ActiveSupport::MessageVerifier.new(k1, serializer: JSON)
p(v3.verified(v3.generate("with a derived key")))
