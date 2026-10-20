gem "actionpack", "8.1.3"
gem "actionview", "8.1.3"
gem "activemodel", "8.1.3"
require "active_support/all"
require "active_support/messages/rotation_configuration"
require "action_controller"
require "action_view"
require "active_model"

# Controllers rendering ActionView templates through the routes: implicit render of the action's template in the
# application layout, `render :new, status: :unprocessable_entity`, a layout by name with except:, layout: false,
# a template of another controller, render_to_string, respond_to with an html and a json template, a missing
# template, partials and collections of records, form_with a record, url helpers from the RouteSet, the flash
# after a redirect, csrf_meta_tags and a helper_method in the layout.
# the load_defaults 8.1 values (the port's defaults)
ActionView::Helpers::FormHelper.form_with_generates_ids = true
ActionView::Helpers::FormHelper.form_with_generates_remote_forms = false
ActionView::Helpers::FormTagHelper.default_enforce_utf8 = false
ActionController::Base.allow_forgery_protection = true

class Post
  include ActiveModel::Model
  attr_accessor :id, :title, :body
  validates :title, presence: true
  def persisted? = !id.nil?
end

# The posts (a database's stand-in)
POSTS = [Post.new(id: 1, title: "Hello", body: "First <post>"), Post.new(id: 2, title: "Second", body: "More")]

ROUTES = ActionDispatch::Routing::RouteSet.new
ROUTES.draw do
  resources :posts
  ["about", "home", "plain", "plain_with_layout", "bare", "other", "string", "negotiate", "missing", "partial", "helper"].each { |a| get a, to: "pages##{a}" }
  ["home", "about", "fixed"].each { |a| get "admin/#{a}", to: "admin_pages##{a}" }
  ["index", "with_admin", "required"].each { |a| get "nolayout/#{a}", to: "bare##{a}" }
end

require_relative "controller_view_decl"
class ApplicationController < ActionController::Base
  include ROUTES.url_helpers
  self.view_paths = ["controller_views_rb"]

  private
  def current_user = "ko1"
  def greeting(word, name: current_user) = "#{word}, #{name}!"
end

class PostsController < ApplicationController
  attr_reader :post, :posts

  def index = @posts = POSTS
  def show = nil
  def new = @post = Post.new
  def create
    @post = Post.new(title: params[:title], body: "")
    if @post.valid?
      @post.id = POSTS.size + 1
      POSTS.push(@post)
      redirect_to post_path(@post), notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit = nil
  def update
    @post.title = params[:title]
    if @post.valid?
      redirect_to @post, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    POSTS.delete(@post)
    redirect_to posts_path, notice: "Post was successfully destroyed.", status: :see_other
  end

  private
  def set_post = @post = POSTS.find { |p| p.id == params[:id].to_i } || raise(ActionController::RoutingError, "no post #{params[:id]}")
end

class PagesController < ApplicationController
  def about = nil
  def home = nil
  def plain = render plain: "plain text"
  def plain_with_layout = render plain: "plain in a layout", layout: "application"
  def bare = render :about, layout: false
  def other = render "posts/new"
  def string
    html = render_to_string(:home, layout: false)
    render plain: "home is #{html.size} bytes: #{html.strip}"
  end
  def negotiate
    respond_to do |format|
      format.html { render :about }
      format.json { render :about }
    end
  end
  def missing = render :nope
  def partial = render partial: "fragment"
  def helper = render plain: "#{helpers.number_to_currency(1234.5)} #{helpers.pluralize(2, "page")} #{helpers.greeting("Bye")}"
end

# layout :choose_layout: a name, or nil for the implied lookup (layouts/admin_pages, then PagesController's layout)
class AdminPagesController < PagesController
  def fixed = render :home
  def about = render template: "pages/about"

  private
  def choose_layout = action_name == "fixed" ? "application" : nil
end

# layout false: none, unless the render names one (or asks for the default with layout: true)
class BareController < ApplicationController
  def index = nil
  def with_admin = render :index, layout: "admin"
  def required = render :index, layout: true
end

