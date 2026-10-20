# The class bodies of model.rb / model.sake (Ruby requires this file; Sake's `generate` reads it).
class Person
  include ActiveModel::Model
  attr_accessor :id, :name, :email, :age, :role
  validates :name, presence: true, length: { maximum: 10 }
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/, message: "is not an email" }, allow_blank: true
  validates :age, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :role, inclusion: { in: %w[admin member] }, on: :create
  validate :not_reserved
  validates :id, absence: true, if: :guest?
end

class Admin < Person
  attr_accessor :level
  validates :level, presence: true
end

class Tag
  extend ActiveModel::Naming
end
