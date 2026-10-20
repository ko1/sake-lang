gem "actionpack", "8.1.3"
require "action_controller"

# Controllers on ActionController::API: render json/plain/body with status and location, head, redirect_to,
# rescue_from, callbacks (only/if/skip), BasicImplicitRender's 204, params from the query, the path and a JSON body.
class Forbidden < StandardError
end
require_relative "controller_api_decl"

class ApiController < ActionController::API
  def health = head :ok

  private
  def count = response.set_header("X-Counted", "1")
  def forbidden(e) = render json: { "error" => e.message }, status: :forbidden
end

class ItemsController < ApiController
  attr_reader :item

  def index = render json: [{ "id" => 1 }, { "id" => 2 }]
  def show = render json: { "id" => @item, "q" => params[:q] }
  def create
    name = params.expect(item: [:name])

    render json: { "created" => name[:name] }, status: :created, location: "/items/3"
  end
  def update = head :no_content
  def destroy = raise Forbidden, "no deleting"
  def ping = render plain: "pong"
  def raw = render body: "raw body", content_type: "application/octet-stream"
  def nothing = nil
  def go = redirect_to "/items", status: :moved_permanently

  private
  def find_item = @item = params[:id].to_s
  def tag = response.set_header("X-Tag", "tagged")
  def tagged? = params[:tag] == "1"
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :items
  ["ping", "raw", "nothing", "go"].each { |a| get a, to: "items##{a}" }
  get "health", to: "api#health"
end

def show_response(method, path, status, headers, body)
  out = +""
  body.each { |s| out << s }
  keys = headers.keys.sort.select { |k| k != "content-length" }
  puts("#{method} #{path} -> #{status}")
  keys.each { |k| puts("  #{k}: #{headers[k]}") }
  puts("  body: #{out.inspect}")
end

def send_request(set, method, path, body = nil)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}", method: method, input: body || "")
  if body
    env["CONTENT_TYPE"] = "application/json"
    env["CONTENT_LENGTH"] = body.bytesize.to_s
  end
  status, hs, b = set.call(env)
  show_response(method, path, status, hs, b)
end

send_request(set, "GET", "/items")
send_request(set, "GET", "/items/7?q=x")
send_request(set, "GET", "/items/7?q=x&tag=1")
send_request(set, "POST", "/items", "{\"item\":{\"name\":\"pen\",\"price\":3}}")
send_request(set, "PATCH", "/items/7")
send_request(set, "DELETE", "/items/7")
send_request(set, "GET", "/ping")
send_request(set, "GET", "/raw")
send_request(set, "GET", "/nothing")
send_request(set, "GET", "/go")
send_request(set, "GET", "/health")
