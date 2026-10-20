gem "actionpack", "8.1.3"
require "action_dispatch"
require "action_dispatch/http/content_disposition"

def show(label, v) = puts("#{label}: #{v.inspect}")
# Rails' Rack body is a RackBody over the response; shown as its parts.
def triple(res)
  status, headers, body = res.to_a
  [status, headers.to_h, body.respond_to?(:each) ? body.to_enum.to_a : body]
end

puts("-- a new response")
res = ActionDispatch::Response.create
show("status", res.status)
show("headers", res.headers.to_h)
show("content_type", res.content_type)
show("charset", res.charset)
show("message", res.message)
show("committed?", res.committed?)
res.body = "hello"
show("body", res.body)
show("to_a", triple(res))
show("committed? after to_a", res.committed?)
show("headers after", res.headers.to_h)

puts("-- content type and charset")
res = ActionDispatch::Response.new
res.content_type = "text/plain"
show("text/plain", [res.content_type, res.media_type, res.charset])
res.content_type = :json
show(":json", [res.content_type, res.media_type, res.charset])
res.charset = "ISO-8859-1"
show("charset=", res.content_type)
res.charset = false
show("charset=false", res.content_type)
res.content_type = "text/csv; charset=Shift_JIS"
show("with charset", [res.content_type, res.charset])
res.content_type = "application/xml"
show("keeps charset", res.content_type)
begin
  res.content_type = :nope
rescue ArgumentError => e
  show("ArgumentError", e.message)
end

puts("-- status")
res = ActionDispatch::Response.new(404)
show("404", [res.status, res.code, res.message, res.status_message, res.response_code, res.not_found?, res.client_error?])
res.status = :created
show(":created", [res.status, res.message, res.successful?, res.created?])
res.status = :unprocessable_entity
show(":unprocessable_entity", [res.status, res.message, res.unprocessable?])
res = ActionDispatch::Response.new(204, { "Content-Type" => "text/plain" }, ["x"])
show("204 to_a", triple(res))
res = ActionDispatch::Response.new(302, { "Location" => "/posts" })
show("redirect", [res.location, res.redirect?, res.redirection?, res.redirect_url])

puts("-- headers")
res = ActionDispatch::Response.new(200, { "X-Frame-Options" => "SAMEORIGIN" }, [])
show("get_header", res.get_header("x-frame-options"))
show("[]", res["X-Frame-Options"])
res["X-Request-Id"] = "abc"
show("has_header?", res.has_header?("x-request-id"))
res.delete_header("X-Frame-Options")
show("after delete", res.headers.to_h)
res = ActionDispatch::Response.create(200, {}, [], default_headers: { "x-content-type-options" => "nosniff" })
show("default_headers", res.headers.to_h)

puts("-- body")
res = ActionDispatch::Response.new
res.write("a")
res.write("b")
show("written", [res.body, res.body_parts, res.committed?])
res.body = ["x", "y"]
show("array body", [res.body, res.body_parts])
res.reset_body!
show("reset", res.body)

puts("-- cookies")
res = ActionDispatch::Response.new
res.set_cookie("user", { value: "ko1", path: "/", http_only: true })
res.set_cookie("theme", "dark")
show("set-cookie", res.get_header("set-cookie"))
show("cookies", res.cookies)
res.delete_cookie("theme", { path: "/" })
show("deleted", res.get_header("set-cookie"))

puts("-- caching")
res = ActionDispatch::Response.new
res.etag = "abc"
show("etag", [res.etag, res.weak_etag?, res.strong_etag?])
res.strong_etag = ["post", 1]
show("strong_etag", [res.etag, res.weak_etag?, res.strong_etag?])
show("to_a", triple(res))
res = ActionDispatch::Response.new
res.last_modified = Time.utc(2026, 10, 20, 12, 0, 0)
show("last_modified", [res.get_header("last-modified"), res.last_modified, res.last_modified?])
res = ActionDispatch::Response.new(200, { "Cache-Control" => "public, max-age=60, foo=bar" })
show("cache-control in", triple(res)[1]["cache-control"])
res = ActionDispatch::Response.new(200, { "Cache-Control" => "no-cache" })
show("no-cache", triple(res)[1]["cache-control"])

puts("-- content disposition")
show("attachment", ActionDispatch::Http::ContentDisposition.format(disposition: "attachment", filename: "résumé 2026.pdf"))
show("inline", ActionDispatch::Http::ContentDisposition.format(disposition: "inline", filename: nil))
