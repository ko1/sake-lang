gem "actionpack", "8.1.3"
require "action_controller"

# A bare ActionController::Metal subclass, and controllers called as Rack apps through `action(name)`, without
# routes: response_body=, status=, content_type=, headers, the ActionNotFound message, and a controller's names
# (controller_path, controller_name, action_methods).
class HelloController < ActionController::Metal
  def index = self.response_body = "Hello World!"
  def teapot
    self.status = 418
    self.content_type = "text/plain"
    response.set_header("X-Brew", "earl grey")
    self.response_body = "short and stout"
  end
end

module Admin
  class PostsController < ActionController::Base
    def index = render plain: "admin posts for #{request.params["page"]}"
    def show = render plain: "admin post"

    private
    def helper = "not an action"
  end
end


def show_response(name, triple)
  status, headers, body = triple
  out = +""
  body.each { |s| out << s }
  keys = headers.keys.sort.select { |k| k != "content-length" }
  puts("#{name} -> #{status}")
  keys.each { |k| puts("  #{k}: #{headers[k]}") }
  puts("  body: #{out.inspect}")
end

def env_for(path) = Rack::MockRequest.env_for("http://www.example.com#{path}")

show_response("HelloController#index", HelloController.action(:index).call(env_for("/")))
show_response("HelloController#teapot", HelloController.action("teapot").call(env_for("/")))
show_response("Admin::PostsController#index", Admin::PostsController.action(:index).call(env_for("/admin/posts?page=2")))
begin
  Admin::PostsController.action(:helper).call(env_for("/"))
rescue AbstractController::ActionNotFound => e
  puts("AbstractController::ActionNotFound: #{e.message}")
end
begin
  HelloController.action(:nope).call(env_for("/"))
rescue AbstractController::ActionNotFound => e
  puts("AbstractController::ActionNotFound: #{e.message}")
end

c = Admin::PostsController.new
p(c.controller_path, c.controller_name)
p(c.action_methods.to_a.sort)
# (Ruby also lists the included modules' public methods as HelloController's actions; Sake lists the class's own)
p(HelloController.new.controller_path, (HelloController.new.action_methods.to_a & ["index", "teapot"]).sort)
p(!!c.available_action?("show"), !!c.available_action?("helper"), !!c.available_action?("../show"))
