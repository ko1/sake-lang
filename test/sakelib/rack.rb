require "rack"
require "rackup"
require "webrick"
require "net/http"
require "stringio"

# --- a Rack app and a middleware (Sake: types, since an app cannot be a lambda) ---
class Hello
  def call(env)
    req = Rack::Request.new(env)
    res = Rack::Response.new
    res.content_type = "text/plain"
    case req.path_info
    when "/"
      res.write("hello #{req.params["name"] || "world"}")
    when "/form"
      p = req.params
      res.write("#{req.request_method} #{p.sort_by { |k, v| k }.inspect} #{req.media_type.inspect}")
    when "/raw"                              # Rack's rack.input is a stream read once (params consume it); Sake's is a String
      res.write("#{req.request_method} #{req.media_type.inspect} #{req.body&.read.inspect}")
    when "/cookie"
      res.set_cookie("seen", {value: "yes", path: "/", http_only: true})
      res.set_cookie("n", "#{req.cookies.size}")
      res.write(req.cookies.inspect)
    when "/go"
      res.redirect("/", 303)
    when "/nothing"
      res.status = 204
    when "/info"
      res.write("#{req.url} host=#{req.host} port=#{req.port} path=#{req.path} script=#{req.script_name} qs=#{req.query_string} get=#{req.get?} ua=#{req.user_agent} xhr=#{req.xhr?}")
    else
      res.status = 404
      res.write("no #{req.path_info}")
    end
    res.finish
  end
end

class Counter                 # middleware: counts calls, adds a header
  attr_reader :count
  def initialize(app) = (@app, @count = app, 0)
  def call(env)
    @count += 1
    status, headers, body = @app.call(env)
    headers["x-count"] = @count.to_s
    [status, headers, body]
  end
end

# Rack 3 headers are a Rack::Headers; shown as a plain Hash, as Sake's are.
def plain(triple) = [triple[0], triple[1].to_h, triple[2]]

puts("-- RackUtils")
p(Rack::Utils.parse_query("a=1&a=2&b=x+y%21&c&d="))
p(Rack::Utils.parse_query("a=1;a=2", ";"))
p(Rack::Utils.parse_nested_query("a[b]=1&a[c][d]=2&x[]=1&x[]=2&y[][k]=1&y[][k]=2&z&w=&v=1&v=2&q[=1"))
p(Rack::Utils.parse_nested_query(""))
begin
  Rack::Utils.parse_nested_query("a[]=1&a[b]=2")
rescue Rack::QueryParser::ParameterTypeError => e
  puts("ParameterTypeError: #{e.message}")
end
begin
  Rack::Utils.parse_nested_query("a" + "[b]" * 40 + "=1")
rescue Rack::QueryParser::ParamsTooDeepError => e
  puts("ParamsTooDeepError: #{e.message}")
end
p(Rack::Utils.build_query({"a" => "1", "b" => ["x", "y z"], "c" => nil, "d" => 2}))
p(Rack::Utils.build_nested_query({"a" => {"b" => "1"}, "x" => ["1", "2"], "n" => nil}))
p(Rack::Utils.build_nested_query(["a", "b"], "list"))
begin
  Rack::Utils.build_nested_query("bare")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
p([Rack::Utils.escape("a b&c/d"), Rack::Utils.unescape("a+b%26c"), Rack::Utils.escape_path("/a b/c?d=é"), Rack::Utils.unescape_path("/a%20b")])
p([Rack::Utils.status_code(:not_found), Rack::Utils.status_code(:ok), Rack::Utils.status_code(200), Rack::Utils.status_code("201"), Rack::Utils.status_code(:unprocessable_content)])
begin
  Rack::Utils.status_code(:teapot)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
p([Rack::Utils::HTTP_STATUS_CODES[200], Rack::Utils::HTTP_STATUS_CODES[418], Rack::Utils::HTTP_STATUS_CODES[511], Rack::Utils::HTTP_STATUS_CODES.size])
p(Rack::Utils.parse_cookies_header("a=1; b=x%20y; a=2; c; d="))
p(Rack::Utils.parse_cookies_header(nil))
p(Rack::Utils.set_cookie_header("s", "v w"))
p(Rack::Utils.set_cookie_header("s", {value: "1", domain: "example.org", path: "/", max_age: 60, expires: Time.at(0), secure: true, http_only: true, same_site: :strict}))
p(Rack::Utils.set_cookie_header("s", {value: ["a", "b"], same_site: :none}))
begin
  Rack::Utils.set_cookie_header("bad key", "v")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
