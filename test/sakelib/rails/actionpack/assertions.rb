gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"
require "action_controller"
require "action_view"
require "action_dispatch/testing/integration"

# The app under test: routes and a controller stand-in, with ShowExceptions so errors become pages
class PostsController
  def self.make_response!(req) = nil
  def self.action_encoding_template(_action) = false
  def self.dispatch(action, req, _res)
    case action
    when "index" then [200, { "content-type" => "text/plain" }, ["all posts"]]
    when "create" then [302, { "location" => "http://www.example.com/posts/1" }, []]
    when "update" then [303, { "location" => "http://www.example.com/posts" }, []]
    when "destroy" then raise "boom"
    else [200, { "content-type" => "text/plain" }, ["post #{req.path_parameters[:id]}"]]
    end
  end
end
PagesController = Class.new(PostsController)       # recognize_path checks that the controller class exists
Admin = Module.new
Admin.const_set(:UsersController, Class.new(PostsController))
set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :posts
  namespace :admin do
    resources :users, only: [:index, :show]
  end
  get "about", to: "pages#about"
end
stack = ActionDispatch::MiddlewareStack.new
stack.use ActionDispatch::ShowExceptions, ActionDispatch::PublicExceptions.new("fixtures/public")
inner = stack.build(set)
app = ->(env) { env["action_dispatch.show_exceptions"] = :all; inner.call(env) }

# Rails' IntegrationTest: Minitest's assertions with ActionDispatch's, on the session's @response, @request, @routes
class AssertionsTest
  include Minitest::Assertions
  include ActionDispatch::Assertions
  attr_accessor :assertions
  def initialize(session, routes) = (@session, @routes, @assertions = session, routes, 0)
  def get(path) = (@session.get(path); copy)
  def post(path) = (@session.post(path); copy)
  def patch(path) = (@session.patch(path); copy)
  def delete(path) = (@session.delete(path); copy)
  def copy = (@response, @request = @session.response, @session.request)
end
it = AssertionsTest.new(ActionDispatch::Integration::Session.new(app), set)

def check(label)
  yield
  puts "#{label}: ok"
rescue Minitest::Assertion => e
  puts "#{label}: #{e.message.lines.map(&:chomp).reject { |l| l.start_with?("    ") }.join(" | ")}"   # without a backtrace
end

puts "-- assert_response"
it.get "/posts"
check("success") { it.assert_response :success }
check("200") { it.assert_response 200 }
check(":ok") { it.assert_response :ok }
check("missing") { it.assert_response :missing }
check("redirect") { it.assert_response :redirect }
check("404 with a message") { it.assert_response 404, "not here" }
it.get "/nothing"
check("missing") { it.assert_response :missing }
check(":not_found") { it.assert_response :not_found }
check("success") { it.assert_response :success }
it.delete "/posts/1"
check("error") { it.assert_response :error }
check("success") { it.assert_response :success }
it.post "/posts"
check("success after a redirect") { it.assert_response :success }

puts "-- assert_redirected_to"
check("full url") { it.assert_redirected_to "http://www.example.com/posts/1" }
check("path") { it.assert_redirected_to "/posts/1" }
check("wrong path") { it.assert_redirected_to "/posts/2" }
check("status") { it.assert_redirected_to "/posts/1", status: :found }
check("wrong status") { it.assert_redirected_to "/posts/1", status: :see_other }
it.patch "/posts/1"
check("see_other") { it.assert_redirected_to "/posts", status: :see_other }
it.get "/posts"
check("not a redirect") { it.assert_redirected_to "/posts" }

puts "-- assert_recognizes, assert_generates, assert_routing"
check("recognizes") { it.assert_recognizes({ controller: "posts", action: "show", id: "1" }, "/posts/1") }
check("recognizes a verb") { it.assert_recognizes({ controller: "posts", action: "update", id: "1" }, { path: "/posts/1", method: :patch }) }
check("recognizes extras") { it.assert_recognizes({ controller: "posts", action: "index", page: "2" }, "/posts", { page: "2" }) }
check("recognizes wrong") { it.assert_recognizes({ controller: "posts", action: "index" }, "/posts/1") }
check("recognizes nothing") { it.assert_recognizes({ controller: "posts", action: "index" }, "/nope") }
check("recognizes with a message") { it.assert_recognizes({ controller: "posts", action: "index" }, "/posts/1", {}, "routes changed") }
check("generates") { it.assert_generates "/posts/1", { controller: "posts", action: "show", id: "1" } }
check("generates no slash") { it.assert_generates "admin/users", { controller: "admin/users", action: "index" } }
check("generates a url") { it.assert_generates "http://example.com/about", { controller: "pages", action: "about" } }
check("generates extras") { it.assert_generates "/posts", { controller: "posts", action: "index", page: "2" }, {}, { page: "2" } }
check("generates wrong") { it.assert_generates "/posts/2", { controller: "posts", action: "show", id: "1" } }
check("generates missing extras") { it.assert_generates "/posts", { controller: "posts", action: "index", page: "2" } }
check("routing") { it.assert_routing "/admin/users/5", { controller: "admin/users", action: "show", id: "5" } }
check("routing a verb") { it.assert_routing({ path: "/posts", method: :post }, { controller: "posts", action: "create" }) }
check("routing wrong") { it.assert_routing "/about", { controller: "pages", action: "contact" } }
it.assert it.assertions > 0
p it.assertions
