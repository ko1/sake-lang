gem "actionpack", "8.1.3"
require "action_dispatch"

# RemoteIp in front of an endpoint that answers the request's remote_ip
endpoint = ->(env) { [200, { "content-type" => "text/plain" }, [ActionDispatch::Request.new(env).remote_ip]] }
app = ActionDispatch::RemoteIp.new(endpoint)
custom = ActionDispatch::RemoteIp.new(endpoint, true, [IPAddr.new("203.0.113.0/24")])
unchecked = ActionDispatch::RemoteIp.new(endpoint, false)

def remote_ip(app, headers)
  env = Rack::MockRequest.env_for("/", headers.merge("REMOTE_ADDR" => headers.fetch("REMOTE_ADDR", "10.0.0.1")))
  _, _, body = app.call(env)
  body.first
rescue ActionDispatch::RemoteIp::IpSpoofAttackError => e
  "IpSpoofAttackError: #{e.message}"
end

p remote_ip(app, { "REMOTE_ADDR" => "198.51.100.7" })
p remote_ip(app, { "HTTP_X_FORWARDED_FOR" => "198.51.100.7" })
p remote_ip(app, { "HTTP_X_FORWARDED_FOR" => "198.51.100.7, 10.0.0.2, 192.168.1.9" })
p remote_ip(app, { "HTTP_X_FORWARDED_FOR" => "unknown, 198.51.100.7" })
p remote_ip(app, { "HTTP_X_FORWARDED_FOR" => "10.0.0.2, 127.0.0.1" })
p remote_ip(app, { "HTTP_CLIENT_IP" => "198.51.100.8" })
p remote_ip(app, { "HTTP_CLIENT_IP" => "198.51.100.8", "HTTP_X_FORWARDED_FOR" => "198.51.100.7" })
p remote_ip(unchecked, { "HTTP_CLIENT_IP" => "198.51.100.8", "HTTP_X_FORWARDED_FOR" => "198.51.100.7" })
p remote_ip(app, { "HTTP_X_FORWARDED_FOR" => "2001:db8::1, fe80::1" })
p remote_ip(custom, { "REMOTE_ADDR" => "203.0.113.5", "HTTP_X_FORWARDED_FOR" => "10.0.0.9" })
p remote_ip(custom, { "REMOTE_ADDR" => "198.51.100.1", "HTTP_X_FORWARDED_FOR" => "10.0.0.9" })
