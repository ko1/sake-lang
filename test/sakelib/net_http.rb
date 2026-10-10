require "net/http"
require "open-uri"
require "socket"

# --- a tiny HTTP/1.1 server on an ephemeral port, in a thread ---
def respond(c, status, headers, body)
  c.write("HTTP/1.1 #{status}\r\n#{headers}Connection: close\r\n\r\n")
  c.write(body) if body
  c.close
end

def handle(c)
  line = c.gets
  return c.close unless line
  m = line.match(/\A(\S+) (\S+) HTTP/)
  return c.close unless m
  verb = m[1] || ""
  path = m[2] || ""
  hdrs = {}
  l = c.gets
  while l != nil && l.chomp != ""
    k, _sep, v = l.chomp.partition(":")
    hdrs[k.downcase] = v.strip
    l = c.gets
  end
  len = hdrs["content-length"]
  body = len ? (c.read(len.to_i) || "") : ""
  head = verb == "HEAD"
  case path
  when "/hello"
    text = "Hello, world!\n"
    respond(c, "200 OK", "Content-Type: text/plain; charset=utf-8\r\nContent-Length: #{text.bytesize}\r\nX-Custom: yes\r\nSet-Cookie: a=1\r\nSet-Cookie: b=2\r\n", head ? nil : text)
  when "/missing"
    respond(c, "404 Not Found", "Content-Type: text/plain\r\nContent-Length: 9\r\n", "not found")
  when "/chunked"
    chunks = "6;ext=1\r\n{\"ok\":\r\n5\r\ntrue}\r\n0\r\nX-Trailer: t\r\n\r\n"
    respond(c, "200 OK", "Content-Type: application/json\r\nTransfer-Encoding: chunked\r\n", chunks)
  when "/redirect"
    respond(c, "302 Found", "Location: /hello\r\nContent-Length: 0\r\n", "")
  when "/redirect-abs"
    respond(c, "301 Moved Permanently", "Location: http://#{hdrs["host"]}/chunked\r\nContent-Length: 0\r\n", "")
  when "/loop"
    respond(c, "302 Found", "Location: /loop2\r\nContent-Length: 0\r\n", "")
  when "/loop2"
    respond(c, "307 Temporary Redirect", "Location: /loop\r\nContent-Length: 0\r\n", "")
  when "/echo"
    text = "#{verb} #{hdrs["content-type"]} #{body}"
    respond(c, "200 OK", "Content-Type: text/plain\r\nContent-Length: #{text.bytesize}\r\n", text)
  when "/headers"
    text = "ua=#{hdrs["user-agent"]} token=#{hdrs["x-token"]} auth=#{hdrs["authorization"]}"
    respond(c, "200 OK", "Content-Type: text/plain\r\nContent-Length: #{text.bytesize}\r\n", text)
  when "/empty"
    respond(c, "204 No Content", "", nil)
  when "/nolength"
    respond(c, "200 OK", "Content-Type: text/plain\r\n", "until eof\n")
  when "/error"
    respond(c, "500 Internal Server Error", "Content-Length: 4\r\n", "boom")
  when "/html"
    text = "<p>日本語</p>\n"
    respond(c, "200 OK", "Content-Type: text/html\r\nContent-Length: #{text.bytesize}\r\n", text)
  when "/binary"
    bin = [0, 255, 10].pack("C*")
    respond(c, "200 OK", "Content-Type: application/octet-stream\r\nContent-Length: 3\r\nContent-Encoding: identity\r\n", bin)
  else
    respond(c, "404 Not Found", "Content-Length: 0\r\n", "")
  end
end

def serve(srv)
  loop { handle(srv.accept) }
end

srv = TCPServer.new("127.0.0.1", 0)
port = srv.addr[1]
server = Thread.new { serve(srv) }
server.report_on_exception = false
def url(port, path) = "http://127.0.0.1:#{port}#{path}"

puts("-- Net::HTTP.get")
p(Net::HTTP.get(URI.parse(url(port, "/hello"))))
p(Net::HTTP.get("127.0.0.1", "/hello", port))
p(Net::HTTP.get(URI.parse(url(port, "/chunked"))))
p(Net::HTTP.get(URI.parse(url(port, "/nolength"))))
p(Net::HTTP.get(URI.parse(url(port, "/empty"))))
p(Net::HTTP.get(URI.parse(url(port, "/missing"))))
Net::HTTP.get_print(URI.parse(url(port, "/hello")))

