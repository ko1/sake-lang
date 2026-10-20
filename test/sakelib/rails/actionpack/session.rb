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

def sid_of(session) = session.id&.public_id

def step(name, req)
  session = req.session
  case name
  when "write"
    session[:user_id] = 42
    session["cart"] = [1, 2]
    p([session[:user_id], session.loaded?, session.keys])
  when "read"
    p([session[:user_id], session["cart"], session.key?(:user_id), session.fetch(:zz, 0), session.loaded?])
    p([session.to_hash, session.empty?, sid_of(session), session["session_id"]])
  when "untouched"
    p(session.loaded?)
  when "delete"
    p(session.delete(:cart))
    p(session.keys)
  when "reset"
    req.reset_session
    p([session.to_hash, sid_of(session)])
    session[:fresh] = true
  when "renew"
    session.options[:renew] = true
    session[:user_id] = 7
  when "skip"
    session[:user_id] = 8
    session.options[:skip] = true
  end
end

endpoint = ->(env) {
  req = ActionDispatch::Request.new(env)
  step(req.path_info.delete_prefix("/"), req)
  [200, Rack::Headers.new.merge!("content-type" => "text/plain"), ["ok"]]
}
store = TestStore.new(endpoint, key: "_s", httponly: true)
app = ActionDispatch::Cookies.new(store)

def run(app, path, cookie)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}")
  env["HTTP_COOKIE"] = cookie if cookie
  status, headers, _body = app.call(env)
  sc = headers["set-cookie"]
  puts("#{path} -> #{status} #{sc.inspect}")
  sc ? sc[/\A_s=[^;]*/] : cookie
end

c = run(app, "/untouched", nil)
c = run(app, "/write", c)
c = run(app, "/read", c)
c = run(app, "/delete", c)
c = run(app, "/read", c)
c = run(app, "/renew", c)
c = run(app, "/read", c)
c = run(app, "/skip", c)
c = run(app, "/read", c)
c = run(app, "/reset", c)
c = run(app, "/read", c)
c = run(app, "/read", "_s=unknown")
p(store.stored)
