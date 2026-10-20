gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"

# --- an endpoint (Sake: a type including ActionDispatch::App) ---
endpoint = ->(env) {
  req = ActionDispatch::Request.new(env)
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["id=#{req.request_id}"]]
}

def names(stack) = stack.middlewares.map(&:inspect)

puts("-- building the list")
stack = ActionDispatch::MiddlewareStack.new
stack.use ActionDispatch::Cookies
stack.use ActionDispatch::Flash
stack.unshift ActionDispatch::RequestId, header: "X-Request-Id"
p(names(stack))
stack.insert_before ActionDispatch::Cookies, ActionDispatch::DebugExceptions
stack.insert_after ActionDispatch::RequestId, ActionDispatch::ShowExceptions, ActionDispatch::PublicExceptions.new("public")
p(names(stack))
p(stack.size)
p(stack[0].inspect)
p(stack.last.inspect)
stack.move_before ActionDispatch::RequestId, ActionDispatch::Flash
p(names(stack))
stack.move_after ActionDispatch::Cookies, ActionDispatch::Flash
p(names(stack))
stack.swap ActionDispatch::DebugExceptions, ActionDispatch::Static, "fixtures/public"
p(names(stack))
p(stack.delete(ActionDispatch::Static) != nil)
p(stack.delete(ActionDispatch::Static))
begin
  stack.delete!(ActionDispatch::Static)
rescue RuntimeError => e
  puts("RuntimeError: #{e.message}")
end
begin
  stack.insert_before(ActionDispatch::Static, ActionDispatch::Cookies)
rescue RuntimeError => e
  puts("RuntimeError: #{e.message}")
end
p(names(stack))

puts("-- building the app")
app = stack.build(endpoint)
status, headers, body = app.call(Rack::MockRequest.env_for("/", "HTTP_X_REQUEST_ID" => "abc-123 <x>"))
p([status, headers.to_h, body])