def configure(env)
  env["action_dispatch.key_generator"] = ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new("b" * 64, iterations: 2))
  env["action_dispatch.secret_key_base"] = "b" * 64   # the session goes in the encrypted jar, as in a Rails app
  env["action_dispatch.authenticated_encrypted_cookie_salt"] = "authenticated encrypted cookie"
  env["action_dispatch.use_authenticated_cookie_encryption"] = true
  env["action_dispatch.cookies_serializer"] = :json
  env["action_dispatch.use_cookies_with_metadata"] = true
  env["action_dispatch.cookies_rotations"] = ActiveSupport::Messages::RotationConfiguration.new
end
class Config
  def initialize(app) = @app = app
  def call(env)
    configure(env)
    @app.call(env)
  end
end

stack = ActionDispatch::MiddlewareStack.new
stack.use ActionDispatch::Cookies
stack.use ActionDispatch::Session::CookieStore, key: "_blog_session"
stack.use ActionDispatch::Flash
app = Config.new(stack.build(ROUTES))

# The response: status, the headers that matter, the body (CSRF tokens are random: replaced).
def send_request(app, jar, method, path, headers = {})
  env = Rack::MockRequest.env_for("http://www.example.com#{path}", method: method)
  env["HTTP_COOKIE"] = jar.map { |k, v| "#{k}=#{v}" }.join("; ") if !jar.empty?
  headers.each { |k, v| env[k] = v }
  begin
    status, hs, body = app.call(env)
  rescue => e
    puts("#{method} #{path} -> #{e.class.name}: #{e.message.split("\n")[0].sub(/ in #<ActionView::PathSet.*/, "")}")
    return
  end
  out = +""
  body.each { |s| out << s }
  puts("#{method} #{path} -> #{status}")
  ["content-type", "location", "vary"].each { |k| puts("  #{k}: #{hs[k]}") if hs[k] }
  out = out.gsub(/(name="csrf-token" content=|name="authenticity_token" value=)"[^"]*"/) { "#{$1}\"TOKEN\"" }
  puts(out.lines.map { |l| "  | #{l}" }.join)
  lines = case (h = hs["set-cookie"])
          when Array then h
          when String then h.split("\n")
          else []
          end
  lines.each do |l|
    name, rest = l.split("=", 2)
    jar[name.to_s] = (rest.to_s.split(";", 2)[0] || "")
  end
end

jar = {}
send_request(app, jar, "GET", "/posts")
send_request(app, jar, "GET", "/posts/1")
send_request(app, jar, "GET", "/posts/new")
send_request(app, jar, "POST", "/posts?title=")
send_request(app, jar, "POST", "/posts?title=Third")
send_request(app, jar, "GET", "/posts/3")
send_request(app, jar, "GET", "/posts/3/edit")
send_request(app, jar, "PATCH", "/posts/3?title=")
send_request(app, jar, "PATCH", "/posts/3?title=Third+again")
send_request(app, jar, "DELETE", "/posts/3")
send_request(app, jar, "GET", "/posts")
send_request(app, jar, "GET", "/about?who=you")
send_request(app, jar, "GET", "/home")
send_request(app, jar, "GET", "/plain")
send_request(app, jar, "GET", "/plain_with_layout")
send_request(app, jar, "GET", "/bare")
send_request(app, jar, "GET", "/other")
send_request(app, jar, "GET", "/string")
send_request(app, jar, "GET", "/negotiate")
send_request(app, jar, "GET", "/negotiate", { "HTTP_ACCEPT" => "application/json" })
send_request(app, jar, "GET", "/missing")
send_request(app, jar, "GET", "/partial")
send_request(app, jar, "GET", "/helper")
send_request(app, jar, "GET", "/posts/9")
send_request(app, jar, "GET", "/admin/home")
send_request(app, jar, "GET", "/admin/about")
send_request(app, jar, "GET", "/admin/fixed")
send_request(app, jar, "GET", "/nolayout/index")
send_request(app, jar, "GET", "/nolayout/with_admin")
send_request(app, jar, "GET", "/nolayout/required")
