gem "actionpack", "8.1.3"
require "active_support/all"
require "active_support/messages/rotation_configuration"
require "action_dispatch"
require "action_controller"

# A request through the stack an app has (ShowExceptions, DebugExceptions, Cookies, the cookie session, Flash) into
# the routes and a controller stand-in (Rails: ActionController::Metal.dispatch; Sake: a Routing::Controllers type).
class PostsController
  def self.make_response!(req) = nil
  def self.action_encoding_template(_action) = false
  def self.dispatch(action, req, _res)
    session = req.session
    flash = req.flash
    session[:visits] = (session[:visits] || 0) + 1
    result = case action
    when "index" then [200, { "content-type" => "text/plain" }, ["index notice=#{flash[:notice].inspect} visits=#{session[:visits]}"]]
    when "create"
      flash[:notice] = "Post was successfully created."
      [302, { "location" => "http://www.example.com/posts/1" }, []]
    when "show" then [200, { "content-type" => "text/plain" }, ["show #{req.path_parameters[:id]} notice=#{flash[:notice].inspect} visits=#{session[:visits]}"]]
    when "destroy" then raise ActionController::BadRequest, "no"
    end
    req.commit_flash
    result
  end
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :posts, only: [:index, :create, :show, :destroy]
  root "posts#index"
end

# Rails.application.env_config, which Rails::Engine#call merges into the env before the stack
def configure(env)
  env["action_dispatch.key_generator"] = ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new("b" * 64, iterations: 2))
  env["action_dispatch.signed_cookie_salt"] = "signed cookie"
  env["action_dispatch.cookies_serializer"] = :json
  env["action_dispatch.use_cookies_with_metadata"] = true
  env["action_dispatch.cookies_rotations"] = ActiveSupport::Messages::RotationConfiguration.new
  env["action_dispatch.show_exceptions"] = :all
  env["action_dispatch.show_detailed_exceptions"] = false
end

stack = ActionDispatch::MiddlewareStack.new
stack.use ActionDispatch::ShowExceptions, ActionDispatch::PublicExceptions.new("fixtures/public")
stack.use ActionDispatch::DebugExceptions
stack.use ActionDispatch::Cookies
stack.use ActionDispatch::Session::CookieStore, key: "_blog_session"
stack.use ActionDispatch::Flash
app = stack.build(set)

def send_request(app, method, path, cookie)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}", method: method)
  env["HTTP_COOKIE"] = cookie if cookie
  configure(env)
  status, headers, body = app.call(env)
  out = +""
  body.each { |s| out << s }
  sc = headers["set-cookie"]
  sc = sc.first if sc.is_a?(Array)
  puts "#{method} #{path} -> #{status} #{headers["location"].inspect} #{out.lines.first.to_s.strip.inspect} cookie=#{!sc.nil?}"
  sc ? sc[/\A[^;]*/] : cookie
end

c = send_request(app, "GET", "/posts", nil)
c = send_request(app, "POST", "/posts", c)
c = send_request(app, "GET", "/posts/1", c)
c = send_request(app, "GET", "/posts/1", c)
c = send_request(app, "GET", "/", c)
c = send_request(app, "DELETE", "/posts/1", c)
c = send_request(app, "GET", "/nothing", c)
c = send_request(app, "PATCH", "/posts/1", c)
