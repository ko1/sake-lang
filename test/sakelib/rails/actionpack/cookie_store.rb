gem "actionpack", "8.1.3"
require "active_support/all"
require "active_support/messages/rotation_configuration"
require "action_dispatch"
require "base64"
require "json"
ActionDispatch::Cookies

# The app's env_config, without secret_key_base: the session goes in the signed jar (Rails: encrypted with one).
def configure(env)
  env["action_dispatch.key_generator"] = ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new("b" * 64, iterations: 2))
  env["action_dispatch.signed_cookie_salt"] = "signed cookie"
  env["action_dispatch.cookies_serializer"] = :json
  env["action_dispatch.use_cookies_with_metadata"] = true
  env["action_dispatch.cookies_rotations"] = ActiveSupport::Messages::RotationConfiguration.new
end

endpoint = ->(env) {
  session = ActionDispatch::Request.new(env).session
  case env["PATH_INFO"]
  when "/login"
    session[:user_id] = 42
  when "/show"
    p([session[:user_id], session["session_id"].to_s.size, session.loaded?])
  when "/logout"
    ActionDispatch::Request.new(env).reset_session
  end
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["ok"]]
}
app = ActionDispatch::Cookies.new(ActionDispatch::Session::CookieStore.new(endpoint, key: "_app_session"))

# The cookie's session, with the random id hidden.
def decode(set_cookie)
  return nil unless set_cookie
  value = Rack::Utils.unescape(set_cookie[/\A_app_session=([^;]*)/, 1])
  envelope = JSON.parse(Base64.strict_decode64(value.split("--").first))
  data = JSON.parse(Base64.strict_decode64(envelope["_rails"]["message"]))
  [envelope["_rails"]["pur"], data.transform_values { |v| v.is_a?(String) && v.size == 32 ? "<sid>" : v }, set_cookie[/;.*/]]
end

def run(app, path, cookie)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}")
  env["HTTP_COOKIE"] = cookie if cookie
  configure(env)
  _, headers, _ = app.call(env)
  sc = headers["set-cookie"]
  sc = sc.first if sc.is_a?(Array)
  p([path, decode(sc)])
  sc ? sc[/\A[^;]*/] : cookie
end

c = run(app, "/show", nil)
c = run(app, "/login", c)
c = run(app, "/show", c)
c = run(app, "/logout", c)
c = run(app, "/show", c)
run(app, "/show", "_app_session=forged--0123")
