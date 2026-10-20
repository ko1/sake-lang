# The class bodies of transactions.rb/transactions.sake's models (Ruby requires it; Sake's generator reads it)
class Account < ActiveRecord::Base
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  after_commit :trace_commit
  after_rollback :trace_rollback
end
