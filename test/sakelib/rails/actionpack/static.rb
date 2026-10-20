gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"
require "action_controller"

endpoint = ->(env) { [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["app: #{env["PATH_INFO"]}"]] }
app = ActionDispatch::Static.new(endpoint, "fixtures/public", headers: { "cache-control" => "public, max-age=60" })

def run(app, path, headers = {})
  status, h, body = app.call(Rack::MockRequest.env_for(path, headers))
  h = h.to_h
  p([path, status, h.except("last-modified"), h.key?("last-modified"), body.respond_to?(:each) ? body.to_enum(:each).to_a.join.bytesize : body])
end

run(app, "/")
run(app, "/index.html")
run(app, "/about")
run(app, "/about.html")
run(app, "/docs")
run(app, "/docs/")
run(app, "/hello.txt")
run(app, "/style.css")
run(app, "/app.js")
run(app, "/app.js", "HTTP_ACCEPT_ENCODING" => "gzip, deflate")
run(app, "/missing")
run(app, "/../static.rb")
run(app, "/about", "REQUEST_METHOD" => "POST")
run(app, "/about", "REQUEST_METHOD" => "HEAD")
