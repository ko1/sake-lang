# The class bodies of features.rb/features.sake's models (Ruby requires it; Sake's generator reads it)
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Order < ApplicationRecord
  enum :status, [:pending, :shipped, :cancelled]
  enum :priority, { low: "low", high: "high" }, prefix: true
  store :settings, accessors: [:color, :gift_note], coder: JSON
  has_secure_token
  attr_readonly :code
  attribute :discount, :integer, default: 5
end

class Doc < ApplicationRecord
end

class Note < ApplicationRecord
  self.record_timestamps = false
end
