gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"

endpoint = ->(env) { [200, Rack::Headers.new.merge!("content-type" => "text/plain", "set-cookie" => ["a=1; path=/", "b=2; secure"]), ["ok"]] }
app = ActionDispatch::SSL.new(endpoint)
custom = ActionDispatch::SSL.new(endpoint, redirect: { host: "secure.example.com", port: 8443, status: 308 }, hsts: { preload: true, expires: 3600 })
off = ActionDispatch::SSL.new(endpoint, redirect: false, hsts: false, ssl_default_redirect_status: 302)

def run(app, url, headers = {})
  status, h, body = app.call(Rack::MockRequest.env_for(url, headers))
  p([url, status, h.to_h, body.to_a])
end

run(app, "http://example.com/a?b=1")
run(app, "http://example.com:8080/a", "REQUEST_METHOD" => "POST")
run(app, "https://example.com/a")
run(custom, "http://example.com/x")
run(custom, "https://example.com/x")
run(off, "http://example.com/y", "REQUEST_METHOD" => "POST")
run(off, "https://example.com/y")
