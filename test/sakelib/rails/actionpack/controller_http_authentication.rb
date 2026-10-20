gem "actionpack", "8.1.3"
require "action_controller"

# HTTP Basic and Token authentication: http_basic_authenticate_with (a before_action), authenticate_or_request_with_http_basic
# with a block, authenticate_with_http_token and request_http_token_authentication, with Rails' headers and bodies.
require_relative "controller_http_authentication_decl"
class AdminController < ActionController::Base
  def index = render plain: "admin index"
  def open = render plain: "open to all"
end

class ReportsController < ActionController::Base
  def basic
    user = authenticate_or_request_with_http_basic("Reports") { |name, password| name == "ann" && password == "pw" ? name : nil }
    render plain: "hello #{user}" unless performed?
  end
  def token
    found = authenticate_with_http_token { |token, options| token == "abc" ? "#{token} #{options[:scope].inspect}" : nil }
    if found
      render plain: "token #{found}"
    else
      request_http_token_authentication("API \"v1\"")
    end
  end
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  get "admin", to: "admin#index"
  get "open", to: "admin#open"
  get "basic", to: "reports#basic"
  get "token", to: "reports#token"
end

def request(set, path, authorization)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}")
  env["HTTP_AUTHORIZATION"] = authorization if authorization
  status, headers, body = set.call(env)
  out = +""
  body.each { |s| out << s }
  puts("#{path} #{authorization.inspect} -> #{status} #{headers["www-authenticate"].inspect} #{headers["content-type"].inspect} #{out.inspect}")
end

Basic = ActionController::HttpAuthentication::Basic
Token = ActionController::HttpAuthentication::Token
request(set, "/admin", nil)
request(set, "/admin", Basic.encode_credentials("dhh", "wrong"))
request(set, "/admin", Basic.encode_credentials("dhh", "secret"))
request(set, "/open", nil)
request(set, "/basic", nil)
request(set, "/basic", Basic.encode_credentials("ann", "pw"))
request(set, "/basic", "Bearer abc")
request(set, "/token", nil)
request(set, "/token", Token.encode_credentials("abc", { scope: "read" }))
request(set, "/token", "Bearer abc")
request(set, "/token", "Token token=\"zzz\"")
p(Token.encode_credentials("abc", { scope: "read", n: 1 }))
p(Basic.encode_credentials("a:b", "p w"))
