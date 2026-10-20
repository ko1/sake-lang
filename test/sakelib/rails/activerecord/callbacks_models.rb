# The class bodies of callbacks.rb/callbacks.sake's models (Ruby requires it; Sake's generator reads it)
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Post < ApplicationRecord
  after_initialize :trace_initialize
  after_find :trace_find
  before_validation :trace_before_validation
  after_validation :trace_after_validation
  before_save :trace_before_save
  around_save :trace_around_save
  after_save :trace_after_save
  after_save :trace_after_save_again
  before_create :make_slug
  around_create :trace_around_create
  after_create :trace_after_create
  before_update :trace_before_update, unless: :locked?
  after_update :trace_after_update
  before_destroy :check_locked
  after_destroy :trace_after_destroy
  after_commit :trace_commit
  after_create_commit :trace_create_commit
  after_update_commit :trace_update_commit
  after_destroy_commit :trace_destroy_commit
  after_rollback :trace_rollback
  validates :title, presence: true
end

class Account < ApplicationRecord
  validates :email, uniqueness: { scope: :org_id }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }, on: :update
  before_save :check_frozen, if: :frozen_balance?
end
