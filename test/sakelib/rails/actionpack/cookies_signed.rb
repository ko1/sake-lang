gem "actionpack", "8.1.3"
require "active_support/all"
require "active_support/messages/rotation_configuration"
require "action_dispatch"
ActionDispatch::Cookies

# The app's env_config (Rails::Application#env_config) for signed cookies.
def configure(env)
  env["action_dispatch.key_generator"] = ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new("b" * 64, iterations: 2))   # Rails apps use 1000: see the notes for the time it takes here
  env["action_dispatch.signed_cookie_salt"] = "signed cookie"
  env["action_dispatch.cookies_serializer"] = :json
  env["action_dispatch.use_cookies_with_metadata"] = true
  env["action_dispatch.cookies_rotations"] = ActiveSupport::Messages::RotationConfiguration.new
end

endpoint = ->(env) {
  jar = ActionDispatch::Request.new(env).cookie_jar
  case env["PATH_INFO"]
  when "/write"
    jar.signed[:user] = "ko1"
    jar.signed[:cart] = { value: [1, { "id" => 2 }], httponly: true }
    jar.permanent.signed[:remember] = 42
  when "/read"
    p([jar.signed[:user], jar.signed[:cart], jar.signed[:remember], jar[:user] != nil, jar.signed[:forged], jar.signed[:missing]])
  end
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["ok"]]
}
app = ActionDispatch::Cookies.new(endpoint)

env = Rack::MockRequest.env_for("http://www.example.com/write")
configure(env)
_, headers, _ = app.call(env)
set = headers["set-cookie"].map { |c| c.sub(/expires=[^;]*/, "expires=<20 years>") }
set.each { |c| puts(c) }
cookie = set.map { |c| c[/\A[^;]*/] }.join("; ") + "; forged=" + set[0][/=([^;]*)/, 1].sub(/\h\z/) { |d| d == "0" ? "1" : "0" }

env = Rack::MockRequest.env_for("http://www.example.com/read", "HTTP_COOKIE" => cookie)
configure(env)
app.call(env)
