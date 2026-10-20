gem "actionpack", "8.1.3"
require "action_controller"
require "json"

# ParamsWrapper: a JSON body's keys wrapped under the controller's singular name, with :include, :exclude, a
# name, false, a subclass inheriting its parent's options, an API controller with form bodies, and the cases
# that are not wrapped (a form body, a key already there).
module Api
end
require_relative "controller_params_wrapper_decl"
class ApplicationController < ActionController::Base
  def create = render plain: "#{self.class.name} #{params.to_unsafe_h.inspect}"
end
class PostsController < ApplicationController
end
class PeopleController < ApplicationController
end
class CommentsController < ApplicationController
end
class NotesController < ApplicationController
end
module Api
  class UsersController < ActionController::API
    def create = render plain: "#{self.class.name} #{params.to_unsafe_h.inspect} #{request.request_parameters.inspect}"
  end
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  ["posts", "people", "comments", "notes"].each { |r| post r, to: "#{r}#create" }
  post "users", to: "api/users#create"
end

def request(set, path, content_type, body)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}", method: "POST", input: body)
  env["CONTENT_TYPE"] = content_type
  status, _headers, out = set.call(env)
  text = +""
  out.each { |s| text << s }
  puts("#{path} #{content_type} -> #{status} #{text}")
end

json = JSON.generate({ "title" => "Hi", "name" => "ann", "age" => 3, "secret" => "x" })
request(set, "/posts", "application/json", json)
request(set, "/posts", "application/x-www-form-urlencoded", "title=Hi")
request(set, "/posts", "application/json", JSON.generate({ "title" => "Hi", "post" => "given" }))
request(set, "/people", "application/json", json)
request(set, "/comments", "application/json", json)
request(set, "/notes", "application/json", json)
request(set, "/users", "application/x-www-form-urlencoded", "name=bob&authenticity_token=t")
