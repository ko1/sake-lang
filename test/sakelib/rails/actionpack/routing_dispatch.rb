gem "actionpack", "8.1.3"
require "action_dispatch"
require "action_controller"

# The controllers (Rails: ActionController::Metal.dispatch; here the smallest stand-in: the class answers itself)
class ShowsParams
  def self.make_response!(req) = nil
  def self.action_encoding_template(_action) = false
  def self.dispatch(action, req, _res)
    [200, { "content-type" => "text/plain" }, ["#{name.underscore.delete_suffix("_controller")}##{action} #{req.path_parameters.except(:controller, :action)}"]]
  end
end
class PostsController < ShowsParams; end
class PagesController < ShowsParams; end
class ApiController < ShowsParams; end

# A mounted Rack app sees the rest of the path
class Echo
  def call(env) = [200, { "content-type" => "text/plain" }, ["echo #{env["SCRIPT_NAME"]} #{env["PATH_INFO"]}"]]
  def inspect = "Echo"
end

# A constraint object and a lambda (Sake: names that the routes' constraint_matches? answers)
class AdminOnly
  def self.matches?(req) = req.query_parameters["admin"] == "1"
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :posts, only: [:index, :show, :create]
  get "pages/:name", to: "pages#show", constraints: { name: /[a-z]+/ }
  get "api", to: "api#index", constraints: { subdomain: "api" }
  get "old/:id", to: redirect("/posts/%{id}")
  get "moved", to: redirect(path: "/posts", status: 302)
  mount Echo.new, at: "/echo"
  match "ping", to: "pages#ping", via: :head
  constraints AdminOnly do
    get "secret", to: "pages#secret"
  end
  get "beta", to: "pages#beta", constraints: ->(req) { req.host.start_with?("beta") }
end

def show(set, method, path, host: "example.org")
  env = Rack::MockRequest.env_for("http://#{host}#{path}", method: method)
  status, headers, body = set.call(env)
  out = +""
  body.each { |s| out << s }
  puts "#{method} #{host}#{path} -> #{status} #{headers.to_h.slice("location", "x-cascade").inspect} #{out.inspect}"
end

show(set, "GET", "/posts")
show(set, "GET", "/posts/12.json")
show(set, "POST", "/posts")
show(set, "DELETE", "/posts/12")
show(set, "GET", "/pages/about")
show(set, "GET", "/pages/About1")
show(set, "GET", "/api")
show(set, "GET", "/api", host: "api.example.org")
show(set, "GET", "/old/7")
show(set, "GET", "/moved?x=1")
show(set, "GET", "/echo/a/b")
show(set, "HEAD", "/posts/3")
show(set, "HEAD", "/ping")
show(set, "GET", "/nothing")
show(set, "GET", "/posts/")
show(set, "GET", "/secret")
show(set, "GET", "/secret?admin=1")
show(set, "GET", "/beta")
show(set, "GET", "/beta", host: "beta.example.org")
