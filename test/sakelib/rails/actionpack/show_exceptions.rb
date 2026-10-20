gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"
require "action_controller"

# The endpoint raises by path; x-cascade "pass" stands for "no route" (Sake: a case over the path).
endpoint = ->(env) {
  case env["PATH_INFO"]
  when "/ok" then [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["fine"]]
  when "/missing" then [404, Rack::Headers.new.merge!("x-cascade" => "pass"), []]
  when "/boom" then raise "boom"
  when "/bad" then raise ActionController::BadRequest, "bad"
  when "/parse" then raise ActionDispatch::Http::Parameters::ParseError, "parse"
  when "/method" then raise ActionController::UnknownHttpMethod, "FOO"
  else raise ArgumentError, "other"
  end
}

# The app's config.action_dispatch.show_exceptions, from a header here (Rails puts it in the env).
class Config
  def initialize(app) = @app = app
  def call(env)
    env["action_dispatch.show_exceptions"] = env["HTTP_X_SHOW"].to_sym if env["HTTP_X_SHOW"]
    @app.call(env)
  end
end

app = Config.new(ActionDispatch::ShowExceptions.new(ActionDispatch::DebugExceptions.new(endpoint), ActionDispatch::PublicExceptions.new("fixtures/public")))

def run(app, path, headers = {})
  status, h, body = app.call(Rack::MockRequest.env_for(path, headers))
  p([path, status, h.to_h, body.to_a])
rescue => e
  puts("#{path}: raised #{e.class}: #{e.message}")
end

run(app, "/ok")
run(app, "/missing")
run(app, "/boom")
run(app, "/bad")
run(app, "/parse")
run(app, "/method")
run(app, "/boom", "HTTP_ACCEPT" => "application/json")
run(app, "/missing", "HTTP_ACCEPT" => "application/json")
run(app, "/missing.json")
run(app, "/boom", "REQUEST_METHOD" => "HEAD")
run(app, "/boom", "HTTP_X_SHOW" => "none")
run(app, "/boom", "HTTP_X_SHOW" => "rescuable")
run(app, "/bad", "HTTP_X_SHOW" => "rescuable")

puts("-- ExceptionWrapper")
w = ActionDispatch::ExceptionWrapper.new(nil, ActionController::RoutingError.new("No route"))
p([w.status_code, w.exception_class_name, w.rescue_template, w.rescue_response?, w.routing_error?])
w = ActionDispatch::ExceptionWrapper.new(nil, RuntimeError.new("x"))
p([w.status_code, w.exception_class_name, w.rescue_template, w.rescue_response?, w.message])
p(ActionDispatch::ExceptionWrapper.status_code_for_exception("ActionController::UnknownFormat"))
p(ActionDispatch::ExceptionWrapper.status_code_for_exception("ActionController::InvalidAuthenticityToken"))
