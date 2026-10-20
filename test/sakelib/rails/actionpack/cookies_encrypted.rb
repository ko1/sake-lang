gem "actionpack", "8.1.3"
require "active_support/all"
require "active_support/messages/rotation_configuration"
require "action_dispatch"
ActionDispatch::Cookies

# Encrypted cookies (aes-256-gcm, and aes-256-cbc with an HMAC when authenticated encryption is off): written and
# read back, a tampered one, and cookies Rails wrote with the same secrets (so the format is Rails').
def configure(env, authenticated)
  env["action_dispatch.key_generator"] = ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new("b" * 64, iterations: 2))
  env["action_dispatch.secret_key_base"] = "b" * 64
  env["action_dispatch.authenticated_encrypted_cookie_salt"] = "authenticated encrypted cookie"
  env["action_dispatch.encrypted_cookie_salt"] = "encrypted cookie"
  env["action_dispatch.encrypted_signed_cookie_salt"] = "signed encrypted cookie"
  env["action_dispatch.use_authenticated_cookie_encryption"] = authenticated
  env["action_dispatch.cookies_serializer"] = :json
  env["action_dispatch.use_cookies_with_metadata"] = true
  env["action_dispatch.cookies_rotations"] = ActiveSupport::Messages::RotationConfiguration.new
end

# Written by Rails 8.1.3 with these secrets: encrypted[:fixed] = {value: {"made_by" => "rails", "n" => [1, 2]}} (gcm)
# and encrypted[:fixed_cbc] = "cbc from rails" (cbc)
FIXED = "fixed=5fQiPY7bViJ%2BnxG8IHKR%2FX7%2BRQI%2Bv3aKgYtLmce4Yzf2raF3eVy3bFEoZJM%2FfnDVkE0MRQIUZxdCyU5dtm4MIBq3IxW0%2Bk%2B4pNDfVjTMyFr8Fz%2B%2BU%2BQM%2FdHfR2GnhksCrA%3D%3D--eWKlbONAle%2B%2BNDVX--unXocTznbuawxOSRilYRQQ%3D%3D"
FIXED_CBC = "fixed_cbc=UGhXNkxKMCtqZWR3R1pqYzhyejkwbG1XOHRIRXZ4QlZKRUNGT1o0NEUrN2g5aEVCQ2dKLzMvY3lwUUUyWVp4OVJRVHorTG95T0RkSTVIakhSaENpSWFxbHlWT2FpeE82NGg1TXQ1SUk5a0dla0F4WnFQNW9JRzJPNnM2VkZJNXMtLWFQWWRKMW1PMllpakNDR1ZKNnhkN0E9PQ%3D%3D--7245568aba72b82e9a27fa7fabf481731f8d3053"

endpoint = ->(env) {
  jar = ActionDispatch::Request.new(env).cookie_jar
  case env["PATH_INFO"]
  when "/write"
    jar.encrypted[:user] = "ko1"
    jar.encrypted[:cart] = { value: [1, { "id" => 2 }], httponly: true }
    jar.permanent.encrypted[:remember] = 42
  when "/read"
    p([jar.encrypted[:user], jar.encrypted[:cart], jar.encrypted[:remember], jar[:user] != nil, jar.encrypted[:forged], jar.encrypted[:missing], jar.encrypted[:fixed], jar.encrypted[:fixed_cbc]])
    p(jar.encrypted[:renamed])
  end
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["ok"]]
}
app = ActionDispatch::Cookies.new(endpoint)

# The parts of an encrypted value: the ciphertext, the iv and the auth tag (gcm), or base64 data and an HMAC (cbc)
def shape(c)
  name, rest = c.split("=", 2)
  value = rest.split(";", 2)[0]
  parts = CGI.unescape(value).split("--")
  "#{name}=<#{parts.map(&:size).join(", ")}>#{rest.sub(/\A[^;]*/, "").sub(/expires=[^;]*/, "expires=<20 years>")}"
end

[true, false].each do |authenticated|
  puts(authenticated ? "-- aes-256-gcm" : "-- aes-256-cbc")
  env = Rack::MockRequest.env_for("http://www.example.com/write")
  configure(env, authenticated)
  _, headers, _ = app.call(env)
  set = headers["set-cookie"]
  set.each { |c| puts(shape(c)) }
  values = set.map { |c| c[/\A[^;]*/] }
  user = values[0].split("=", 2)[1]
  forged = user.sub(/\A./) { |d| d == "A" ? "B" : "A" }
  cookie = (values + ["forged=#{forged}", "renamed=#{user}", FIXED, FIXED_CBC]).join("; ")
  env = Rack::MockRequest.env_for("http://www.example.com/read", "HTTP_COOKIE" => cookie)
  configure(env, authenticated)
  app.call(env)
end
