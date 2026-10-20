gem "actionview", "8.1.3"
gem "actionpack", "8.1.3"
gem "activemodel", "8.1.3"
require "action_view"
require "action_dispatch"
require "action_controller"
require "active_model"
require_relative "fixtures/blog_routes_ruby"
require_relative "fixtures/records_ruby"

# A view with the routes' url helpers (Rails: the view class includes routes.url_helpers), as an app's has
ActionView::Helpers::UrlHelper.button_to_generates_button_tag = true
class AppView < ActionView::Base.with_empty_template_cache
  include BLOG_ROUTES.url_helpers
end

env = Rack::MockRequest.env_for("http://www.example.com/posts?page=2")
view = AppView.with_view_paths([]); req = ActionDispatch::Request.new(env); view.define_singleton_method(:request) { req }
post = Post.new(id: 1, title: "Hello", body: "World")
comment = Comment.new(id: 5, post_id: 1, body: "Nice")

# url_for
puts view.url_for("/plain")
puts view.url_for(controller: "posts", action: "show", id: 3)
puts view.url_for(controller: "posts", action: "index", only_path: false, host: "example.org")
puts view.url_for(post)
puts view.url_for([post, comment])
puts view.url_for([post, { only_path: false, host: "h.example" }])
puts view.url_for(:posts)
puts view.url_for(:back)
puts view.posts_path, view.post_path(post), view.edit_post_comment_path(post, comment)
puts view.post_url(post, host: "example.com")
# link_to
puts view.link_to("Home", view.root_path)
puts view.link_to("Show", post)
puts view.link_to("Show", post, class: "btn", data: { turbo_confirm: "Sure?" })
puts view.link_to("Delete", post, method: :delete, rel: "external")
puts view.link_to("Remote", "/x", remote: true)
puts view.link_to("<Escaped>", [post, comment])
puts view.link_to(nil, "http://www.rubyonrails.org/")
puts view.link_to(post) { "Block <b>" }
puts view.link_to(view.posts_path, class: "nav") { "<b>All</b>".html_safe }
puts view.link_to("About", controller: "pages", action: "about")
# button_to
puts view.button_to("New", "/posts/new", method: :get)
puts view.button_to("Create", "/posts")
puts view.button_to("Destroy", post, method: :delete)
puts view.button_to("Update", post, form: { id: "f" }, form_class: "inline", params: { page: 2, tags: ["a", "b"] })
puts view.button_to(post, class: "b") { "Inside" }
# link_to_if / unless / unless_current
puts view.link_to_if(true, "Yes", "/yes")
puts view.link_to_if(false, "No <1>", "/no")
puts view.link_to_unless(true, "Hidden", "/h") { |name| "[#{name}]" }
puts view.link_to_unless_current("Posts", view.posts_path)
puts view.link_to_unless_current("Root", view.root_path)
# current_page?
p(view.current_page?("/posts"), view.current_page?("/posts?page=2"), view.current_page?("/posts?page=3"))
p(view.current_page?("/posts", check_parameters: true), view.current_page?("http://www.example.com/posts"))
p(view.current_page?(controller: "posts", action: "index"), view.current_page?("/posts", method: :post))
# mail_to / sms_to / phone_to
puts view.mail_to("me@example.com")
puts view.mail_to("me@example.com", "My email", class: "m")
puts view.mail_to("me@example.com", cc: "ccaddress@example.com", subject: "This is an example email", body: "Hi & bye")
puts view.mail_to("me@example.com") { "Email me" }
puts view.sms_to("5155555785", "Text me", country_code: "01", body: "I have a question")
puts view.phone_to("1234567890", "Call me", country_code: "01")
# dom_id / dom_class / dom_target
puts view.dom_id(post), view.dom_id(Post.new(title: "", body: "")), view.dom_id(post, :edit)
puts view.dom_class(post), view.dom_class(post, :edit), view.dom_target(post, :comments, comment)
