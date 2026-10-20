gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"
require "action_view"
require "ipaddr"

endpoint = ->(env) { [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["hi"]] }
app = ActionDispatch::HostAuthorization.new(endpoint, ["example.com", ".myapp.test", /\Aapi\d\.local\z/, IPAddr.new("10.0.0.0/8")])
open = ActionDispatch::HostAuthorization.new(endpoint, [])

def run(app, host, headers = {})
  env = Rack::MockRequest.env_for("http://#{host}/", headers)
  env["HTTP_HOST"] = host                               # as a browser sends it
  status, h, body = app.call(env)
  p([host, status, h.to_h, body.to_a])
end

run(app, "example.com")
run(app, "example.com:3000")
run(app, "evil.com")
run(app, "www.myapp.test")
run(app, "myapp.test")
run(app, "a.b.myapp.test")
run(app, "api1.local")
run(app, "api12.local")
run(app, "10.1.2.3")
run(app, "11.1.2.3")
run(app, "example.com", "HTTP_X_FORWARDED_HOST" => "evil.com")
run(app, "evil.com", "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest")
run(open, "anything.org")
