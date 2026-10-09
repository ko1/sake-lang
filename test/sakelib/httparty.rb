require_relative "ref/httparty"
require "webrick"
require "json"

# --- an API server: WEBrick, one servlet answering every method (mount_proc would 405 PATCH and DELETE) ---
class Api < WEBrick::HTTPServlet::AbstractServlet
def service(req, res)
  body = req.body
  q = req.query
  case req.path_info
  when "/users"
    res.content_type = "application/json; charset=utf-8"
    res.body = JSON.generate({"users" => [{"id" => 1, "name" => "ko1"}], "page" => q["page"]&.to_s || "1", "q" => WEBrick::HTTPUtils.parse_query(req.query_string).map { |k, v| [k, v.to_s] }.sort_by { |k, v| k }})
  when "/echo"
    res.content_type = "application/json"
    res.body = JSON.generate({"method" => req.request_method, "content_type" => req.content_type, "body" => body, "auth" => req["Authorization"], "x" => req["X-Api-Key"], "accept" => req["Accept"]})
  when "/text"
    res.content_type = "text/plain"
    res.body = "plain #{req.request_method} #{body.inspect}"
  when "/missing"
    res.status = 404
    res.content_type = "application/json"
    res.body = "{\"error\":\"not found\"}"
  when "/boom"
    res.status = 503
    res.body = "down"
  when "/go"
    res.status = 302
    res["Location"] = "/text"
  when "/loop"
    res.status = 302
    res["Location"] = "/loop"
  when "/empty"
    res.status = 204
  else
    res.status = 400
    res.body = "?"
  end
end
end
srv = WEBrick::HTTPServer.new(BindAddress: "127.0.0.1", Port: 0, Logger: WEBrick::Log.new(File::NULL), AccessLog: [])
port = srv.config[:Port]
srv.mount("/", Api)
t = Thread.new { srv.start }
base = "http://127.0.0.1:#{port}"

def show(r)
  puts("#{r.code} #{r.message.inspect} success=#{r.success?} type=#{r.content_type.inspect}")
  puts("  body=#{r.body.inspect}")
  puts("  parsed=#{r.parsed_response.inspect}")
end

puts("-- get")
r = HTTParty.get("#{base}/users")
show(r)
p([r.ok?, r.client_error?, r.server_error?, r.redirection?, r.not_found?, r.nil?])
p(r["users"])
p(r.header("Content-Type"))
p(r.headers["content-length"])
p(r.content_length)
puts(r.to_s)
r = HTTParty.get("#{base}/users?page=2", query: {"sort" => "name", "tags" => ["a", "b c"], "f" => {"x" => 1}})
show(r)
r = HTTParty.get(URI.parse("#{base}/echo"), headers: {"X-Api-Key" => "k1", "Accept" => "application/json"})
show(r)
r = HTTParty.get("#{base}/echo", basic_auth: {username: "user", password: "pw"})
p(r["auth"])
r = HTTParty.get("#{base}/text")
show(r)
p(r[0])

puts("-- post, put, patch, delete, head")
r = HTTParty.post("#{base}/echo", body: {"name" => "sake", "tags" => ["x", "y"]})
show(r)
r = HTTParty.post("#{base}/echo", body: JSON.generate({"a" => 1}), headers: {"Content-Type" => "application/json"})
show(r)
r = HTTParty.post("#{base}/text", body: "raw text")
show(r)
r = HTTParty.put("#{base}/echo", body: {"v" => "2"})
p([r["method"], r["body"]])
r = HTTParty.patch("#{base}/echo", body: "p")
p([r["method"], r["body"], r["content_type"]])
r = HTTParty.delete("#{base}/echo")
p([r["method"], r["body"]])
r = HTTParty.head("#{base}/users")
p([r.code, r.body, r.parsed_response, r.headers["content-type"]])

puts("-- errors, redirects")
r = HTTParty.get("#{base}/missing")
show(r)
p([r.not_found?, r.client_error?, r["error"]])
r = HTTParty.get("#{base}/boom")
show(r)
r = HTTParty.get("#{base}/empty")
show(r)
r = HTTParty.get("#{base}/go")
show(r)
r = HTTParty.get("#{base}/go", follow_redirects: false)
p([r.code, r.redirection?, (r.headers["location"] || "").sub(/:\d+\//, ":PORT/")])
r = HTTParty.post("#{base}/go", body: "x")
show(r)
begin
  HTTParty.get("#{base}/loop")
rescue HTTParty::RedirectionTooDeep => e
  puts("RedirectionTooDeep: #{e.message}")
end

puts("-- to_params")
p(HTTParty.to_params({"a" => 1, "b" => [1, 2], "c" => {"d" => "e f"}, "n" => nil}))
p(HTTParty.normalize_param("k", "v&w"))

puts("-- client (the class DSL)")
api = HTTParty::Client.new(base, headers: {"X-Api-Key" => "secret"}, default_params: {"page" => "9"})
r = api.get("/users", query: {"sort" => "id"})
show(r)
r = api.get("/echo")
p([r["x"], r["accept"]])
api.basic_auth = {username: "u", password: "p"}
r = api.post("/echo", body: {"k" => "v"}, headers: {"Accept" => "text/*"})
p([r["auth"], r["x"], r["accept"], r["body"]])
api2 = HTTParty::Client.new(base + "/")
p(api2.get("/text").body)

srv.shutdown
t.join
puts("end")
