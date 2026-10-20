gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"

# config/initializers/content_security_policy.rb's block (Sake: a function that receives the policy)
def configure(policy)
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :https, "sha256-abc="
  policy.style_src   :self, :https, :unsafe_inline
  policy.report_uri  "/csp-violation-report-endpoint"
end
policy = ActionDispatch::ContentSecurityPolicy.new
configure(policy)
p policy.build
p policy.build(nil, "n0nce")
p policy.build(nil, "n0nce", ["script-src"])

copy = policy.dup
copy.upgrade_insecure_requests
copy.block_all_mixed_content
copy.sandbox
copy.plugin_types "application/pdf"
copy.script_src nil
copy.img_src "https://cdn.example.com", :blob
p copy.build
p policy.directives.keys
copy.sandbox "allow-scripts", "allow-forms"
copy.upgrade_insecure_requests false
p copy.build

# errors
[-> { policy.dup.script_src :bogus }, -> { policy.dup.script_src 1 }, -> { c = policy.dup; c.script_src "a b"; c.build }].each do |f|
  f.call
rescue ArgumentError, ActionDispatch::ContentSecurityPolicy::InvalidDirectiveError => e
  puts "#{e.class}: #{e.message}"
end

# the middleware adds the header from the request's policy (the nonce from the session id: none here, so "")
endpoint = ->(env) { [200, { "content-type" => "text/html" }, ["ok"]] }
already = ->(env) { [200, { "content-security-policy" => "default-src 'none'" }, ["ok"]] }
not_modified = ->(env) { [304, {}, []] }
def run(app, policy, report_only: false, generator: nil)
  env = Rack::MockRequest.env_for("/")
  env["action_dispatch.content_security_policy"] = policy
  env["action_dispatch.content_security_policy_report_only"] = report_only
  env["action_dispatch.content_security_policy_nonce_generator"] = generator
  status, headers, _ = ActionDispatch::ContentSecurityPolicy::Middleware.new(app).call(env)
  p [status, headers.to_h.select { |k, _| k.start_with?("content-security-policy") }]
end
run(endpoint, policy)
run(endpoint, policy, generator: ->(request) { request.session.id.to_s })
run(endpoint, policy, report_only: true)
run(already, policy)
run(not_modified, policy)
run(endpoint, nil)
