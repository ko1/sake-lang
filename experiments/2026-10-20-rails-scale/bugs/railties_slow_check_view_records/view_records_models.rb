# The class bodies of view_records.rb/view_records.sake's models (Ruby requires it; Sake's generator reads it)
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

class Article < ApplicationRecord
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end

class Comment < ApplicationRecord
  belongs_to :article
end

class User < ApplicationRecord
  has_secure_password
end
