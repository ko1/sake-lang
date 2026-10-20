gem "actionpack", "8.1.3"
require "action_controller"

# redirect_to with a URL, a path, url_for options (through the routes), status options, a protocol-relative URL;
# redirect_back and redirect_back_or_to with and without a referer; the open-redirect, path-relative and
# header-safety checks and their messages; url_from.
class GoController < ActionController::Base
  def show = render plain: "show #{params[:id]}"
  def to_url = redirect_to "http://www.example.com/elsewhere"
  def to_path = redirect_to "/posts/1", status: :see_other
  def to_options = redirect_to({ action: "show", id: 5 })
  def to_options_status = redirect_to({ controller: "go", action: "show", id: 6, status: 301 })
  def to_other_host = redirect_to "http://evil.example.org/x"
  def to_other_host_denied = redirect_to "http://evil.example.org/x", allow_other_host: false
  def to_other_host_allowed = redirect_to "http://evil.example.org/x", allow_other_host: true
  def protocol_relative = redirect_to "//evil.example.org/y", allow_other_host: false
  def relative = redirect_to "posts"
  def unsafe = redirect_to "/posts/\u0001x"
  def stripped = redirect_to "/posts\r\n/1"
  def to_nil = redirect_to nil
  def back = redirect_back fallback_location: "/fallback"
  def back_or = redirect_back_or_to "/fallback", allow_other_host: false
  def from = render plain: "#{url_from("/inside").inspect} #{url_from("http://evil.example.org/").inspect} #{url_from("http://www.example.com/ok").inspect} #{url_from("").inspect}"
end


set = ActionDispatch::Routing::RouteSet.new
set.draw do
  get "go/show/:id", to: "go#show"
  ["to_url", "to_path", "to_options", "to_options_status", "to_other_host", "to_other_host_denied",
    "to_other_host_allowed", "protocol_relative", "relative", "unsafe", "stripped", "to_nil", "back", "back_or", "from"].each { |a| get "go/#{a}", to: "go##{a}" }
end
GoController.include(set.url_helpers)

def send_request(set, path, referer = nil)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}")
  env["HTTP_REFERER"] = referer if referer
  begin
    status, hs, body = set.call(env)
    out = +""
    body.each { |s| out << s }
    puts("#{path}#{referer ? " (from #{referer})" : ""} -> #{status} #{hs["location"].inspect} #{out.inspect}")
  rescue => e
    puts("#{path} -> error: #{e.message}")
  end
end

send_request(set, "/go/to_url")
send_request(set, "/go/to_path")
send_request(set, "/go/to_options")
send_request(set, "/go/to_options_status")
send_request(set, "/go/to_other_host")
send_request(set, "/go/to_other_host_denied")
send_request(set, "/go/to_other_host_allowed")
send_request(set, "/go/protocol_relative")
send_request(set, "/go/relative")
send_request(set, "/go/unsafe")
send_request(set, "/go/stripped")
send_request(set, "/go/to_nil")
send_request(set, "/go/back")
send_request(set, "/go/back", "http://www.example.com/came/from")
send_request(set, "/go/back", "http://evil.example.org/came/from")
send_request(set, "/go/back_or", "http://evil.example.org/came/from")
send_request(set, "/go/back_or", "http://www.example.com/came/from")
send_request(set, "/go/from")
puts("raise_on_open_redirects = true, action_on_path_relative_redirect = :raise:")
ActionController::Base.raise_on_open_redirects = true
ActionController::Base.action_on_path_relative_redirect = :raise
send_request(set, "/go/to_other_host")
send_request(set, "/go/back", "http://evil.example.org/came/from")
send_request(set, "/go/relative")
