gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"

endpoint = ->(env) {
  req = ActionDispatch::Request.new(env)
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), [req.request_id.to_s]]
}
app = ActionDispatch::RequestId.new(endpoint, header: "X-Request-Id")
custom = ActionDispatch::RequestId.new(endpoint, header: "X-Trace")

def run(app, headers)
  _, h, body = app.call(Rack::MockRequest.env_for("/", headers))
  id = body.first
  shape = id.match?(/\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/) ? "<uuid>" : id
  p([shape.size > 40 ? "#{shape[0, 20]}... (#{shape.size})" : shape, h.to_h.transform_values { |v| v == id ? "=body" : v }])
end

run(app, {})
run(app, "HTTP_X_REQUEST_ID" => "req-42")
run(app, "HTTP_X_REQUEST_ID" => "a b;c<d>@e_f")
run(app, "HTTP_X_REQUEST_ID" => "x" * 300)
run(app, "HTTP_X_REQUEST_ID" => "")
run(custom, "HTTP_X_TRACE" => "t-1")
