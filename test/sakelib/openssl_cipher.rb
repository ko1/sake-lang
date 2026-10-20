require "openssl"
require "base64"

# ActiveSupport::MessageEncryptor's steps: a key from PBKDF2, AES-256-GCM with an auth tag, AES-256-CBC with padding.
key = OpenSSL::KDF.pbkdf2_hmac("secret_key_base", salt: "authenticated encrypted cookie", iterations: 1000, length: 32, hash: "sha256")
puts key.unpack1("H*")
puts OpenSSL::PKCS5.pbkdf2_hmac("secret_key_base", "signed cookie", 1000, 64, "sha1").unpack1("H*")
["aes-256-gcm", "aes-256-cbc", "aes-128-gcm"].each do |name|
  c = OpenSSL::Cipher.new(name)
  puts "#{c.name} #{c.key_len} #{c.iv_len} #{c.block_size} #{c.authenticated?}"
end
["", "a", "sixteen bytes!!!", "日本語のメッセージ" * 5].each do |msg|
  c = OpenSSL::Cipher.new("aes-256-gcm")
  c.encrypt
  c.key = key
  c.iv = "0123456789ab"
  c.auth_data = ""
  data = c.update(msg) + c.final
  tag = c.auth_tag(16)
  puts "gcm #{Base64.strict_encode64(data)}--#{Base64.strict_encode64(tag)}"
  d = OpenSSL::Cipher.new("aes-256-gcm")
  d.decrypt
  d.key = key
  d.iv = "0123456789ab"
  d.auth_tag = tag
  d.auth_data = ""
  plain = d.update(data) + d.final
  puts plain.force_encoding("UTF-8") == msg
  cbc = OpenSSL::Cipher.new("aes-256-cbc")
  cbc.encrypt
  cbc.key = key
  cbc.iv = "0123456789abcdef"
  puts "cbc #{Base64.strict_encode64(cbc.update(msg) + cbc.final)}"
end
begin
  d = OpenSSL::Cipher.new("aes-256-gcm")
  d.decrypt
  d.key = key
  d.iv = "0123456789ab"
  d.auth_tag = "x" * 16
  d.update("abc")
  d.final
rescue OpenSSL::Cipher::CipherError => e
  puts "CipherError #{e.message}"
end
iv = OpenSSL::Cipher.new("aes-256-gcm").encrypt.random_iv
p iv.bytesize
