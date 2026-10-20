# A plain ActiveModel class next to the records (base.rb requires it; base.sake's ActiveModel generator reads it)
class PostForm
  include ActiveModel::Model
  attr_accessor :title, :post_id
  validates :title, presence: true, length: { maximum: 10 }
end
