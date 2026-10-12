# A todo list on Sinatra (the Ruby twin of app.sake): a form, redirects, a JSON endpoint, a session
# counter, a 404 page; served by WEBrick on 127.0.0.1 and a free port (printed as "port N").
require "sinatra/base"
require "json"

class TodoApp < Sinatra::Base
  STORE = [{id: 1, title: "Try Sake-lang", done: true}]
  LOCK = Mutex.new
  helpers do
    def todos = LOCK.synchronize { STORE.map(&:dup) }
    def find(id) = LOCK.synchronize { STORE.find { |t| t[:id] == id.to_i } }
  end

  # (Sake: def routes(app), the class body run once per request phase)
  set :environment, :production
  set :server, "webrick"
  set :views, File.join(File.dirname($PROGRAM_NAME), "views")
  enable :sessions
  set :session_secret, "demo-secret-" * 6
  helpers ERB::Util                                 # h() in templates

  before do
    visits = session["visits"] || 0
                                                    # (Sake: visits => Integer)
    session["visits"] = visits + 1
  end

  get "/" do
    erb :index, locals: {todos: todos, visits: session["visits"]}
  end

  get "/todos.json" do
    content_type :json
    JSON.generate(todos)
  end

  get "/todos/:id" do
    todo = find(params["id"])
    halt 404 unless todo
    erb :show, locals: {todo: todo, visits: session["visits"]}
  end

  post "/todos" do
    title = params["title"].to_s.strip
    halt 400, "title is empty" if title.empty?
    LOCK.synchronize { STORE << {id: STORE.size + 1, title: title, done: false} }
    redirect "/"
  end

  post "/todos/:id/done" do
    todo = find(params["id"])
    halt 404 unless todo
    LOCK.synchronize { todo[:done] = true }
    redirect to("/")
  end

  not_found do
    "<h1>Not found</h1><p>#{Rack::Utils.escape_html(request.path_info)}</p>"
  end
  # (Sake: end of routes)
end

$stdout.sync = true
TodoApp.run!(bind: "127.0.0.1", port: 0) do |server|
  puts "port #{server.config[:Port]}"
                                                    # (Sake: IO.flush(IO.stdout))
end
