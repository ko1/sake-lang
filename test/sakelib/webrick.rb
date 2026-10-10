require "webrick"
require "net/http"
require "socket"

# --- handlers: Ruby's mount_proc blocks; Sake's are types whose fields are what the block closes over ---
srv = WEBrick::HTTPServer.new(BindAddress: "127.0.0.1", Port: 0, Logger: WEBrick::Log.new(File::NULL), AccessLog: [])
port = srv.config[:Port]
p(srv.status)
greeting = "Hi"
srv.mount_proc("/hello") do |req, res|
  res["Content-Type"] = "text/plain"
  res.body = "#{greeting}, #{req.query["name"] || "world"}!\n"
end
srv.mount_proc("/echo") do |req, res|
  res.content_type = "text/plain"
  q = req.query
  body = req.body
  res.body = "#{req.request_method} script=#{req.script_name} info=#{req.path_info} path=#{req.path} qs=#{req.query_string.inspect} q=#{q.sort_by { |k, v| k }.map { |k, v| [k, v.to_s] }.inspect} ct=#{req.content_type.inspect} len=#{req["content-length"].inspect} body=#{body.inspect} token=#{req["X-Token"].inspect} host=#{req.host.inspect}"
end
created = ->(code) {
  ->(req, res) {
    res.status = code
    res["X-Reason"] = res.reason_phrase || ""
    res.body = "made" if code == 201
  }
}
srv.mount_proc("/echo/deeper", created.(201))
srv.mount_proc("/nothing", created.(204))
to = "/hello?name=there"
srv.mount_proc("/go") { |req, res| res.set_redirect(WEBrick::HTTPStatus::Found, to) }
srv.mount_proc("/boom") { |req, res| raise("kaboom") }
srv.mount_proc("/teapot") { |req, res| raise(WEBrick::HTTPStatus::UnprocessableEntity, "short and stout") }
t = Thread.new { srv.start }

def url(port, path) = URI.parse("http://127.0.0.1:#{port}#{path}")

def show(res)
  body = res.body
  puts("#{res.code} #{res.message} type=#{res["content-type"].inspect} length=#{res["content-length"].inspect} body=#{body.inspect}")
end

puts("-- GET")
show(Net::HTTP.get_response(url(port, "/hello")))
show(Net::HTTP.get_response(url(port, "/hello?name=Sake&name=two")))
show(Net::HTTP.get_response(url(port, "/hello/")))
show(Net::HTTP.get_response(url(port, "/echo")))
show(Net::HTTP.get_response(url(port, "/echo/sub/path?x=1&y=a+b%21")))
show(Net::HTTP.get_response(url(port, "/echo/deeper/x")))
show(Net::HTTP.get_response(url(port, "/echo"), {"X-Token" => "t0k"}))

puts("-- POST")
show(Net::HTTP.post_form(url(port, "/echo"), {"k" => "v w", "n" => "1"}))
show(Net::HTTP.post(url(port, "/echo"), "{\"a\":1}", {"Content-Type" => "application/json"}))

puts("-- HEAD, 204, redirect, errors")
res = Net::HTTP.start("127.0.0.1", port) { |http| http.head("/hello") }
show(res)
show(Net::HTTP.get_response(url(port, "/nothing")))
res = Net::HTTP.get_response(url(port, "/go"))
puts("#{res.code} location=#{(res["location"] || "").sub(/:\d+\//, ":PORT/")} body=#{res.body.inspect}")
res = Net::HTTP.get_response(url(port, "/echo/deeper"))
puts("#{res.code} #{res.message} reason=#{res["x-reason"]} body=#{res.body.inspect}")
res = Net::HTTP.get_response(url(port, "/missing"))
puts("#{res.code} #{res.message} type=#{res["content-type"]} html=#{(res.body || "").include?("<H1>Not Found</H1>")} path=#{(res.body || "").include?("'/missing' not found.")}")
res = Net::HTTP.get_response(url(port, "/boom"))
puts("#{res.code} #{res.message} kaboom=#{(res.body || "").include?("kaboom")}")
res = Net::HTTP.get_response(url(port, "/teapot"))
puts("#{res.code} #{res.message} msg=#{(res.body || "").include?("short and stout")}")

res = Net::HTTP.start("127.0.0.1", port) { |http| http.patch("/echo", "x", {"Content-Type" => "text/plain"}) }
puts("#{res.code} #{res.message} msg=#{(res.body || "").include?("unsupported method &#39;PATCH&#39;.") || (res.body || "").include?("unsupported method 'PATCH'.")}")
res = Net::HTTP.start("127.0.0.1", port) { |http| http.put("/echo", "x", {"Content-Type" => "text/plain"}) }
show(res)
res = Net::HTTP.start("127.0.0.1", port) { |http| http.send_request("OPTIONS", "/echo") }
puts("#{res.code} allow=#{res["allow"]} body=#{res.body.inspect}")

puts("-- raw HTTP/1.0 and a bad request")
c = TCPSocket.new("127.0.0.1", port)
c.write("GET /hello?name=raw HTTP/1.0\r\n\r\n")
c.close_write
status = c.gets || ""
rest = []
l = c.gets
while l != nil
  rest.push(l)
  l = c.gets
end
c.close
puts(status.chomp)
puts(rest.last || "")
c = TCPSocket.new("127.0.0.1", port)
c.write("NOT A REQUEST\r\n\r\n")
c.close_write
puts((c.gets || "").chomp)
c.close

puts("-- unmount, shutdown")
srv.unmount("/hello")
res = Net::HTTP.get_response(url(port, "/hello"))
puts("#{res.code} #{res.message} type=#{res["content-type"]}")
p(srv.status)
srv.shutdown
t.join
p(srv.status)
begin
  Net::HTTP.get_response(url(port, "/hello"))
  puts("still up?")
rescue SystemCallError
  puts("refused")
end

puts("-- WEBrick::HTTPStatus, WEBrick::HTTPUtils")
p([WEBrick::HTTPStatus.reason_phrase(200), WEBrick::HTTPStatus.reason_phrase(422), WEBrick::HTTPStatus.reason_phrase(599)])
p([WEBrick::HTTPStatus.success?(204), WEBrick::HTTPStatus.redirect?(301), WEBrick::HTTPStatus.client_error?(404), WEBrick::HTTPStatus.server_error?(503), WEBrick::HTTPStatus.error?(200)])
p(WEBrick::HTTPUtils.parse_query("a=1&b=x+y%21&a=2;c&=d").transform_values(&:to_s))
p(WEBrick::HTTPUtils.parse_query(nil))
p([WEBrick::HTTPUtils.escape_form("a b&c!"), WEBrick::HTTPUtils.unescape_form("a+b%26c"), WEBrick::HTTPUtils.escape("a b/c?d\"é"), WEBrick::HTTPUtils.unescape("a%20b"), WEBrick::HTTPUtils.escape_path("/a b/c?d=é/:x")])
p([WEBrick::HTTPUtils.mime_type("index.html", WEBrick::HTTPUtils::DefaultMimeTypes), WEBrick::HTTPUtils.mime_type("x.PNG", WEBrick::HTTPUtils::DefaultMimeTypes), WEBrick::HTTPUtils.mime_type("Makefile", WEBrick::HTTPUtils::DefaultMimeTypes)])
puts("end")
