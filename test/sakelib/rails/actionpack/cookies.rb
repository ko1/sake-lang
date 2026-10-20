gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"

# Each request runs the endpoint's step on the request's cookie jar (Sake: a case over the step's name).
def step(name, jar)
  case name
  when "read"
    p([jar[:a], jar["b"], jar[:missing], jar.key?(:a), jar.has_key?("zz"), jar.fetch(:b), jar.fetch(:zz, "dflt")])
    p(jar.to_hash)
    puts(jar.to_header)
  when "write"
    jar[:user] = "ko1"
    jar["theme"] = { value: "dark", path: "/app", httponly: true, secure: false, same_site: :lax }
    jar[:a] = "1"                                     # unchanged: no set-cookie
    jar[:wide] = { value: "w", domain: :all }
    jar[:wide3] = { value: "w", domain: :all, tld_length: 3 }
    jar[:listed] = { value: "l", domain: [".example.com", "other.org"] }
    jar.permanent[:remember] = "yes"
    p(jar[:user])
  when "delete"
    p(jar.delete(:a))
    p(jar.delete(:nothing))
    p(jar.deleted?(:a))
    p(jar.deleted?(:b))
  when "clear"
    jar.clear(path: "/x")
    p(jar.to_hash)
  when "secure"
    jar[:s] = { value: "1", secure: true }
  end
end

endpoint = ->(env) {
  req = ActionDispatch::Request.new(env)
  step(req.path_info.delete_prefix("/"), req.cookie_jar)
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["ok"]]
}
app = ActionDispatch::Cookies.new(endpoint)

def show(response)
  status, headers, body = response
  sc = headers["set-cookie"]
  sc = [sc].compact unless sc.is_a?(Array)
  p(status)
  sc.each { |c| puts(c.sub(/expires=\w{3}, \d\d \w{3} \d{4} [\d:]{8} GMT/) { |m| m.start_with?("expires=Thu, 01 Jan 1970") ? m : "expires=<20 years>" }) }
end

cookie = "a=1; b=x%20y; a=2"
puts("-- read")
show(app.call(Rack::MockRequest.env_for("http://www.example.com/read", "HTTP_COOKIE" => cookie)))
puts("-- write")
show(app.call(Rack::MockRequest.env_for("http://www.example.com/write", "HTTP_COOKIE" => cookie)))
puts("-- write on a .co.uk host")
show(app.call(Rack::MockRequest.env_for("http://shop.example.co.uk/write", "HTTP_COOKIE" => cookie)))
puts("-- write on an IP")
show(app.call(Rack::MockRequest.env_for("http://127.0.0.1/write", "HTTP_COOKIE" => cookie)))
puts("-- delete")
show(app.call(Rack::MockRequest.env_for("http://www.example.com/delete", "HTTP_COOKIE" => cookie)))
puts("-- clear")
show(app.call(Rack::MockRequest.env_for("http://www.example.com/clear", "HTTP_COOKIE" => cookie)))
puts("-- secure over http, then https")
show(app.call(Rack::MockRequest.env_for("http://www.example.com/secure")))
show(app.call(Rack::MockRequest.env_for("https://www.example.com/secure")))
