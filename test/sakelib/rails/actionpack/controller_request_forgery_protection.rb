gem "actionpack", "8.1.3"
require "action_controller"
require "active_support/messages/rotation_configuration"

# Request forgery protection over a cookie session: protect_from_forgery with :exception, :null_session and
# :reset_session, skip_forgery_protection, the masked form token (as a param and as X-CSRF-Token), a token for
# another session, a malformed one, an unmasked raw token, and the cross-origin JavaScript check.
require_relative "controller_request_forgery_protection_decl"
class FormsController < ActionController::Base
  def new = render plain: form_authenticity_token
  def create = render plain: "created"
  def script = render js: "alert(1)"
  def raw = render plain: Base64.urlsafe_encode64(real_csrf_token, padding: false)
end
class OpenController < FormsController
end
class NullController < ActionController::Base
  def login
    session[:user] = "ann"
    render plain: "logged in #{form_authenticity_token != ""}"
  end
  def create = render plain: "user=#{session[:user].inspect}"
end
class ResetController < ActionController::Base
  def login
    session[:user] = "bob"
    render plain: "logged in"
  end
  def create = render plain: "user=#{session[:user].inspect}"
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  ["forms", "open"].each do |r|
    get "#{r}/new", to: "#{r}#new"
    post r, to: "#{r}#create"
    get "#{r}/script", to: "#{r}#script"
    get "#{r}/raw", to: "#{r}#raw"
  end
  ["null", "reset"].each do |r|
    get "#{r}/login", to: "#{r}#login"
    post r, to: "#{r}#create"
  end
end

def configure(env)
  env["action_dispatch.key_generator"] = ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new("b" * 64, iterations: 2))
  env["action_dispatch.signed_cookie_salt"] = "signed cookie"
  env["action_dispatch.cookies_serializer"] = :json
  env["action_dispatch.use_cookies_with_metadata"] = true
  env["action_dispatch.cookies_rotations"] = ActiveSupport::Messages::RotationConfiguration.new
end
stack = ActionDispatch::MiddlewareStack.new
stack.use ActionDispatch::Cookies
stack.use ActionDispatch::Session::CookieStore, key: "_app_session"
stack.use ActionDispatch::Flash
app = stack.build(set)

# Returns the session cookie to send next and the body.
def request(app, method, path, cookie, query = nil, headers = {})
  env = Rack::MockRequest.env_for("http://www.example.com#{path}#{query ? "?#{query}" : ""}", method: method)
  env["HTTP_COOKIE"] = cookie if cookie
  headers.each { |k, v| env[k] = v }
  configure(env)
  begin
    status, hs, body = app.call(env)
  rescue => e
    puts("#{method} #{path} -> #{e.class.name}: #{e.message.slice(0, 60)}")
    return [cookie, ""]
  end
  out = +""
  body.each { |s| out << s }
  sc = hs["set-cookie"]
  sc = sc.first if sc.is_a?(Array)
  shown = out.size > 40 ? "(#{out.size} chars)" : out.inspect
  puts("#{method} #{path} -> #{status} #{shown} cookie=#{!sc.nil?}")
  [sc ? sc[/\A[^;]*/] : cookie, out]
end

def esc(s) = Rack::Utils.escape(s)

c, token = request(app, "GET", "/forms/new", nil)
request(app, "POST", "/forms", c)
request(app, "POST", "/forms", c, "authenticity_token=#{esc(token)}")
request(app, "POST", "/forms", c, nil, { "HTTP_X_CSRF_TOKEN" => token })
c2, token2 = request(app, "GET", "/forms/new", c)
request(app, "POST", "/forms", c2, "authenticity_token=#{esc(token2)}")
request(app, "POST", "/forms", c, "authenticity_token=#{esc(token)}")
other, other_token = request(app, "GET", "/forms/new", nil)
request(app, "POST", "/forms", c, "authenticity_token=#{esc(other_token)}")
request(app, "POST", "/forms", c, "authenticity_token=not-base64!!")
request(app, "POST", "/forms", c, "authenticity_token=YWJj")
_, raw = request(app, "GET", "/forms/raw", c)
request(app, "POST", "/forms", c, "authenticity_token=#{esc(raw)}")
request(app, "GET", "/forms/script", c)
request(app, "GET", "/forms/script", c, nil, { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" })
request(app, "POST", "/open", c)
request(app, "GET", "/open/script", c)
n, _ = request(app, "GET", "/null/login", nil)
request(app, "POST", "/null", n)
r, _ = request(app, "GET", "/reset/login", nil)
r2, _ = request(app, "POST", "/reset", r)
request(app, "POST", "/reset", r2)
p(ActionController::RequestForgeryProtection::ProtectionMethods::Exception.name.demodulize.underscore.to_sym)
begin
  ActionController::Base.send(:protection_method_class, :nope)
rescue ArgumentError => e
  puts(e.message)
end
