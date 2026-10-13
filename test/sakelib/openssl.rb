require "openssl"

keys = ["key", "", "k" * 64, "k" * 65, "k" * 200, "日本語の鍵"]
data = ["The quick brown fox jumps over the lazy dog", "", "a" * 1000, "héllo ✓"]
algs = ["MD5", "SHA1", "SHA256", "SHA384", "SHA512", "sha256"]
algs.each do |alg|
  keys.each do |key|
    data.each { |d| puts "#{alg} #{key.bytesize} #{d.bytesize} #{OpenSSL::HMAC.hexdigest(alg, key, d)}" }
  end
end
# RFC 4231 test case 2
puts OpenSSL::HMAC.hexdigest("SHA256", "Jefe", "what do ya want for nothing?")
p OpenSSL::HMAC.digest("SHA512", "key", "data").bytesize
puts OpenSSL::HMAC.base64digest("SHA1", "key", "data")
begin
  OpenSSL::HMAC.hexdigest("XYZ", "key", "data")
rescue OpenSSL::Digest::DigestError => e
  puts e.message.split(":")[0]
end
