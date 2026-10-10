require "jwt"
require "openssl"

# The Sake program (jwt.sake) with the real gem (jwt 3.2). the JWT::X errors have the same names there; Ruby's options
# Hash is Sake's keywords; JWT.base64url_encode / hmac_sha256 are JWT::Base64.url_encode / OpenSSL::HMAC.

def show_error(e)
  case e
  when JWT::VerificationError then "VerificationError: #{e.message}"
  when JWT::ExpiredSignature then "ExpiredSignature: #{e.message}"
  when JWT::ImmatureSignature then "ImmatureSignature: #{e.message}"
  when JWT::InvalidIatError then "InvalidIatError: #{e.message}"
  when JWT::IncorrectAlgorithm then "IncorrectAlgorithm: #{e.message}"
  when JWT::InvalidIssuerError then "InvalidIssuerError: #{e.message}"
  when JWT::InvalidAudError then "InvalidAudError: #{e.message}"
  when JWT::InvalidSubError then "InvalidSubError: #{e.message}"
  when JWT::InvalidJtiError then "InvalidJtiError: #{e.message}"
  when JWT::InvalidPayload then "InvalidPayload: #{e.message}"
  when JWT::Base64DecodeError then "Base64DecodeError: #{e.message}"
  when JWT::DecodeError then "DecodeError: #{e.message}"   # last: the others are its subclasses
  when JWT::EncodeError then "EncodeError: #{e.message}"
  else "other: #{e.message}"
  end
end

# 1. encode: the token of jwt.io's example, byte for byte
puts "-- encode"
payload = {"sub" => "1234567890", "name" => "John Doe", "iat" => 1516239022}
token = JWT.encode(payload, "your-256-bit-secret", "HS256")
puts token
puts JWT.encode({"a" => 1}, "s")
puts JWT.encode({"a" => 1}, "s", "HS384")
puts JWT.encode({"a" => 1}, "s", "HS512")
puts JWT.encode({"a" => 1}, nil, "none")
puts JWT.encode({"a" => 1}, "s", "HS256", {"kid" => "k1", "typ" => "JWT"})
puts JWT.encode({"a" => 1}, "s", "HS256", {kid: "k1"})
puts JWT.encode({a: 1, b: [1, 2], c: nil, d: 1.5, e: "é", f: true}, "s", "HS256")
puts JWT.encode({"exp" => 1516239022.5}, "s", "HS256")
puts JWT.encode({"a" => 1}, "x" * 100, "HS256")      # key longer than the HMAC block: hashed
puts JWT.encode({"a" => 1}, "x" * 64, "HS256")       # exactly one block
puts JWT.encode({"a" => 1}, "k" * 200, "HS512")
puts JWT.encode({"msg" => "日本語"}, "鍵", "HS256")   # UTF-8 payload and key
puts JWT.encode({}, "s")
[{"iat" => "x"}, {"exp" => "x"}, {"nbf" => [1]}].each do |bad|
  begin
    JWT.encode(bad, "s", "HS256")
  rescue => e
    puts show_error(e)
  end
end
["FOO", "hs256"].each do |alg|
  begin
    JWT.encode({"a" => 1}, "s", alg)
  rescue => e
    puts show_error(e)
  end
end
begin
  JWT.encode({"a" => 1}, "", "HS256")
rescue => e
  puts show_error(e)
end

# 2. decode
puts "-- decode"
p JWT.decode(token, "your-256-bit-secret", true, {algorithm: "HS256"})
p JWT.decode(token, "your-256-bit-secret")
p JWT.decode(token, nil, false)
p JWT.decode(token, "wrong", false)
p JWT.decode(JWT.encode({"a" => 1}, "s", "HS512"), "s", true, {algorithm: "HS512"})
p JWT.decode(JWT.encode({"a" => 1}, "s", "HS384"), "s", true, {algorithms: ["HS256", "HS384"]})
p JWT.decode(JWT.encode({"a" => 1}, "s", "HS256", {"kid" => "k1"}), "s")
p JWT.decode(JWT.encode({a: 1, b: [1, 2], c: nil, d: 1.5, e: "é"}, "s", "HS256"), "s")
p JWT.decode(JWT.encode({"exp" => 1516239022.5}, "s"), "s", false)
p JWT.decode(JWT.encode({"msg" => "日本語"}, "鍵", "HS256"), "鍵")
# errors
[
  [token, "wrong", true],
  [token, nil, true],
  [token, "", true],
  [token + "x", "your-256-bit-secret", true],
  ["abc", "s", true],
  ["a.b.c", "s", true],
  ["", "s", true],
  ["eyJhbGciOiJIUzI1NiJ9.e30.x", "s", true],
  ["eyJhbGciOiJIUzI1NiJ9.!!!.x", "s", true],
  ["eyJhbGciOiJIUzI1NiJ9.eyJhIjoxfQ", "s", true],
  ["eyJhbGciOiJIUzI1NiJ9.eyJhIjoxfQ", "s", false],
  ["eyJhbGciOiJIUzI1NiJ9.eyJhIjoxfQ.YWJj", "s", true],
  ["eyJhbGciOiJGT08ifQ.eyJhIjoxfQ.YWJj", "s", true],
  ["eyJhbGciOiJIUzI1NiJ9.eyJleHAiOiJ4In0.sig", "s", false]
].each do |tok, key, verify|
  begin
    p JWT.decode(tok, key, verify)
  rescue => e
    puts show_error(e)
  end
end
# none is rejected unless asked for
none = JWT.encode({"a" => 1}, nil, "none")
begin
  JWT.decode(none, nil)
