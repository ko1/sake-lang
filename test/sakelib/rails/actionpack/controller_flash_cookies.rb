gem "actionpack", "8.1.3"
require "active_support/all"
require "active_support/messages/rotation_configuration"
require "action_controller"

# A controller behind the cookie, session and flash middleware: redirect_to with notice:/alert:/flash:, the flash
# on the next request, flash.now, the alert/notice readers, cookies[:x] = (with options) and delete, the session,
# reset_session.
require_relative "controller_flash_cookies_decl"
class NotesController < ActionController::Base
  def create = redirect_to "/notes", notice: "Note saved"
  def fail = redirect_to "/notes", alert: "Not saved", flash: { "extra" => "more" }
  def index
    f = flash
    render plain: "notice=#{notice.inspect} alert=#{alert.inspect} extra=#{f[:extra].inspect} visits=#{session[:visits]}"
  end
  def now
    flash.now[:info] = "just now"
    render plain: "info=#{flash[:info].inspect}"
  end
  def remember
    jar = cookies
    jar[:theme] = "dark"
    jar[:lang] = { value: "ja", path: "/notes", httponly: true }
    render plain: "remembered"
  end
  def recall = render plain: "theme=#{cookies[:theme].inspect} lang=#{cookies[:lang].inspect}"
  def forget
    cookies.delete(:theme)
    render plain: "forgotten"
  end
  def logout
    reset_session
    render plain: "visits=#{session[:visits].inspect}"
  end

  private
  def count_visit
    v = session[:visits]
    session[:visits] = (v.is_a?(Integer) ? v : 0) + 1
  end
end


set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :notes, only: [:index, :create]
  ["fail", "now", "remember", "recall", "forget", "logout"].each { |a| get "notes/#{a}", to: "notes##{a}" }
end

# Rails.application.env_config, which Rails::Engine#call merges into the env before the stack
def configure(env)
  env["action_dispatch.key_generator"] = ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new("b" * 64, iterations: 2))
  env["action_dispatch.signed_cookie_salt"] = "signed cookie"
  env["action_dispatch.cookies_serializer"] = :json
  env["action_dispatch.use_cookies_with_metadata"] = true
  env["action_dispatch.cookies_rotations"] = ActiveSupport::Messages::RotationConfiguration.new
end
class Config
  def initialize(app) = @app = app
  def call(env)
    configure(env)
    @app.call(env)
  end
end

stack = ActionDispatch::MiddlewareStack.new
stack.use ActionDispatch::Cookies
stack.use ActionDispatch::Session::CookieStore, key: "_notes_session"
stack.use ActionDispatch::Flash
app = Config.new(stack.build(set))

# The browser's cookies: name => value, updated from each response's set-cookie lines.
def send_request(app, jar, method, path)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}", method: method)
  env["HTTP_COOKIE"] = jar.map { |k, v| "#{k}=#{v}" }.join("; ") if !jar.empty?
  status, headers, body = app.call(env)
  out = +""
  body.each { |s| out << s }
  puts("#{method} #{path} -> #{status} #{headers["location"].inspect} #{out.inspect}")
  h = headers["set-cookie"]
  lines = case h
          when Array then h
          when String then h.split("\n")
          else []
          end
  lines.each do |l|
    name, rest = l.split("=", 2)
    value = rest.to_s.split(";", 2)[0] || ""
    name = name.to_s
    puts("  set-cookie: #{l}") if name != "_notes_session"
    if l.include?("max-age=0")
      jar.delete(name)
    else
      jar[name] = value
    end
  end
end

jar = {}
send_request(app, jar, "GET", "/notes")
send_request(app, jar, "POST", "/notes")
send_request(app, jar, "GET", "/notes")
send_request(app, jar, "GET", "/notes")
send_request(app, jar, "GET", "/notes/fail")
send_request(app, jar, "GET", "/notes")
send_request(app, jar, "GET", "/notes/now")
send_request(app, jar, "GET", "/notes")
send_request(app, jar, "GET", "/notes/remember")
send_request(app, jar, "GET", "/notes/recall")
send_request(app, jar, "GET", "/notes/forget")
send_request(app, jar, "GET", "/notes/recall")
send_request(app, jar, "GET", "/notes/logout")
send_request(app, jar, "GET", "/notes")
