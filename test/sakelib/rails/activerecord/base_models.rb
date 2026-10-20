# The class bodies of base.rb/base.sake's models (Ruby requires it; Sake's generator reads it)
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Post < ApplicationRecord
  validates :title, presence: true, length: { minimum: 3 }
  validate :body_is_not_shouting
  before_save :normalize_title
  after_create :log_create
end