rescue => e
  puts show_error(e)
end
begin
  JWT.decode(none, nil, true, {algorithm: "none"})
rescue => e
  puts show_error(e)
end
p JWT.decode(none, nil, false)
begin
  JWT.decode(token, "your-256-bit-secret", true, {algorithm: "HS512"})
rescue => e
  puts show_error(e)
end
begin
  JWT.decode(token, "your-256-bit-secret", true, {algorithm: "FOO"})
rescue => e
  puts show_error(e)
end

# 3. claims
puts "-- claims"
past = 1516239022
future = 4102444800
expired = JWT.encode({"exp" => past}, "s")
begin
  JWT.decode(expired, "s")
rescue => e
  puts show_error(e)
end
p JWT.decode(expired, "s", true, {verify_expiration: false})
p JWT.decode(expired, "s", true, {leeway: 10 ** 10})
p JWT.decode(expired, "s", true, {exp_leeway: 10 ** 10})
p JWT.decode(JWT.encode({"exp" => future}, "s"), "s")
begin
  JWT.decode(JWT.encode({"exp" => future}, "s"), "s", true, {leeway: -(10 ** 10)})
rescue => e
  puts show_error(e)
end
immature = JWT.encode({"nbf" => future}, "s")
begin
  JWT.decode(immature, "s")
rescue => e
  puts show_error(e)
end
p JWT.decode(immature, "s", true, {verify_not_before: false})
p JWT.decode(immature, "s", true, {nbf_leeway: 10 ** 10})
p JWT.decode(JWT.encode({"nbf" => past}, "s"), "s")
p JWT.decode(JWT.encode({"iat" => future}, "s"), "s")      # iat is not checked by default
begin
  JWT.decode(JWT.encode({"iat" => future}, "s"), "s", true, {verify_iat: true})
rescue => e
  puts show_error(e)
end
p JWT.decode(JWT.encode({"iat" => past}, "s"), "s", true, {verify_iat: true})
begin
  JWT.decode("eyJhbGciOiJIUzI1NiJ9.eyJleHAiOiJ4In0.sig", "s", false)
rescue => e
  puts show_error(e)
end
# a payload with a non-numeric exp, signed by hand: InvalidPayload at decode
header = "eyJhbGciOiJIUzI1NiJ9"
body = JWT::Base64.url_encode("{\"exp\":\"x\"}")
sig = JWT::Base64.url_encode(OpenSSL::HMAC.digest("SHA256", "s", header + "." + body))
begin
  JWT.decode(header + "." + body + "." + sig, "s")
rescue => e
  puts show_error(e)
end
# iss / aud / sub / jti
iss = JWT.encode({"iss" => "me"}, "s")
p JWT.decode(iss, "s", true, {iss: "me", verify_iss: true})
p JWT.decode(iss, "s", true, {iss: ["you", "me"], verify_iss: true})
p JWT.decode(iss, "s", true, {iss: "you"})                          # not verified unless asked
begin
  JWT.decode(iss, "s", true, {iss: "you", verify_iss: true})
rescue => e
  puts show_error(e)
end
begin
  JWT.decode(JWT.encode({"a" => 1}, "s"), "s", true, {iss: "you", verify_iss: true})
rescue => e
  puts show_error(e)
end
aud = JWT.encode({"aud" => "a"}, "s")
p JWT.decode(aud, "s", true, {aud: "a", verify_aud: true})
begin
  JWT.decode(aud, "s", true, {aud: "b", verify_aud: true})
rescue => e
  puts show_error(e)
end
p JWT.decode(JWT.encode({"aud" => ["a", "b"]}, "s"), "s", true, {aud: "b", verify_aud: true})
p JWT.decode(aud, "s", true, {aud: ["a", "c"], verify_aud: true})
begin
  JWT.decode(JWT.encode({"x" => 1}, "s"), "s", true, {aud: "b", verify_aud: true})
rescue => e
  puts show_error(e)
end
sub = JWT.encode({"sub" => "a"}, "s")
p JWT.decode(sub, "s", true, {sub: "a", verify_sub: true})
begin
  JWT.decode(sub, "s", true, {sub: "b", verify_sub: true})
rescue => e
  puts show_error(e)
end
p JWT.decode(JWT.encode({"jti" => "id1"}, "s"), "s", true, {verify_jti: true})
[{"jti" => ""}, {"x" => 1}].each do |pl|
  begin
    JWT.decode(JWT.encode(pl, "s"), "s", true, {verify_jti: true})
  rescue => e
    puts show_error(e)
  end
end
# claims are not checked without verify
p JWT.decode(expired, "s", false)
p JWT.decode(immature, nil, false)

# 4. the pieces: HMAC (RFC 4231 test case 2) and Base64url
puts "-- hmac"
puts OpenSSL::HMAC.hexdigest("SHA256", "Jefe", "what do ya want for nothing?")
puts OpenSSL::HMAC.hexdigest("SHA384", "Jefe", "what do ya want for nothing?")
puts OpenSSL::HMAC.hexdigest("SHA512", "Jefe", "what do ya want for nothing?")
puts OpenSSL::HMAC.hexdigest("SHA256", "k" * 100, "msg")
puts JWT::Base64.url_encode("\xFB\xFF\xBF")
p JWT::Base64.url_decode("-_-_")
p JWT::Base64.url_decode("YQ")
p JWT::Base64.url_decode("")
begin
  JWT::Base64.url_decode("Y")
rescue => e
  puts show_error(e)
end
begin
  JWT::Base64.url_decode("!!!!")
rescue => e
  puts show_error(e)
end
