gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"

# config/initializers/permissions_policy.rb's block (Sake: a function that receives the policy)
def configure(policy)
  policy.camera      :none
  policy.gyroscope   :none
  policy.microphone  :none
  policy.usb         :none
  policy.fullscreen  :self
  policy.payment     :self, "https://secure.example.com"
end
policy = ActionDispatch::PermissionsPolicy.new
configure(policy)
p policy.build
copy = policy.dup
copy.camera nil
copy.web_share :self
p [copy.build, policy.directives.size]
begin
  copy.usb :everyone
rescue ArgumentError => e
  p e.message
end

endpoint = ->(env) { [200, { "content-type" => "text/html" }, ["ok"]] }
[policy, ActionDispatch::PermissionsPolicy.new, nil].each do |pol|
  env = Rack::MockRequest.env_for("/")
  env["action_dispatch.permissions_policy"] = pol
  _, headers, _ = ActionDispatch::PermissionsPolicy::Middleware.new(endpoint).call(env)
  p headers.to_h.slice("feature-policy")
end
