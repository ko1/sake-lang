gem "actionpack", "8.1.3"
gem "activemodel", "8.1.3"
require "action_dispatch"
require "action_controller"
require "active_model"

# Records: ActiveModel gives model_name (route_key, singular_route_key), to_model, to_param and persisted?
# (Sake: a type that includes PolymorphicRoutes::Model and ToParam)
class Post
  include ActiveModel::Model
  attr_accessor :id
  def persisted? = !id.nil?
end
class Comment
  include ActiveModel::Model
  attr_accessor :id
  def persisted? = !id.nil?
end

set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :posts do
    resources :comments
  end
  namespace :admin do
    resources :posts
  end
end
helpers = Class.new.tap { |c| c.include(set.url_helpers) }.new
post = Post.new(id: 1)
comment = Comment.new(id: 5)

p helpers.polymorphic_path(post)
p helpers.polymorphic_path(Post.new)
p helpers.polymorphic_path([post, comment])
p helpers.polymorphic_path([post, Comment.new])
p helpers.polymorphic_path([:admin, post])
p helpers.polymorphic_path([:admin, :posts])
p helpers.polymorphic_path(:posts)
p helpers.polymorphic_path(post, format: :json, anchor: "c")
p helpers.edit_polymorphic_path(post)
p helpers.new_polymorphic_path(Post.new)
p helpers.new_polymorphic_path([post, Comment.new])
p helpers.polymorphic_url(post, host: "example.com")
p helpers.polymorphic_url([post, comment], host: "example.com", only_path: true)
p helpers.polymorphic_path({ id: post, format: :xml })
[nil, [nil], [post, "comments"]].each do |bad|
  helpers.polymorphic_path(bad)
rescue ArgumentError => e
  p e.message
end
begin
  helpers.polymorphic_path([:nothing, post])
rescue NoMethodError => e
  p e.message.split(" for ").first
end
