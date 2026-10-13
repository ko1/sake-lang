# Sinatra: one app and its requests, on the real gem (sinatra 4.2.1, mustermann 3.1.1, rack 3.2.6);
# sinatra.sake is the same program on sakelib/sinatra.sake. Read the two side by side.
require "sinatra/base"
require "json"

class MyError < StandardError
end

class App < Sinatra::Base
  # (Sake: def routes(app), the class body run once per request phase)
  # settings (Ruby: the class body runs once)
  set :environment, :production
  set :views, File.join(__dir__, "sinatra_views")
  set :public_folder, File.join(__dir__, "sinatra_public")
  set :title, "Sake"
  set :port, 8080
  enable :sessions
  set :session_secret, "0123456789abcdef" * 4

  helpers ERB::Util                          # h() in templates

  template :named do
    "named <%= who %>"
  end

  # filters
  before do
    headers "x-before" => "yes"
  end

  before "/admin/*" do
    halt 401, "admin only" unless params["key"] == "secret"
  end

  after do
    headers "x-after" => response.status.to_s
  end

  # routes
  get "/" do
    "Hello, world"
  end

  get "/hello/:name" do
    "Hello, #{params["name"]}!"
  end

  get "/say/*/to/*" do
    splat = params["splat"]
                                           # (Sake: splat => Array)
    "say #{splat.join(" | ")}"
  end

  get "/posts/:id(.:format)?" do
    "post #{params["id"]} format=#{params["format"].inspect}"
  end

  get %r{/num/(\d+)} do
    captures = params["captures"]

    "num #{captures.first}"
  end

  get "/query" do
    "q=#{params["q"]} list=#{params["list"].inspect}"
  end

  post "/form" do
    "posted #{params["name"]} (#{request.content_type})"
  end

  put "/item/:id" do
    "put #{params["id"]} v=#{params["v"]}"
  end

  delete "/item/:id" do
    status 204
  end

  get "/status" do
    status 201
    headers "x-custom" => "1"
    content_type :txt
    "created"
  end

  get "/halt" do
    halt 418, {"x-halt" => "1"}, "teapot"
    "not reached"
  end

  get "/forbidden" do
    halt 403, "nope"
  end

  get "/tuple" do
    [202, {"x-t" => "1"}, "tuple body"]
  end

  get "/redirect" do
    redirect "/"
  end

  post "/redirect" do
    redirect to("/done")
  end

  get "/uri" do
    "#{uri("/x")} #{url("/y", false)} #{to("z")}"
  end

  get "/pass/:who" do
    pass unless params["who"] == "me"
    "it is me"
  end

  get "/pass/*" do
    splat = params["splat"]

    "passed #{splat.first}"
  end

  get "/json" do
    content_type :json
    JSON.generate({"ok" => true, "items" => [1, 2]})
  end

  get "/erb" do
    erb :index, locals: {title: "Todo <list>", items: [{name: "write", done: true}, {name: "test & ship", done: false}]}
  end

  get "/inline" do
    erb "<b><%= name %></b>", layout: false, locals: {name: "inline"}
  end

  get "/named" do
    erb :named, layout: false, locals: {who: "template"}
  end

  get "/counter" do
    session["count"] = (session["count"] || 0) + 1
    "count=#{session["count"]}"
  end

  get "/settings" do
    "title=#{settings.title} sessions=#{settings.sessions} port=#{settings.port} bind=#{settings.bind.inspect}"
  end

  get "/admin/panel" do
    "admin panel"
  end

  get "/boom" do
    raise MyError, "it broke"
  end

  get "/plain-error" do
    raise "plain"
  end

  get "/strict" do
    "strict"
  end

  # error handlers
  not_found do
    "no route for #{request.path_info}"
  end

  error 403 do
    "403 handler"
  end

  error do |e|
    "error: #{e.inspect}"
  end
  # (Sake: end of routes)
end

def show(label, triple)
  status, headers, body = triple
  parts = []
  body.each { |s| parts << s }
  puts "== #{label} -> #{status}"
  headers.to_h.sort.each do |k, v|
    v = v.sub(/\A([^=]*)=[^;]*/) { "#{$1}=..." } if k == "set-cookie"
    puts "#{k}: #{v}"
  end
  puts parts.join unless parts.empty?
end

def req(app, method, path, input = nil, cookie = nil)
  opts = {method: method}
  opts[:input] = input if input
  opts["CONTENT_TYPE"] = "application/x-www-form-urlencoded" if input
  opts["HTTP_COOKIE"] = cookie if cookie
  app.call(Rack::MockRequest.env_for(path, opts))
end

app = App
show("GET /", req(app, "GET", "/"))
show("GET /hello/Sake%20lang", req(app, "GET", "/hello/Sake%20lang"))
show("GET /say/hi/to/the/world", req(app, "GET", "/say/hi/to/the/world"))
show("GET /posts/7.json", req(app, "GET", "/posts/7.json"))
show("GET /posts/7", req(app, "GET", "/posts/7"))
show("GET /num/42", req(app, "GET", "/num/42"))
show("GET /query", req(app, "GET", "/query?q=a+b&list[]=1&list[]=2"))
show("POST /form", req(app, "POST", "/form", "name=ko1&x=1"))
show("PUT /item/3", req(app, "PUT", "/item/3", "v=1"))
show("DELETE /item/3", req(app, "DELETE", "/item/3"))
show("GET /status", req(app, "GET", "/status"))
show("GET /halt", req(app, "GET", "/halt"))
show("GET /forbidden", req(app, "GET", "/forbidden"))
show("GET /tuple", req(app, "GET", "/tuple"))
show("GET /redirect", req(app, "GET", "/redirect"))
show("POST /redirect", req(app, "POST", "/redirect", ""))
show("GET /uri", req(app, "GET", "/uri"))
show("GET /pass/me", req(app, "GET", "/pass/me"))
show("GET /pass/you", req(app, "GET", "/pass/you"))
show("GET /json", req(app, "GET", "/json"))
show("GET /erb", req(app, "GET", "/erb"))
show("GET /inline", req(app, "GET", "/inline"))
show("GET /named", req(app, "GET", "/named"))
show("GET /settings", req(app, "GET", "/settings"))
show("GET /admin/panel", req(app, "GET", "/admin/panel"))
show("GET /admin/panel?key=secret", req(app, "GET", "/admin/panel?key=secret"))
show("GET /boom", req(app, "GET", "/boom"))
show("GET /plain-error", req(app, "GET", "/plain-error"))
show("GET /missing", req(app, "GET", "/missing"))
show("GET /strict/", req(app, "GET", "/strict/"))
show("HEAD /", req(app, "HEAD", "/"))
show("GET /hello.txt", req(app, "GET", "/hello.txt"))

puts "-- session"
cookie = nil
3.times do
  status, headers, body = req(app, "GET", "/counter", nil, cookie)
  cookie = headers["set-cookie"][/\A[^;]*/]
  parts = []
  body.each { |s| parts << s }
  puts "#{status} #{parts.join}"
end
