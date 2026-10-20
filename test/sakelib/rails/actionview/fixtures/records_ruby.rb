# Model-like records for the actionview tests (ActiveModel::Model)
class Post
  include ActiveModel::Model
  attr_accessor :id, :title, :body
  def persisted? = !id.nil?
  def to_s = "Post #{id}"
end

class Comment
  include ActiveModel::Model
  attr_accessor :id, :post_id, :body
  def persisted? = !id.nil?
end
