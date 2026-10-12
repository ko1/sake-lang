# The HTML of Rails' helpers, route helpers and model errors outside an app (actionview, actionpack, activemodel
# 8.1.3); compare.sake prints the same with the Sake framework. Run: ruby compare.rb
require "action_view"
require "active_model"
require "action_controller"
require "action_dispatch/routing/inspector"

# config/routes.rb
ROUTES = ActionDispatch::Routing::RouteSet.new
ROUTES.draw do
  root "posts#index"
  resources :posts do
    resources :comments, only: [:create, :destroy]
  end
end

# app/models/post.rb (ActiveModel only: no database here)
class Post
  include ActiveModel::Model
  include ActiveModel::Attributes
  attribute :id, :integer
  attribute :title, :string
  attribute :body, :string
  validates :title, presence: true, length: { minimum: 5 }
  validates :body, presence: true
  def persisted? = !id.nil?
end

class Comment
  include ActiveModel::Model
  include ActiveModel::Attributes
  attribute :id, :integer
  attribute :commenter, :string
  attribute :body, :string
  def persisted? = !id.nil?
end

# the view context: helpers and route helpers
class View < ActionView::Base
  include ROUTES.url_helpers
  def protect_against_forgery? = false
end
# the defaults a Rails 8.1 app has (config.load_defaults 8.1); outside an app they are off
ActionView::Helpers::FormHelper.form_with_generates_remote_forms = false
ActionView::Helpers::FormHelper.form_with_generates_ids = true
ActionView::Helpers::FormTagHelper.default_enforce_utf8 = false
ActionView::Helpers::UrlHelper.button_to_generates_button_tag = true
view = View.empty

# `bin/rails routes`
puts ActionDispatch::Routing::RoutesInspector.new(ROUTES.routes).format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new)

# route helpers
puts view.root_path
puts view.posts_path
puts view.new_post_path
puts view.post_path(1)
puts view.edit_post_path(1)
puts view.post_comments_path(1)
puts view.post_comment_path(1, 2)
post = Post.new(id: 3, title: "Hello <world>", body: "text")
puts view.post_path(post)
puts view.polymorphic_path(post)
puts view.polymorphic_path([post, Comment.new(id: 9)])

# tags and links
puts view.content_tag(:p, "Hello <world>", class: "note")
puts view.content_tag(:div, id: "posts") { "<b>inner</b>" }
puts view.content_tag(:div, id: "posts") { view.content_tag(:b, "inner") }
puts view.tag.br
puts view.link_to("Show this post", "/posts/1")
puts view.link_to("Back <home>", "/posts", class: "nav")
puts view.link_to("Show this post", post)
puts view.button_to("Destroy this post", post, method: :delete)
puts view.button_to("New", "/posts")
puts view.pluralize(1, "error")
puts view.pluralize(2, "error")
puts view.pluralize(0, "comment")
puts view.pluralize(2, "person")
puts ERB::Util.h("<script>alert('x') & \"y\"</script>")
puts view.dom_id(post)
puts view.dom_id(Post.new)
puts view.dom_id(post, :edit)
t0 = Time.utc(2026, 10, 12, 12, 0, 0)
[0, 50, 5 * 60, 50 * 60, 3 * 3600, 30 * 3600, 3 * 86400, 40 * 86400, 100 * 86400, 800 * 86400].each do |sec|
  puts view.distance_of_time_in_words(t0, t0 + sec)
end

# a model with errors
bad = Post.new(title: "Hi", body: "")
puts bad.valid?
puts bad.errors.count
bad.errors.full_messages.each { |m| puts m }
puts bad.errors.full_messages_for(:title).inspect
puts bad.errors[:body].inspect
empty = Post.new(title: "", body: nil)
puts empty.valid?
empty.errors.each { |e| puts "#{e.attribute}: #{e.full_message}" }
ok = Post.new(title: "Hello world", body: "text")
puts ok.valid?
puts ok.errors.any?

# forms
puts view.form_with(model: Post.new, url: "/posts") { |f|
  f.label(:title) + f.text_field(:title) + f.text_area(:body) + f.submit
}
puts view.form_with(model: post) { |f|
  f.label(:title, style: "display: block") + f.text_field(:title) + f.text_area(:body) + f.submit
}
puts view.form_with(model: [post, Comment.new]) { |f|
  f.text_field(:commenter) + f.submit
}
puts view.form_with(url: "/search", method: :get) { |f| f.text_field(:q) + f.submit("Search") }
