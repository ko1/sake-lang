gem "actionpack", "8.1.3"
require "active_support/all"
require "active_support/messages/rotation_configuration"
require "action_dispatch"
require "action_controller"
require "action_dispatch/testing/integration"
require "json"

# The blog's controllers (stand-ins for ActionController::Metal.dispatch; Sake: a Routing::Controllers type)
class PostsController
  def self.make_response!(req) = nil
  def self.action_encoding_template(_action) = false
  def self.dispatch(action, req, _res)
    session = req.session
    flash = req.flash
    session[:visits] = (session[:visits] || 0) + 1
    result = case action
    when "index" then [200, { "content-type" => "text/plain" }, ["index notice=#{flash[:notice].inspect} visits=#{session[:visits]} page=#{req.query_parameters["page"].inspect} host=#{req.host} ssl=#{req.ssl?}"]]
    when "create"
      post = req.request_parameters["post"] || {}
      if post["title"].to_s.empty?
        [422, { "content-type" => "text/plain" }, ["invalid #{post.inspect}"]]
      else
        flash[:notice] = "Post was successfully created."
        [302, { "location" => "http://#{req.host}/posts/1" }, []]
      end
    when "show" then [200, { "content-type" => "text/plain" }, ["show #{req.path_parameters[:id]} notice=#{flash[:notice].inspect} visits=#{session[:visits]} referer=#{req.referer.inspect}"]]
    when "destroy" then raise ActionController::BadRequest, "no"
    when "prefs" then [200, { "content-type" => "text/plain" }, ["theme=#{req.cookies["theme"].inspect}"]]
    when "status"
      body = { "method" => req.request_method, "xhr" => req.xhr?, "accept" => req.get_header("HTTP_ACCEPT"), "params" => req.request_parameters.merge(req.query_parameters) }
      [200, { "content-type" => "application/json; charset=utf-8" }, [JSON.generate(body)]]
    end
    req.commit_flash
    result
  end
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :posts, only: [:index, :create, :show, :destroy]
  get "prefs", to: "posts#prefs"
  match "api/status", to: "posts#status", via: [:get, :post]
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
inner = stack.build(set)
app = ->(env) { configure(env); inner.call(env) }

# Rails' Runner makes the session class with the app's url helpers
session = Class.new(ActionDispatch::Integration::Session) { include set.url_helpers }.new(app)
def show(s) = puts("#{s.request.request_method} #{s.path} -> #{s.status} #{s.response.location.inspect} #{s.body.lines.first.to_s.strip.inspect}")

puts "-- get, params"
session.get "/posts"
show(session)
session.get "/posts", params: { page: 2 }
show(session)
puts "-- post, redirect, follow_redirect!, flash over the session cookie"
session.post "/posts", params: { post: { title: "" } }
show(session)
session.post "/posts", params: { post: { title: "Hello" } }
show(session)
p session.redirect?
p session.follow_redirect!
show(session)
session.get "/posts/1"
show(session)
puts "-- cookies kept by the session, and set by the test"
p session.cookies.to_hash.keys.sort
session.cookies["theme"] = "dark"
session.get "/prefs"
show(session)
p session.cookies["theme"]
puts "-- as: :json, xhr"
session.post "/api/status", params: { title: "x", tags: ["a", "b"] }, as: :json
show(session)
p [session.response.media_type, session.response.parsed_body]
session.get "/api/status", params: { q: "1" }, as: :json
p session.response.parsed_body
session.get "/api/status", params: { q: "2" }, xhr: true
p session.response.parsed_body
session.get "/api/status", headers: { "Accept" => "text/plain", "X-Custom" => "1" }
p session.response.parsed_body["accept"]
puts "-- host!, https!, url_for"
session.host! "blog.example.org"
session.get "/posts"
show(session)
p session.url_for(controller: "posts", action: "show", id: 3)
session.https!
session.get "http://www.example.com/posts?page=9"
show(session)
p [session.host, session.https?]
puts "-- errors"
session.delete "/posts/1"
show(session)
session.get "/nothing"
show(session)
p session.request_count