p(Rack::Utils.delete_set_cookie_header("s", {path: "/x"}))
p([Rack::Utils.clean_path_info("/a/../b/./c//"), Rack::Utils.clean_path_info("a/b/../../.."), Rack::Utils.clean_path_info("")])
p([Rack::Utils.valid_path?("/ok"), Rack::Utils.valid_path?("/n\0")])
p(Rack::Utils.q_values("text/html;q=0.9, */*;q=0.1, application/json"))
p([Rack::Utils.best_q_match("gzip;q=0.5, deflate", ["gzip", "deflate", "identity"]), Rack::Utils.best_q_match("br", ["gzip"])])

puts("-- RackMockRequest.env_for, RackRequest")
env = Rack::MockRequest.env_for("/")
p(env.reject { |k, v| k.start_with?("rack.") })
env = Rack::MockRequest.env_for("https://example.com:8443/a/b?x=1&y[z]=2", method: :post, input: "k=v&list[]=1", "CONTENT_TYPE" => "application/x-www-form-urlencoded", "HTTP_COOKIE" => "a=1; b=x%20y", "HTTP_USER_AGENT" => "sake")
p(env.reject { |k, v| k.start_with?("rack.") })
p(env["rack.input"].read.tap { env["rack.input"].rewind })
req = Rack::Request.new(env)
p([req.request_method, req.get?, req.post?, req.put?])
p([req.path_info, req.script_name, req.path, req.query_string, req.fullpath])
p([req.scheme, req.ssl?, req.host, req.hostname, req.port, req.host_with_port, req.base_url, req.url])
p([req.content_type, req.media_type, req.content_length, req.form_data?, req.user_agent, req.xhr?])
p(req.GET)
p(req.POST)
p(req.params)
p(req.cookies)
req.body.rewind                              # consumed by req.POST above; Sake's body is a String
p(req.body.read)
env = Rack::MockRequest.env_for("http://example.org:80/p", params: {"q" => "1", "r" => ["a", "b"]}, "HTTP_HOST" => "example.org", "HTTP_X_FORWARDED_PROTO" => "https", "CONTENT_TYPE" => "text/html; charset=utf-8")
req = Rack::Request.new(env)
p([env["QUERY_STRING"], req.params, req.scheme, req.port, req.url, req.media_type, req.media_type_params, req.content_charset])
env = Rack::MockRequest.env_for("/p", method: "post", params: {"a" => "1", "b" => {"c" => "2"}})
req = Rack::Request.new(env)
p([env["CONTENT_TYPE"], env["rack.input"].string, env["CONTENT_LENGTH"], req.params, req.body.string])
env = Rack::MockRequest.env_for("/p", method: "POST", input: "{\"a\":1}", "CONTENT_TYPE" => "application/json")
req = Rack::Request.new(env)
p([req.params, req.form_data?, req.body.read, req.cookies])
env = Rack::MockRequest.env_for("/p", "HTTP_HOST" => "[::1]:3000", "HTTP_ACCEPT_LANGUAGE" => "ja, en;q=0.5")
req = Rack::Request.new(env)
p([req.host, req.hostname, req.port, req.url, req.accept_language])

