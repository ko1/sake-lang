gem "actionpack", "8.1.3"
require "action_dispatch"

# config.filter_parameters (Rails 8's default list) reaches the request as "action_dispatch.parameter_filter"
filters = [:passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc]
env = Rack::MockRequest.env_for("/login?user=ann&password=hunter2&token=abc;page=2", method: "POST",
  params: { "user" => { "email" => "a@example.com", "name" => "Ann", "password" => "x" }, "api_key" => "k" })
env["action_dispatch.parameter_filter"] = filters
req = ActionDispatch::Request.new(env)
p req.filtered_parameters
p req.filtered_path
p req.filtered_env.slice("QUERY_STRING", "PATH_INFO", "REQUEST_METHOD")   # (Rack caches the form in rack.request.form_vars, masked; Sake keeps it in rack.input)

# without filters nothing is masked, but the raw body still is in the env
req = ActionDispatch::Request.new(Rack::MockRequest.env_for("/x?password=1"))
p [req.filtered_parameters, req.filtered_path]
