gem "actionpack", "8.1.3"
require "action_dispatch"

# Rails finds a controller's encoding template through the controller class; these stand for the app's.
class PostsController; def self.action_encoding_template(action) = false; end

def show(label, v) = puts("#{label}: #{v.inspect}")

puts("-- a GET with a query string")
env = Rack::MockRequest.env_for("http://www.example.com:8080/posts/1.json?a[b]=1&c=2&list[]=x&list[]=y&page=3",
  "HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "HTTP_USER_AGENT" => "Mozilla/5.0", "REMOTE_ADDR" => "127.0.0.1", "HTTP_X_REQUEST_ID" => "abc-123")
req = ActionDispatch::Request.new(env)
show("request_method", req.request_method)
show("request_method_symbol", req.request_method_symbol)
show("method", req.method)
show("get?", req.get?)
show("head?", req.head?)
show("path", req.path)
show("fullpath", req.fullpath)
show("original_fullpath", req.original_fullpath)
show("url", req.url)
show("original_url", req.original_url)
show("protocol", req.protocol)
show("host", req.host)
show("port", req.port)
show("host_with_port", req.host_with_port)
show("standard_port?", req.standard_port?)
show("optional_port", req.optional_port)
show("port_string", req.port_string)
show("domain", req.domain)
show("subdomain", req.subdomain)
show("subdomains", req.subdomains)
show("domain(2)", req.domain(2))
show("user_agent", req.user_agent)
show("accept", req.accept)
show("x_request_id", req.x_request_id)
show("remote_ip", req.remote_ip)
show("ip", req.ip)
show("local?", req.local?)
show("xhr?", req.xhr?)
show("ssl?", req.ssl?)
show("query_parameters", req.query_parameters.to_h)
show("request_parameters", req.request_parameters.to_h)
req.path_parameters = { controller: "posts", action: "show", id: "1", format: "json" }
show("path_parameters", req.path_parameters)
show("parameters", req.parameters.to_h)
show("formats", req.formats.map(&:to_s))
show("format", req.format.to_s)
show("format.ref", req.format.ref)
show("accepts", req.accepts.map(&:to_s))
show("content_mime_type", req.content_mime_type)
show("media_type", req.media_type)
show("content_length", req.content_length)
show("headers[User-Agent]", req.headers["User-Agent"])
show("headers[Content-Type]", req.headers["Content-Type"])
show("headers[REMOTE_ADDR]", req.headers["REMOTE_ADDR"])
show("headers.key?(Accept)", req.headers.key?("Accept"))
show("headers.fetch(X-Missing, none)", req.headers.fetch("X-Missing", "none"))
req.headers["X-Custom"] = "yes"
show("env HTTP_X_CUSTOM", req.get_header("HTTP_X_CUSTOM"))
show("inspect", req.inspect)

puts("-- formats without a format parameter")
def formats_for(path, headers) = ActionDispatch::Request.new(Rack::MockRequest.env_for(path, headers)).formats.map(&:to_s)
show("browser Accept", formats_for("/posts", "HTTP_ACCEPT" => "text/html,application/xhtml+xml,*/*;q=0.8"))
show("json Accept", formats_for("/posts", "HTTP_ACCEPT" => "application/json"))
show("two types", formats_for("/posts", "HTTP_ACCEPT" => "application/json, text/plain;q=0.5"))
show("path extension", formats_for("/posts.csv", {}))
show("xhr", formats_for("/posts", "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"))
show("nothing", formats_for("/posts", {}))
r = ActionDispatch::Request.new(Rack::MockRequest.env_for("/posts", "HTTP_ACCEPT" => "application/json"))
show("negotiate_mime", r.negotiate_mime([Mime[:html], Mime[:json]]).to_s)
show("negotiate_mime none", r.negotiate_mime([Mime[:html]]))
show("should_apply_vary_header?", r.should_apply_vary_header?)

puts("-- a POST with a form body")
env = Rack::MockRequest.env_for("/posts?x=1", method: "POST", input: "post[title]=Hello+World&post[tags][]=a&post[tags][]=b&commit=Save")
env["CONTENT_TYPE"] = "application/x-www-form-urlencoded"
req = ActionDispatch::Request.new(env)
show("post?", req.post?)
show("form_data?", req.form_data?)
show("media_type", req.media_type)
show("content_length", req.content_length)
show("raw_post", req.raw_post)
show("request_parameters", req.request_parameters.to_h)
show("parameters", req.parameters.to_h)

puts("-- a POST with a JSON body")
env = Rack::MockRequest.env_for("/api/posts", method: "POST", input: '{"post":{"title":"Hi","n":3,"tags":["a",null]},"ok":true}')
env["CONTENT_TYPE"] = "application/json; charset=utf-8"
req = ActionDispatch::Request.new(env)
show("content_mime_type", req.content_mime_type.to_s)
show("media_type", req.media_type)
show("request_parameters", req.request_parameters.to_h)
env = Rack::MockRequest.env_for("/api/posts", method: "POST", input: "[1,2]")
env["CONTENT_TYPE"] = "application/json"
show("JSON array", ActionDispatch::Request.new(env).request_parameters.to_h)
env = Rack::MockRequest.env_for("/api/posts", method: "POST", input: "{oops")
env["CONTENT_TYPE"] = "application/json"
begin
  ActionDispatch::Request.new(env).request_parameters
rescue ActionDispatch::Http::Parameters::ParseError => e
  show("ParseError", e.message)
end

puts("-- errors")
begin
  ActionDispatch::Request.new(Rack::MockRequest.env_for("/?a[]=1&a[b]=2")).query_parameters
rescue ActionController::BadRequest => e
  show("BadRequest", e.message)
end
begin
  ActionDispatch::Request.new(Rack::MockRequest.env_for("/", method: "BREW")).request_method
rescue ActionController::UnknownHttpMethod => e
  show("UnknownHttpMethod", e.message)
end

puts("-- forwarded host, https")
req = ActionDispatch::Request.new(Rack::MockRequest.env_for("https://app.example.co.uk/x", "HTTP_X_FORWARDED_HOST" => "a.example.com, shop.example.co.uk"))
show("raw_host_with_port", req.raw_host_with_port)
show("host", req.host)
show("port", req.port)
show("url", req.url)
show("domain(2)", req.domain(2))
show("subdomain(2)", req.subdomain(2))
show("ip host domain", ActionDispatch::Request.new(Rack::MockRequest.env_for("http://192.168.1.10/")).domain)
req = ActionDispatch::Request.new(Rack::MockRequest.env_for("/", method: "PATCH"))
show("patch?", req.patch?)
req.request_method = "DELETE"
show("request_method=", [req.request_method, req.delete?, req.method])

puts("-- conditional GET")
res = ActionDispatch::Response.new
res.etag = "post-1"
req = ActionDispatch::Request.new(Rack::MockRequest.env_for("/", "HTTP_IF_NONE_MATCH" => "#{res.etag}, \"other\""))
show("if_none_match_etags", req.if_none_match_etags)
show("fresh? by etag", req.fresh?(res))
show("fresh? no headers", ActionDispatch::Request.new(Rack::MockRequest.env_for("/")).fresh?(res))
res.last_modified = Time.utc(2026, 10, 1)
req = ActionDispatch::Request.new(Rack::MockRequest.env_for("/", "HTTP_IF_MODIFIED_SINCE" => "Tue, 20 Oct 2026 00:00:00 GMT"))
show("if_modified_since", req.if_modified_since)
show("fresh? by date", req.fresh?(res))
req = ActionDispatch::Request.new(Rack::MockRequest.env_for("/", "HTTP_IF_MODIFIED_SINCE" => "Tue, 01 Sep 2026 00:00:00 GMT"))
show("stale by date", req.fresh?(res))