puts("-- RackResponse")
res = Rack::Response.new
p(plain(res.finish))
p([res.status, res.ok?, res.successful?, res.body, res.headers.to_h])
res = Rack::Response.new("hi")
p(plain(res.finish))
res = Rack::Response.new(["a", "bc"], 201, {"Content-Type" => "text/plain", "X-Y" => "z"})
p(plain(res.finish))
res.write("d")
p(plain(res.finish))
p([res.content_type, res.media_type, res.content_length, res.get_header("x-y"), res.has_header?("x-y"), res.has_header?("nope"), res.created?])
res = Rack::Response.new
res.set_cookie("s", {value: "1", path: "/", http_only: true, same_site: :lax})
res.set_cookie("t", "2")
p(res.headers.to_h)
res.delete_cookie("s")
p(res.set_cookie_header)
res.add_header("vary", "accept-encoding")
res.add_header("vary", "cookie")
p([res.get_header("vary"), res.add_header("vary", nil)])
res.redirect("/elsewhere")
p([res.status, res.location, res.redirect?, res.redirection?])
res = Rack::Response.new("gone", 204, {"content-type" => "text/plain"})
p(plain(res.finish))
p([res.no_content?, res.client_error?, res.invalid?])
res = Rack::Response.new(nil, 404)
res.write("a")
res.write("é")
p([plain(res.finish), res.not_found?, res.server_error?])
res = Rack::Response.new(nil, "500")
p([res.status, res.server_error?])
res.content_type = "application/json"
res.etag = "\"abc\""
res.cache_control = "no-store"
res.set_header("x-removed", "1")
res.delete_header("x-removed")
p(res.headers.to_h)
parts = []
Rack::Response.new(["x", "y"]).each { |s| parts.push(s) }
p(parts)

puts("-- the app through RackMockRequest")
app = Counter.new(Hello.new)
status, headers, body = app.call(Rack::MockRequest.env_for("/?name=Sake"))
p([status, headers.to_h, body])
p(plain(app.call(Rack::MockRequest.env_for("/form", params: {"q" => "1"}))))
p(plain(app.call(Rack::MockRequest.env_for("/form", method: "POST", params: {"a" => "1", "b" => {"c" => "2"}}))))
p(plain(app.call(Rack::MockRequest.env_for("/form?x=9", method: "POST", input: "k=v", "CONTENT_TYPE" => "application/x-www-form-urlencoded"))))
p(plain(app.call(Rack::MockRequest.env_for("/raw", method: "POST", input: "k=v", "CONTENT_TYPE" => "application/x-www-form-urlencoded"))))
p(plain(app.call(Rack::MockRequest.env_for("/cookie", "HTTP_COOKIE" => "a=1; b=2"))))
p(plain(app.call(Rack::MockRequest.env_for("/go"))))
p(plain(app.call(Rack::MockRequest.env_for("/nothing"))))
p(plain(app.call(Rack::MockRequest.env_for("/missing"))))
p(app.count)

puts("-- the app served by webrick (Rackup::Handler::WEBrick)")
srv = WEBrick::HTTPServer.new(BindAddress: "127.0.0.1", Port: 0, Logger: WEBrick::Log.new(File::NULL), AccessLog: [])
port = srv.config[:Port]
srv.mount("/", Rackup::Handler::WEBrick, app)
t = Thread.new { srv.start }
def url(port, path) = URI.parse("http://127.0.0.1:#{port}#{path}")
def show(res)
  puts("#{res.code} type=#{res["content-type"].inspect} length=#{res["content-length"].inspect} count=#{res["x-count"]} body=#{res.body.inspect}")
end
show(Net::HTTP.get_response(url(port, "/")))
show(Net::HTTP.get_response(url(port, "/?name=net")))
show(Net::HTTP.post_form(url(port, "/form"), {"k" => "v w", "n" => "1"}))
show(Net::HTTP.post(url(port, "/form"), "{\"a\":1}", {"Content-Type" => "application/json"}))
show(Net::HTTP.post(url(port, "/raw"), "{\"a\":1}", {"Content-Type" => "application/json"}))
res = Net::HTTP.get_response(url(port, "/cookie"), {"Cookie" => "a=1; b=2"})
show(res)
p(res.get_fields("set-cookie"))
res = Net::HTTP.get_response(url(port, "/go"))
puts("#{res.code} location=#{(res["location"] || "").sub(/:\d+\//, ":PORT/")}")
show(Net::HTTP.get_response(url(port, "/nothing")))
show(Net::HTTP.get_response(url(port, "/missing")))
res = Net::HTTP.get_response(url(port, "/info?q=1"), {"User-Agent" => "sake-test", "X-Requested-With" => "XMLHttpRequest"})
puts((res.body || "").gsub(/\d{4,5}/, "PORT"))
srv.shutdown
t.join
p(app.count)
puts("end")
