gem "actionpack", "8.1.3"
require "active_support/all"
require "action_dispatch"

# A store kept in memory, with ids counted instead of random (Rails' tests write such stores too).
class TestStore < ActionDispatch::Session::AbstractSecureStore
  def initialize(app, options = {})
    super
    @sessions = {}
    @n = 0
  end

  def generate_sid
    @n += 1
    Rack::Session::SessionId.new("sid#{@n}")
  end

  def find_session(req, sid)
    session = sid ? @sessions[sid.private_id] : nil
    sid, session = generate_sid, {} unless session
    [sid, session]
  end

  def write_session(req, sid, session, options)
    @sessions[sid.private_id] = session
    sid
  end

  def delete_session(req, sid, options)
    @sessions.delete(sid.private_id) if sid
    generate_sid unless options[:drop]
  end

  def stored = @sessions.transform_keys { |k| k[0, 9] }
end

# Each step runs as an action would: the flash is committed to the session at the end (ActionController's dispatch).
def step(name, flash)
  case name
  when "set"
    flash[:notice] = "Saved"
    flash["alert"] = "Careful"
    flash.now[:info] = "only now"
    p([flash[:notice], flash.notice, flash.alert, flash[:info], flash.keys])
  when "show"
    p([flash.to_hash, flash.key?(:notice), flash.empty?])
  when "keep"
    p(flash.keep(:notice))
  when "discard"
    flash.discard
    p(flash.to_hash)
  when "update"
    flash.update(:a => 1, "b" => [2])
    flash.delete(:a)
    flash.alert = "replaced"
    p(flash.to_session_value)
  when "sweep"
    flash[:x] = "y"
    flash.sweep
    p(flash.to_hash)
    flash.sweep
    p(flash.to_hash)
  end
end

endpoint = ->(env) {
  req = ActionDispatch::Request.new(env)
  step(req.path_info.delete_prefix("/"), req.flash)
  req.commit_flash
  p(req.session["flash"])
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["ok"]]
}
store = TestStore.new(ActionDispatch::Flash.new(endpoint), key: "_s")
app = ActionDispatch::Cookies.new(store)

def run(app, path, cookie)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}")
  env["HTTP_COOKIE"] = cookie if cookie
  status, headers, _body = app.call(env)
  sc = headers["set-cookie"]
  puts("#{path} -> #{status}")
  sc ? sc[/\A_s=[^;]*/] : cookie
end

c = run(app, "/show", nil)
c = run(app, "/set", c)
c = run(app, "/show", c)
c = run(app, "/show", c)
c = run(app, "/set", c)
c = run(app, "/keep", c)
c = run(app, "/show", c)
c = run(app, "/show", c)
c = run(app, "/set", c)
c = run(app, "/discard", c)
c = run(app, "/show", c)
c = run(app, "/update", c)
c = run(app, "/sweep", c)

puts("-- FlashHash.from_session_value")
f = ActionDispatch::Flash::FlashHash.from_session_value({ "discard" => ["a"], "flashes" => { "a" => 1, "b" => 2 } })
p(f.to_hash)
p(ActionDispatch::Flash::FlashHash.from_session_value(nil).to_hash)