puts("-- get_response")
res = Net::HTTP.get_response(URI.parse(url(port, "/hello")))
p(res)
p([res.code, res.message, res.http_version])
p(res.body)
p(res["Content-Type"])
p(res["x-custom"])
p(res["X-Missing"])
p(res.content_type)
p(res.content_length)
p(res.key?("set-cookie"))
p(res["set-cookie"])
p(res.get_fields("set-cookie"))
p(res.to_hash)
res.each_header { |k, v| puts("#{k}: #{v}") }
p([res.is_a?(Net::HTTPSuccess), res.is_a?(Net::HTTPRedirection), res.is_a?(Net::HTTPClientError), res.is_a?(Net::HTTPServerError)])
p(res.value)

res = Net::HTTP.get_response(URI.parse(url(port, "/missing")))
p(res)
p([res.code, res.message, res.body, res.is_a?(Net::HTTPSuccess), res.is_a?(Net::HTTPClientError)])
begin
  res.value
rescue Net::HTTPClientException => e
  puts("Net::HTTPClientException: #{e.message} #{e.response.code}")
end
res = Net::HTTP.get_response(URI.parse(url(port, "/error")))
p(res)
begin
  res.value
rescue Net::HTTPFatalError => e
  puts("Net::HTTPFatalError: #{e.message}")
end

puts("-- chunked, no body, redirect (not followed)")
res = Net::HTTP.get_response(URI.parse(url(port, "/chunked")))
p([res.body, res["transfer-encoding"], res["content-length"], res.content_type])
res = Net::HTTP.get_response(URI.parse(url(port, "/empty")))
p([res, res.body, res.content_length])
res = Net::HTTP.get_response(URI.parse(url(port, "/redirect")))
p([res, res.is_a?(Net::HTTPRedirection), res["location"], res.body])
begin
  res.value
rescue Net::HTTPRetriableError => e
  puts("Net::HTTPRetriableError: #{e.message}")
end
res = Net::HTTP.get_response(URI.parse(url(port, "/html")))
body = res.body || ""
p([body.encoding.to_s, body.force_encoding("UTF-8")])
res = Net::HTTP.get_response(URI.parse(url(port, "/binary")))
p([res.body, (res.body || "").encoding.to_s])

puts("-- post, post_form")
res = Net::HTTP.post(URI.parse(url(port, "/echo")), "{\"a\":1}", {"Content-Type" => "application/json"})
p([res, res.body])
res = Net::HTTP.post(URI.parse(url(port, "/echo")), "plain")
p(res.body)
res = Net::HTTP.post_form(URI.parse(url(port, "/echo")), {"a" => "1", "b" => "two words"})
p(res.body)

puts("-- requests")
req = Net::HTTP::Get.new("/headers", {"X-Token" => "t0k"})
p(req)
p([req.method, req.path, req["x-token"], req["User-Agent"]])
req["User-Agent"] = "sake-test"
req.basic_auth("user", "pw")
p(req["authorization"])
p(req.key?("X-TOKEN"))
p(req.to_hash.except("accept-encoding"))
req.each_header { |k, v| puts("#{k}: #{v}") unless k == "accept-encoding" }
p(req.delete("accept"))
p(req.key?("accept"))
req.add_field("Foo", "a")
req.add_field("foo", "b")
p([req["foo"], req.get_fields("foo")])
req["foo"] = nil
p(req.key?("foo"))
p([req.request_body_permitted?, req.response_body_permitted?])
post = Net::HTTP::Post.new("/echo")
post.set_form_data({"k" => "v w", "x" => "1&2"})
p([post.body, post.content_type, post["content-type"]])
post.set_form_data([["k", "v"], ["k", "w"]], ";")
p(post.body)
post.content_type = "text/plain"
p(post.content_type)
p([post.request_body_permitted?, Net::HTTP::Head.new("/").response_body_permitted?])
p([Net::HTTP::Put.new("/"), Net::HTTP::Delete.new("/"), Net::HTTP::Patch.new("/"), Net::HTTP::Head.new("/")])
begin
  Net::HTTP::Get.new("")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
ureq = Net::HTTP::Get.new(URI.parse("http://example.com/a/b?c=1"))
p([ureq.path, ureq["host"]])
ureq = Net::HTTP::Get.new(URI.parse("http://example.com:8080/"))
p([ureq.path, ureq["host"]])

