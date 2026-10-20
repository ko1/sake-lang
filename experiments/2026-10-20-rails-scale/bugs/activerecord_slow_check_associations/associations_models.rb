# The class bodies of associations.rb/associations.sake's models (Ruby requires it; Sake's generator reads it)
class Author < ActiveRecord::Base
  has_many :posts, dependent: :nullify
  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :posts, allow_destroy: true
end

class Profile < ActiveRecord::Base
  belongs_to :author
end

class Post < ActiveRecord::Base
  belongs_to :author, optional: true
  has_many :comments, dependent: :destroy
  has_many :taggings, dependent: :delete_all
  has_many :tags, through: :taggings
  has_and_belongs_to_many :categories
  validates :title, presence: true
end

class Comment < ActiveRecord::Base
  belongs_to :post, counter_cache: true, optional: false
  validates :body, presence: true
end

class Tag < ActiveRecord::Base
  has_many :taggings, dependent: :restrict_with_error
  has_many :posts, through: :taggings
end

class Tagging < ActiveRecord::Base
  belongs_to :post
  belongs_to :tag
end

class Category < ActiveRecord::Base
  has_and_belongs_to_many :posts
end
