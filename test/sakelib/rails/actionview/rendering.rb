gem "actionview", "8.1.3"
gem "actionpack", "8.1.3"
gem "activemodel", "8.1.3"
require "action_view"
require "action_dispatch"
require "action_controller"
require "active_model"
require_relative "fixtures/blog_routes_ruby"
require_relative "fixtures/records_ruby"
ActionView::Helpers::FormHelper.form_with_generates_ids = true
ActionView::Helpers::FormHelper.form_with_generates_remote_forms = false
ActionView::Helpers::FormTagHelper.default_enforce_utf8 = false
BlogView = ActionView::Base.with_empty_template_cache
BlogView.include BLOG_ROUTES.url_helpers

def view_for(posts, post, comments)
  view = BlogView.with_view_paths(["views_rb"], { posts: posts, post: post, comments: comments })
  view.lookup_context.prefixes = ["posts"]   # a PostsController's _prefixes
  view
end

posts = [Post.new(id: 1, title: "Hello", body: "First <post>"), Post.new(id: 2, title: "Second", body: "More")]
comments = [Comment.new(id: 1, post_id: 1, body: "Nice"), Comment.new(id: 2, post_id: 1, body: "Great")]

puts "-- posts/index with the layout"
view = view_for(posts, nil, comments)
puts view.render(template: "posts/index", layout: "layouts/application")
puts "-- posts/show"
view = view_for(posts, posts.first, comments)
puts view.render(template: "posts/show", layout: "layouts/application")
puts "-- an empty index without a layout"
puts view_for([], nil, comments).render(template: "posts/index")
puts "-- a partial without locals, and plain/html bodies"
puts view.render(partial: "posts/shared")
puts view.render(plain: "<plain>")
puts view.render(html: "<html>")
puts "-- lookup"
lc = ActionView::LookupContext.new(["views_rb"])
p(lc.exists?("index", ["posts"]), lc.exists?("post", ["posts"], true), lc.exists?("nope", ["posts"]))
t = lc.find_template("posts/index")
p(t.virtual_path, t.format, t.variable)
begin
  view.render(template: "posts/missing")
rescue ActionView::MissingTemplate => e
  puts e.message.split(" with ")[0]
end
begin
  view.render(partial: "posts/nothing")
rescue ActionView::MissingTemplate => e
  puts e.message.split(" with ")[0]
end
