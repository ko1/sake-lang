gem "actionpack", "8.1.3"
require "active_support/all"
require "action_controller"

# Conditional GET: fresh_when with etag/last_modified/public/cache_control, stale?, a strong etag, the flash in
# the etag (EtagWithFlash), expires_in, expires_now, no_store, must_understand, http_cache_forever.
class PagesController < ActionController::Base
  def weak = fresh_when etag: "v1", public: true
  def modified = fresh_when last_modified: Time.utc(2026, 10, 1, 12, 0, 0), cache_control: { max_age: 60 }
  def strong = fresh_when strong_etag: ["post", 7]
  def both
    if stale?(etag: "v2", last_modified: Time.utc(2026, 10, 1, 12, 0, 0))
      render plain: "fresh content"
    end
  end
  def flashed
    flash.now[:notice] = "hi"
    fresh_when etag: "v1"
  end
  def expiring
    expires_in 3600, public: true, must_revalidate: true, foo: "bar"
    render plain: "expires"
  end
  def now
    expires_now
    render plain: "now"
  end
  def nostore
    no_store
    render plain: "no store"
  end
  def understand
    must_understand
    render plain: "must understand"
  end
  def forever
    http_cache_forever(public: true) { render plain: "forever" }
  end
end


set = ActionDispatch::Routing::RouteSet.new
set.draw do
  ["weak", "modified", "strong", "both", "flashed", "expiring", "now", "nostore", "understand", "forever"].each { |a| get a, to: "pages##{a}" }
end

# the session the flash needs (a store kept in memory is enough here)
stack = ActionDispatch::MiddlewareStack.new
stack.use ActionDispatch::Flash
app = stack.build(set)

def send_request(app, path, headers = {})
  env = Rack::MockRequest.env_for("http://www.example.com#{path}")
  env["HTTP_ACCEPT"] = "application/json"   # no templates: the implicit render is 204, not MissingExactTemplate
  headers.each { |k, v| env[k] = v }
  status, hs, body = app.call(env)
  out = +""
  body.each { |s| out << s }
  puts("GET #{path} #{headers.keys.join(",")} -> #{status} #{out.inspect}")
  ["etag", "last-modified", "cache-control", "date"].each do |k|
    v = hs[k]
    v = "<now>" if k == "date" && v != nil
    puts("  #{k}: #{v}") if v != nil
  end
  hs["etag"]
end

etag = send_request(app, "/weak")
send_request(app, "/weak", { "HTTP_IF_NONE_MATCH" => etag.to_s })
send_request(app, "/modified")
send_request(app, "/modified", { "HTTP_IF_MODIFIED_SINCE" => "Thu, 01 Oct 2026 12:00:00 GMT" })
send_request(app, "/modified", { "HTTP_IF_MODIFIED_SINCE" => "Wed, 30 Sep 2026 12:00:00 GMT" })
etag = send_request(app, "/strong")
send_request(app, "/strong", { "HTTP_IF_NONE_MATCH" => etag.to_s })
etag = send_request(app, "/both")
send_request(app, "/both", { "HTTP_IF_NONE_MATCH" => etag.to_s, "HTTP_IF_MODIFIED_SINCE" => "Thu, 01 Oct 2026 12:00:00 GMT" })
send_request(app, "/both", { "HTTP_IF_NONE_MATCH" => etag.to_s })
send_request(app, "/flashed")
send_request(app, "/expiring")
send_request(app, "/now")
send_request(app, "/nostore")
send_request(app, "/understand")
send_request(app, "/forever")
