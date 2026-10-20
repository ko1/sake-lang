gem "actionpack", "8.1.3"
require "action_controller"

# Controllers on ActionController::Base, dispatched through the routes: render plain/json/html/body, status,
# redirect_to, head, implicit render, callbacks with only/except, around and after callbacks, halting,
# rescue_from, DoubleRenderError, respond_to, fresh_when, send_data.
class RecordNotFound < StandardError
end
require_relative "controller_base_decl"

class ApplicationController < ActionController::Base
  private
  def wrap
    puts("  around { #{action_name}")
    yield
    puts("  } around #{action_name}")
  end
  def stamp = response.set_header("X-Stamp", "stamped")
  def not_found(e) = render plain: "not found: #{e.message}", status: :not_found
end

class PostsController < ApplicationController
  attr_reader :post

  def index = render plain: "all posts"
  def show = render json: { "id" => @post, "title" => "Hello" }
  def create = redirect_to "/posts/1", status: :see_other
  def update = render html: "<b>#{@post}</b>", status: :accepted
  def destroy = head :no_content, x_deleted: "yes"

  private
  def authenticate
    head :unauthorized if params[:token] != "secret"
  end
  def load_post = @post = params.expect(:id).to_s
end

class PagesController < ApplicationController
  def missing = raise RecordNotFound, "post 42"
  def twice
    render plain: "one"
    render plain: "two"
  end
  def nothing = nil
  def body = render body: "raw"
  def negotiate
    respond_to do |format|
      format.html { render html: "<p>html</p>" }
      format.json { render json: [1, 2] }
    end
  end
  def cached = fresh_when etag: "v1"
  def download = send_data "a,b\n", filename: "report.csv"
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :posts, only: [:index, :show, :create, :update, :destroy]
  ["missing", "twice", "nothing", "body", "negotiate", "cached", "download"].each { |a| get a, to: "pages##{a}" }
end

def show_response(method, path, status, headers, body)
  out = +""
  body.each { |s| out << s }
  keys = headers.keys.sort.select { |k| k != "content-length" }
  puts("#{method} #{path} -> #{status}")
  keys.each { |k| puts("  #{k}: #{headers[k]}") }
  puts("  body: #{out.inspect}")
end

def request(set, method, path, headers = {})
  env = Rack::MockRequest.env_for("http://www.example.com#{path}", method: method)
  headers.each { |k, v| env[k] = v }
  begin
    status, hs, body = set.call(env)
    show_response(method, path, status, hs, body)
  rescue => e
    puts("#{method} #{path} -> #{e.class.name}: #{e.message.slice(0, 70)}")
  end
end

request(set, "GET", "/posts")
request(set, "GET", "/posts/7")
request(set, "POST", "/posts")
request(set, "POST", "/posts?token=secret")
request(set, "PATCH", "/posts/7?token=secret")
request(set, "DELETE", "/posts/7?token=secret")
request(set, "GET", "/missing")
request(set, "GET", "/twice")
request(set, "GET", "/nothing")
request(set, "GET", "/nothing", { "HTTP_ACCEPT" => "application/json" })
request(set, "GET", "/body")
request(set, "GET", "/negotiate", { "HTTP_ACCEPT" => "application/json" })
request(set, "GET", "/negotiate.html")
request(set, "GET", "/cached")
request(set, "GET", "/cached", { "HTTP_IF_NONE_MATCH" => "W/\"8f2a39dd2fdaecc8bd47e2a9bdc5ea4f\"" })
request(set, "GET", "/download")
