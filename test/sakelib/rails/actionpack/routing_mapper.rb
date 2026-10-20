gem "actionpack", "8.1.3"
require "action_dispatch"
require "action_dispatch/routing/inspector"

# A Rack app to mount (Sake: a type that includes Rack::App)
class HelloApp
  def call(env) = [200, { "content-type" => "text/plain" }, ["hello"]]
  def inspect = "HelloApp"
end

# --- the routes of a blog with most of the mapper DSL ---
set = ActionDispatch::Routing::RouteSet.new
set.draw do
  concern :commentable do
    resources :comments, only: [:index, :create]
  end
  root "posts#index"
  resources :posts, concerns: :commentable do
    member do
      get :preview
      post :publish
    end
    collection { get :search }
    get :stats, on: :collection
    resources :likes, shallow: true
    resource :cover, except: [:edit]
  end
  resources :photos, path: "images", controller: "pictures", as: "images", param: :slug, only: [:index, :show]
  resources :tags, path_names: { new: "make", edit: "change" }, except: [:destroy]
  resource :session, only: [:new, :create, :destroy]
  namespace :admin do
    root to: "dashboard#show"
    resources :users, constraints: { id: /\d+/ }
  end
  scope module: "api", path: "api/v1", as: "api", defaults: { format: "json" } do
    resources :articles, only: :index
  end
  scope "(:locale)", locale: /en|ja/ do
    get "hello", to: "pages#hello"
  end
  constraints subdomain: "beta" do
    get "beta", to: "pages#beta"
  end
  get "about", to: "pages#about", as: :about
  get "pages/contact"
  match "search", to: "search#query", via: [:get, :post]
  get "files/*path", to: "files#show", format: false
  get "old", to: redirect("/new")
  get "legacy/:id", to: redirect("/posts/%{id}", status: 302)
  put "settings", controller: "settings", action: "update"
  mount HelloApp.new, at: "/hello_app"
end
puts ActionDispatch::Routing::RoutesInspector.new(set.routes).format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new)

# --- filters: `rails routes -c posts`, `rails routes -g admin` ---
inspector = ActionDispatch::Routing::RoutesInspector.new(set.routes)
puts inspector.format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new, { controller: "comments" })
puts inspector.format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new, { grep: "admin" })
puts inspector.format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new, { grep: "nothing_like_this" })

# --- named routes and route details ---
p set.named_routes.names.size
route = set.named_routes[:post_comments]
p [route.name, route.verb, route.path.spec.to_s, route.defaults, route.required_parts, route.segment_keys, route.requirements]
route = set.named_routes[:admin_user]
p [route.requirements, route.path.source]

# --- errors from the DSL ---
def error_of
  yield
  "no error"
rescue ArgumentError => e
  e.message.lines.first.chomp
end
p(error_of { ActionDispatch::Routing::RouteSet.new.draw { resources :posts, only: [:index, :bogus] } })
p(error_of { ActionDispatch::Routing::RouteSet.new.draw { match "x", to: "a#b" } })
p(error_of { ActionDispatch::Routing::RouteSet.new.draw { get "x", to: "a#b", as: :dup; get "y", to: "a#b", as: :dup } })
p(error_of { ActionDispatch::Routing::RouteSet.new.draw { get "x", to: "BadName#b" } })
p(error_of { ActionDispatch::Routing::RouteSet.new.draw { member { get :x } } })
p(error_of { ActionDispatch::Routing::RouteSet.new.draw { get "x/:id", to: "a#b", id: /\A\d+/ } })
p(error_of { ActionDispatch::Routing::RouteSet.new.draw { resources :posts, concerns: :nope } })

# --- recognition: every route the router finds for a path (the GTG simulator, then each route's regexp) ---
[["GET", "/"], ["GET", "/posts/1/preview"], ["POST", "/posts/1/likes"], ["GET", "/likes/3/edit"],
 ["DELETE", "/posts/2/cover"], ["GET", "/images/sunset"], ["GET", "/tags/make"], ["GET", "/admin"],
 ["GET", "/admin/users/12"], ["GET", "/admin/users/abc"], ["GET", "/api/v1/articles.xml"], ["GET", "/ja/hello"],
 ["GET", "/hello"], ["GET", "/fr/hello"], ["GET", "/files/a/b/c.txt"], ["POST", "/search"], ["GET", "/legacy/9"],
 ["GET", "/hello_app/x/y"], ["PATCH", "/posts/5.json"], ["GET", "/posts/new"], ["GET", "/nowhere"]].each do |verb, path|
  req = ActionDispatch::Request.new(Rack::MockRequest.env_for(path, method: verb))
  found = []
  set.router.recognize(req) { |route, params| found << [route.name, params] }
  puts "#{verb} #{path} #{found.inspect}"
end