puts("-- start")
out = Net::HTTP.start("127.0.0.1", port) do |http|
  p(http.started?)
  p([http.address == "127.0.0.1", http.port == port])
  res = http.request(req)
  p(res.body)
  res = http.request(post)
  p(res.body)
  res = http.head("/hello")
  p([res, res.body, res["content-length"]])
  res = http.request_get("/hello", {"X-Token" => "ignored"})
  p(res.body)
  res = http.request_post("/echo", "x=1", {"Content-Type" => "application/x-www-form-urlencoded"})
  p(res.body)
  res = http.put("/echo", "P", {"Content-Type" => "text/plain"})
  p(res.body)
  res = http.patch("/echo", "Q", {"Content-Type" => "text/plain"})
  p(res.body)
  res = http.delete("/echo")
  p(res.body)
  res = http.send_request("OPTIONS", "/echo")
  p(res.body)
  res = http.request(Net::HTTP::Get.new("/hello")) { |r| puts("block: #{r.code}") }
  p(res.code)
  :done
end
p(out)
http = Net::HTTP.new("127.0.0.1", port)
p(http.started?)
http.start
p(http.started?)
begin
  http.start
rescue IOError => e
  puts("IOError: #{e.message}")
end
p(http.request_get("/hello").body)
http.finish
p(http.started?)
begin
  http.finish
rescue IOError => e
  puts("IOError: #{e.message}")
end

puts("-- connection refused")
closed = TCPServer.new("127.0.0.1", 0)
closed_port = closed.addr[1]
closed.close
begin
  Net::HTTP.get_response("127.0.0.1", "/", closed_port)
  puts("connected?")
rescue SystemCallError => e
  puts("refused")
end

puts("-- OpenURI.open")
text = URI.open(url(port, "/hello")) { |f| f.read }
p(text)
f = URI.open(url(port, "/hello"))
puts("#<OpenURI::Meta #{f.status.join(" ")} #{f.content_type} #{f.size} bytes>")   # Sake's inspect; Ruby's shows an address
p(f.status)
p(f.content_type)
p(f.charset)
p(f.meta)
p(f.metas)
p(f.content_encoding)
p(f.base_uri.path)
p([f.size, f.eof?])
p(f.read(5))
p(f.read(0))
p(f.read)
p(f.read)
p(f.read(3))
p(f.eof?)
p(f.rewind)
p(f.gets)
p(f.gets)
f.rewind
p(f.readlines)
f.rewind
f.each_line { |l| p(l) }
p(f.string)
p(f.last_modified)

puts("-- redirects")
f = URI.open(url(port, "/redirect"))
p([f.status, f.base_uri.path, f.read])
f = URI.open(url(port, "/redirect-abs"))
p([f.status, f.base_uri.path, f.read, f.content_type, f.charset])
begin
  URI.open(url(port, "/loop"))
rescue RuntimeError => e
  puts(e.message.split(": ")[0])
end
begin
  URI.open(url(port, "/redirect"), redirect: false)
rescue OpenURI::HTTPRedirect => e
  puts("OpenURI::HTTPRedirect: #{e.message} -> #{e.uri.path}")
end
begin
  URI.open(url(port, "/loop"), max_redirects: 1)
rescue OpenURI::TooManyRedirects => e
  puts("OpenURI::TooManyRedirects: #{e.message} #{e.io.status}")
end

puts("-- errors")
begin
  URI.open(url(port, "/missing"))
rescue OpenURI::HTTPError => e
  io = e.io
  puts("OpenURI::HTTPError: #{e.message} #{io.status} #{io.read.inspect}")
end
begin
  URI.open(url(port, "/error"))
rescue OpenURI::HTTPError => e
  puts("OpenURI::HTTPError: #{e.message}")
end
begin
  URI.open("http://user:pw@127.0.0.1:#{port}/hello")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

puts("-- options, content types")
p(URI.open(url(port, "/headers"), "User-Agent" => "ua-x", "X-Token" => "tok") { |f| f.read })
p(URI.open(url(port, "/headers"), http_basic_authentication: ["user", "pw"]) { |f| f.read })
p(OpenURI.open_uri(url(port, "/headers")) { |f| f.read })
f = URI.open(url(port, "/html"))
s = f.read
p([f.content_type, f.charset, s.encoding.to_s, s])
f = URI.open(url(port, "/binary"))
s = f.read
p([f.content_type, f.charset, s.encoding.to_s, s, f.content_encoding])
f = URI.open(url(port, "/chunked"))
p([f.content_type, f.charset, f.read, f.meta])
f = URI.open(url(port, "/empty"))
p([f.status, f.read, f.content_type, f.charset, f.eof?, f.gets])
f = URI.open(URI.parse(url(port, "/nolength")))
p([f.read, f.meta])

srv.close
puts("end")
